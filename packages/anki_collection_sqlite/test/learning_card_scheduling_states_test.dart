// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as protoDeck;
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CollectionSqliteStorage storage;

  setUp(() async {
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => sqlite3.openInMemory(),
      ),
      location: ':memory:',
    );
    await storage.executeBatch('''
CREATE TABLE cards (
  id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER, mod INTEGER,
  usn INTEGER, type INTEGER, queue INTEGER, due INTEGER, ivl INTEGER,
  factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER, odue INTEGER,
  odid INTEGER, flags INTEGER, data TEXT
);
CREATE TABLE deck_config (
  id INTEGER PRIMARY KEY NOT NULL,
  name TEXT NOT NULL COLLATE NOCASE,
  mtime_secs INTEGER NOT NULL,
  usn INTEGER NOT NULL,
  config BLOB NOT NULL
);
CREATE TABLE config (
  key TEXT PRIMARY KEY, usn INTEGER, mtime_secs INTEGER, val BLOB
);
CREATE TABLE decks (
  id INTEGER PRIMARY KEY NOT NULL,
  name TEXT NOT NULL COLLATE NOCASE,
  mtime_secs INTEGER NOT NULL,
  usn INTEGER NOT NULL,
  common BLOB NOT NULL,
  kind BLOB NOT NULL
);
''');
    storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(_config());
    storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
    await _insertCard(storage);
  });

  tearDown(() async => storage.close());

  group('learningCardSchedulingStatesForCard', () {
    test(
      'matches the model using explicit timing and stored Learn state',
      () async {
        const scheduledSecs = 615;
        const elapsedSecs = 278;
        final card = (await storage.getCard(Int64(1)))!;
        final resolver = (double interval, int minimum, int maximum) => 23;
        final base = ReviewSchedulingContext(
          fuzzFactor: 0.37,
          fsrsParams: const [0.2, 0.4],
          fsrsDesiredRetention: 0.91,
          fsrsNextStates: _shortTermOutcomes(),
          loadBalancedIntervalResolver: resolver,
        );

        final result = await storage.learningCardSchedulingStatesForCard(
          cardId: card.id,
          scheduledSecs: scheduledSecs,
          elapsedSecs: elapsedSecs,
          baseContext: base,
        );
        final config = _config();
        final expectedContext = base
            .withDeckConfig(config)
            .withFsrsShortTermSettings(
              allowShortTerm: false,
              shortTermWithStepsEnabled: false,
            );
        final expected = LearningCardState.fromCard(
          card,
          scheduledSecs: scheduledSecs,
          elapsedSecs: elapsedSecs,
        ).nextStates(expectedContext);

        _expectStatesEqual(result, expected);
        expect(result.current.kind, LearningTransitionKind.learning);
        expect(result.current.learning!.remainingSteps, 2);
        expect(result.current.learning!.scheduledSecs, scheduledSecs);
        expect(result.current.learning!.elapsedSecs, elapsedSecs);
        expect(result.current.learning!.memoryState!.stability, 2.0);
        expect(result.current.learning!.memoryState!.difficulty, 4.0);
        expect(expectedContext.loadBalancedIntervalResolver, same(resolver));
        expect(expectedContext.fuzzFactor, 0.37);
        expect(expectedContext.fsrsParams, [0.2, 0.4]);
        expect(expectedContext.fsrsDesiredRetention, 0.91);
      },
    );

    test(
      'uses resolved learning/relearning config and collection FSRS flags',
      () async {
        final config = _config()
          ..inner.learnSteps.clear()
          ..inner.learnSteps.addAll([2, 7, 25])
          ..inner.relearnSteps.clear()
          ..inner.relearnSteps.addAll([1, 6])
          ..inner.graduatingIntervalGood = 4
          ..inner.graduatingIntervalEasy = 9
          ..inner.fsrsParams6.addAll(List<double>.filled(21, 0.25));
        storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(config);
        await storage.writeCollectionConfig('fsrs', true);
        await storage.writeCollectionConfig(
          'fsrs_short_term_with_steps_enabled',
          true,
        );
        final base = ReviewSchedulingContext(
          fuzzFactor: 0.42,
          fsrsParams: const [0.8],
          fsrsDesiredRetention: 0.93,
          fsrsNextStates: _shortTermOutcomes(),
          fsrsAllowShortTerm: false,
          fsrsShortTermWithStepsEnabled: false,
        );

        final result = await storage.learningCardSchedulingStatesForCard(
          cardId: Int64(1),
          scheduledSecs: 120,
          elapsedSecs: 60,
          baseContext: base,
        );
        final expectedContext = base
            .withDeckConfig(config)
            .withFsrsShortTermSettings(
              allowShortTerm: true,
              shortTermWithStepsEnabled: true,
            );
        _expectStatesEqual(
          result,
          LearningCardState.fromCard(
            (await storage.getCard(Int64(1)))!,
            scheduledSecs: 120,
            elapsedSecs: 60,
          ).nextStates(expectedContext),
        );
        expect(result.again.learning!.scheduledSecs, 120);
        expect(result.again.learning!.remainingSteps, 3);
        expect(result.hard.learning!.scheduledSecs, 420);
        expect(result.good.learning!.scheduledSecs, 1500);
        expect(result.easy.review!.scheduledDays, 2);
        expect(expectedContext.learningStepsMinutes, [2, 7, 25]);
        expect(expectedContext.relearningStepsMinutes, [1, 6]);
        expect(expectedContext.fsrsAllowShortTerm, isTrue);
        expect(expectedContext.fsrsShortTermWithStepsEnabled, isTrue);
        expect(expectedContext.fuzzFactor, 0.42);
        expect(expectedContext.fsrsParams, [0.8]);
        expect(expectedContext.fsrsDesiredRetention, 0.93);
      },
    );

    test('uses Core defaults for a missing config row', () async {
      storage.deckConfigs.removeDeckConfig(Int64(10));
      final base = ReviewSchedulingContext(
        fuzzFactor: 0.2,
        fsrsParams: const [0.1, 0.2, 0.3],
      );

      final result = await storage.learningCardSchedulingStatesForCard(
        cardId: Int64(1),
        scheduledSecs: 321,
        elapsedSecs: 123,
        baseContext: base,
      );
      final config = DeckConfig(
        id: Int64(10),
        inner: DeckConfig.defaults().inner,
      );
      _expectStatesEqual(
        result,
        LearningCardState.fromCard(
          (await storage.getCard(Int64(1)))!,
          scheduledSecs: 321,
          elapsedSecs: 123,
        ).nextStates(
          base
              .withDeckConfig(config)
              .withFsrsShortTermSettings(
                allowShortTerm: false,
                shortTermWithStepsEnabled: false,
              ),
        ),
      );
    });

    test('does not read revlogs or load-balancer history/cache', () async {
      // This fixture has no revlog or collection timing/cache tables.
      await storage.writeCollectionConfig('fsrs', true);
      final result = await storage.learningCardSchedulingStatesForCard(
        cardId: Int64(1),
        scheduledSecs: 30,
        elapsedSecs: 5,
        baseContext: const ReviewSchedulingContext(),
      );
      expect(result.current.learning!.scheduledSecs, 30);
      expect(result.current.learning!.elapsedSecs, 5);
    });

    test(
      'rejects missing cards, non-Learn cards, invalid deck and config IDs',
      () async {
        Future<LearningCardSchedulingStates> project([CardId? id]) =>
            storage.learningCardSchedulingStatesForCard(
              cardId: id ?? Int64(404),
              scheduledSecs: 60,
              elapsedSecs: 10,
              baseContext: const ReviewSchedulingContext(),
            );

        await expectLater(project(), _stateError('card not found'));
        await storage.executeBatch('UPDATE cards SET type = 2 WHERE id = 1');
        await expectLater(
          project(Int64(1)),
          _stateError('not a learning card'),
        );
        await storage.executeBatch(
          'UPDATE cards SET type = 1, did = 404 WHERE id = 1',
        );
        await expectLater(project(Int64(1)), _stateError('deck not found'));
        await storage.executeBatch('UPDATE cards SET did = 7 WHERE id = 1');
        storage.decks.addOrUpdateDeckWithExistingId(
          Deck(
            id: Int64(7),
            name: 'No config',
            kind: NormalDeckKind(protoDeck.Deck_Normal()),
          ),
        );
        await expectLater(project(Int64(1)), _stateError('no config ID'));
        storage.decks.addOrUpdateDeckWithExistingId(
          Deck(
            id: Int64(7),
            name: 'Filtered',
            kind: FilteredDeckKind(protoDeck.Deck_Filtered()),
          ),
        );
        await expectLater(project(Int64(1)), _stateError('filtered deck'));
      },
    );
  });
}

