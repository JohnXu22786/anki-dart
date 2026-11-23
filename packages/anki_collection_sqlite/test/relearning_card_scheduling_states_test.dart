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

  group('relearningCardSchedulingStatesForCard', () {
    test(
      'matches RelearningCardState with explicit timing and stored fields',
      () async {
        final card = (await storage.getCard(Int64(1)))!;
        final resolver = (double interval, int minimum, int maximum) => 23;
        final base = ReviewSchedulingContext(
          fuzzFactor: 0.37,
          fsrsParams: const [0.2, 0.4],
          fsrsDesiredRetention: 0.91,
          fsrsNextStates: _shortTermOutcomes(),
          loadBalancedIntervalResolver: resolver,
        );

        final result = await storage.relearningCardSchedulingStatesForCard(
          cardId: card.id,
          scheduledSecs: 615,
          elapsedSecs: 278,
          baseContext: base,
        );
        final expectedContext = base
            .withDeckConfig(_config())
            .withFsrsShortTermSettings(
              allowShortTerm: false,
              shortTermWithStepsEnabled: false,
            );
        final expected = RelearningCardState.fromCard(
          card,
          scheduledSecs: 615,
          elapsedSecs: 278,
        ).nextStates(expectedContext);

        _expectStatesEqual(result, expected);
        expect(result.current.kind, LearningTransitionKind.relearning);
        expect(result.current.learning!.remainingSteps, 2);
        expect(result.current.learning!.scheduledSecs, 615);
        expect(result.current.learning!.elapsedSecs, 278);
        expect(result.current.review!.scheduledDays, 19);
        expect(result.current.review!.elapsedDays, 19);
        expect(result.current.review!.easeFactor, 2.375);
        expect(result.current.review!.lapses, 5);
        expect(result.current.review!.memoryState!.stability, 2.0);
        expect(result.good.review!.scheduledDays, 1);
        expect(expectedContext.loadBalancedIntervalResolver, same(resolver));
        expect(expectedContext.fuzzFactor, 0.37);
        expect(expectedContext.fsrsParams, [0.2, 0.4]);
        expect(expectedContext.fsrsDesiredRetention, 0.91);
      },
    );

    test('uses stored config and collection FSRS short-term flags', () async {
      final config = _config()
        ..inner.relearnSteps.clear()
        ..inner.relearnSteps.addAll([2, 7, 25])
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

      final result = await storage.relearningCardSchedulingStatesForCard(
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
        RelearningCardState.fromCard(
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
      expect(expectedContext.relearningStepsMinutes, [2, 7, 25]);
      expect(expectedContext.fsrsAllowShortTerm, isTrue);
      expect(expectedContext.fsrsShortTermWithStepsEnabled, isTrue);
      expect(expectedContext.fuzzFactor, 0.42);
      expect(expectedContext.fsrsParams, [0.8]);
      expect(expectedContext.fsrsDesiredRetention, 0.93);
    });

    test(
      'uses Core defaults without reading history or cache tables',
      () async {
        storage.deckConfigs.removeDeckConfig(Int64(10));
        await storage.writeCollectionConfig('fsrs', true);
        final base = ReviewSchedulingContext(
          fuzzFactor: 0.2,
          fsrsParams: const [0.1, 0.2, 0.3],
        );

        final result = await storage.relearningCardSchedulingStatesForCard(
          cardId: Int64(1),
          scheduledSecs: 321,
          elapsedSecs: 123,
          baseContext: base,
        );
        final config = DeckConfig(
          id: Int64(10),
          inner: DeckConfig.defaults().inner,
        );
        final expectedContext = base
            .withDeckConfig(config)
            .withFsrsShortTermSettings(
              allowShortTerm: false,
              shortTermWithStepsEnabled: false,
            );
        _expectStatesEqual(
          result,
          RelearningCardState.fromCard(
            (await storage.getCard(Int64(1)))!,
            scheduledSecs: 321,
            elapsedSecs: 123,
          ).nextStates(expectedContext),
        );
        expect(result.current.learning!.scheduledSecs, 321);
        expect(result.current.learning!.elapsedSecs, 123);
        expect(expectedContext.relearningStepsMinutes, [10.0]);
        // The fixture intentionally has no revlog or load-balancer tables.
      },
    );

    test(
      'rejects missing card, wrong card type, deck, and config ID',
      () async {
        Future<LearningCardSchedulingStates> project([CardId? id]) =>
            storage.relearningCardSchedulingStatesForCard(
              cardId: id ?? Int64(404),
              scheduledSecs: 60,
              elapsedSecs: 10,
              baseContext: const ReviewSchedulingContext(),
            );

        await expectLater(project(), _stateError('card not found'));
        await storage.executeBatch('UPDATE cards SET type = 1 WHERE id = 1');
        await expectLater(project(Int64(1)), _stateError('not a Relearn card'));
        await storage.executeBatch(
          'UPDATE cards SET type = 3, did = 404 WHERE id = 1',
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
) VALUES (1, 100, 7, 0, 0, 1, 3, 1, 0, 19, 2375, 8, 5, 2002, 0, 0, 0,
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
    expect(left.review?.scheduledDays, right.review?.scheduledDays);
    expect(left.review?.elapsedDays, right.review?.elapsedDays);
    expect(left.review?.easeFactor, right.review?.easeFactor);
    expect(left.review?.lapses, right.review?.lapses);
    expect(left.review?.leeched, right.review?.leeched);
    expect(
      left.review?.memoryState?.stability,
      right.review?.memoryState?.stability,
    );
    expect(
      left.review?.memoryState?.difficulty,
      right.review?.memoryState?.difficulty,
    );
  }
}