DeckConfig _config() => DeckConfig(
  id: Int64(10),
  name: 'Default',
  inner: DeckConfig.defaults().inner,
);

Deck _normalDeck() => Deck(
  id: Int64(7),
  name: 'Deck 7',
  kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
);

FsrsReviewNextStates _shortTermOutcomes() => FsrsReviewNextStates(
  again: FsrsReviewNextState(
    interval: 0.25,
    memoryState: FsrsMemoryState(stability: 2, difficulty: 4),
  ),
  hard: FsrsReviewNextState(
    interval: 0.5,
    memoryState: FsrsMemoryState(stability: 3, difficulty: 4),
  ),
  good: FsrsReviewNextState(
    interval: 0.75,
    memoryState: FsrsMemoryState(stability: 4, difficulty: 4),
  ),
  easy: FsrsReviewNextState(
    interval: 1.0,
    memoryState: FsrsMemoryState(stability: 5, difficulty: 4),
  ),
);

Matcher _stateError(String message) => throwsA(
  isA<StateError>().having(
    (error) => error.message,
    'message',
    contains(message),
  ),
);

Future<void> _insertCard(CollectionSqliteStorage storage) =>
    storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES (1, 100, 7, 0, 0, 1, 1, 1, 0, 0, 2500, 3, 0, 1002, 0, 0, 0,
          '{"s":2,"d":4}');
''');

void _expectStatesEqual(
  LearningCardSchedulingStates actual,
  LearningCardSchedulingStates expected,
) {
  for (final (left, right) in [
    (actual.current, expected.current),
    (actual.again, expected.again),
    (actual.hard, expected.hard),
    (actual.good, expected.good),
    (actual.easy, expected.easy),
  ]) {
    expect(left.kind, right.kind);
    expect(left.learning?.remainingSteps, right.learning?.remainingSteps);
    expect(left.learning?.scheduledSecs, right.learning?.scheduledSecs);
    expect(left.learning?.elapsedSecs, right.learning?.elapsedSecs);
    expect(
      left.learning?.memoryState?.stability,
      right.learning?.memoryState?.stability,
    );
    expect(
      left.learning?.memoryState?.difficulty,
      right.learning?.memoryState?.difficulty,
    );
    expect(left.review?.scheduledDays, right.review?.scheduledDays);
    expect(left.review?.elapsedDays, right.review?.elapsedDays);
    expect(
      left.review?.memoryState?.stability,
      right.review?.memoryState?.stability,
    );
  }
}
