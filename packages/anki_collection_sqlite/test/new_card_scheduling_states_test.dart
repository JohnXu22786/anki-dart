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
    await _insertCard(storage, due: 17);
  });

  tearDown(() async => storage.close());

  group('newCardSchedulingStatesForCard', () {
    test(
      'clamps stored due to Core new-card position and returns all buttons',
      () async {
        for (final due in [-8, 17]) {
          await storage.executeBatch(
            'UPDATE cards SET due = $due WHERE id = 1',
          );
          final result = await storage.newCardSchedulingStatesForCard(
            cardId: Int64(1),
            baseContext: const ReviewSchedulingContext(
              fuzzFactor: 0.3,
              fsrsParams: [0.1, 0.2],
            ),
          );
          final expected = NewCardState(position: due < 0 ? 0 : due).nextStates(
            const ReviewSchedulingContext(
              fuzzFactor: 0.3,
              fsrsParams: [0.1, 0.2],
            ).withDeckConfig(_config()),
          );
          expect(result.current.newCard!.position, due < 0 ? 0 : due);
          _expectStatesEqual(result, expected);
        }
      },
    );

    test(
      'projects stored steps, graduating intervals, multipliers and FSRS flags',
      () async {
        final config = _config()
          ..inner.learnSteps.clear()
          ..inner.learnSteps.addAll([1, 10, 60])
          ..inner.graduatingIntervalGood = 3
          ..inner.graduatingIntervalEasy = 8
          ..inner.hardMultiplier = 1.7
          ..inner.easyMultiplier = 2.2
          ..inner.intervalMultiplier = 1.4
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

        final result = await storage.newCardSchedulingStatesForCard(
          cardId: Int64(1),
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
          NewCardState(position: 17).nextStates(expectedContext),
        );
        expect(result.current.newCard!.position, 17);
        expect(result.good.kind, LearningTransitionKind.learning);
        expect(result.again.learning!.remainingSteps, 3);
        expect(result.again.learning!.scheduledSecs, 60);
      },
    );

    test(
      'uses defaults for missing config rows and preserves caller context',
      () async {
        storage.deckConfigs.removeDeckConfig(Int64(10));
        final base = ReviewSchedulingContext(
          hardMultiplier: 1.8,
          fuzzFactor: 0.2,
          fsrsParams: const [0.1, 0.2, 0.3],
          fsrsDesiredRetention: 0.91,
          fsrsAllowShortTerm: true,
          fsrsShortTermWithStepsEnabled: true,
        );

        final result = await storage.newCardSchedulingStatesForCard(
          cardId: Int64(1),
          baseContext: base,
        );

        final expectedContext = base
            .withDeckConfig(
              DeckConfig(id: Int64(10), inner: DeckConfig.defaults().inner),
            )
            .withFsrsShortTermSettings(
              allowShortTerm: false,
              shortTermWithStepsEnabled: false,
            );
        _expectStatesEqual(
          result,
          NewCardState(position: 17).nextStates(expectedContext),
        );
        expect(expectedContext.fuzzFactor, 0.2);
        expect(expectedContext.fsrsParams, [0.1, 0.2, 0.3]);
        expect(expectedContext.fsrsDesiredRetention, 0.91);
      },
    );

    test('does not read revlogs or load-balancer timing/history', () async {
      // This fixture intentionally has no revlog or collection timing tables.
      // Enabling FSRS must not make a new-card projection read memory history.
      await storage.writeCollectionConfig('fsrs', true);
      final result = await storage.newCardSchedulingStatesForCard(
        cardId: Int64(1),
        baseContext: const ReviewSchedulingContext(),
      );
      expect(result.current.newCard!.position, 17);
    });

    test(
      'rejects missing cards, non-new cards, missing config IDs and filtered decks',
      () async {
        await expectLater(
          storage.newCardSchedulingStatesForCard(
            cardId: Int64(404),
            baseContext: const ReviewSchedulingContext(),
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('card not found'),
            ),
          ),
        );
        await storage.executeBatch('UPDATE cards SET type = 2 WHERE id = 1');
        await expectLater(
          storage.newCardSchedulingStatesForCard(
            cardId: Int64(1),
            baseContext: const ReviewSchedulingContext(),
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('not a new card'),
            ),
          ),
        );
        await storage.executeBatch('UPDATE cards SET type = 0 WHERE id = 1');
        storage.decks.addOrUpdateDeckWithExistingId(
          Deck(
            id: Int64(7),
            name: 'Filtered',
            kind: FilteredDeckKind(protoDeck.Deck_Filtered()),
          ),
        );
        await expectLater(
          storage.newCardSchedulingStatesForCard(
            cardId: Int64(1),
            baseContext: const ReviewSchedulingContext(),
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('filtered deck'),
            ),
          ),
        );
        storage.decks.addOrUpdateDeckWithExistingId(
          Deck(
            id: Int64(7),
            name: 'No config',
            kind: NormalDeckKind(protoDeck.Deck_Normal()),
          ),
        );
        await expectLater(
          storage.newCardSchedulingStatesForCard(
            cardId: Int64(1),
            baseContext: const ReviewSchedulingContext(),
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('no config ID'),
            ),
          ),
        );
        storage.decks.removeDeck(Int64(7));
        await expectLater(
          storage.newCardSchedulingStatesForCard(
            cardId: Int64(1),
            baseContext: const ReviewSchedulingContext(),
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('deck not found'),
            ),
          ),
        );
      },
    );
  });
}

DeckConfig _config() => DeckConfig(
  id: Int64(10),
  name: 'Default',
  inner: DeckConfig.defaults().inner,
);

FsrsReviewNextStates _shortTermOutcomes() => FsrsReviewNextStates(
  again: _shortTermOutcome(),
  hard: _shortTermOutcome(),
  good: _shortTermOutcome(),
  easy: _shortTermOutcome(),
);

FsrsReviewNextState _shortTermOutcome() => FsrsReviewNextState(
  interval: 0.25,
  memoryState: FsrsMemoryState(stability: 2, difficulty: 4),
);

Deck _normalDeck() => Deck(
  id: Int64(7),
  name: 'Deck 7',
  kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
);

Future<void> _insertCard(CollectionSqliteStorage storage, {required int due}) =>
    storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES (1, 100, 7, 0, 0, 0, 0, 0, $due, 0, 0, 0, 0, 0, 0, 0, 0, '');
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
    expect(left.newCard?.position, right.newCard?.position);
    final leftLearning = left.learning;
    final rightLearning = right.learning;
    if (leftLearning != null && rightLearning != null) {
      expect(leftLearning.remainingSteps, rightLearning.remainingSteps);
      expect(leftLearning.scheduledSecs, rightLearning.scheduledSecs);
      expect(leftLearning.elapsedSecs, rightLearning.elapsedSecs);
    }
    final leftReview = left.review;
    final rightReview = right.review;
    if (leftReview != null && rightReview != null) {
      expect(leftReview.scheduledDays, rightReview.scheduledDays);
      expect(leftReview.elapsedDays, rightReview.elapsedDays);
      expect(leftReview.easeFactor, rightReview.easeFactor);
      expect(leftReview.lapses, rightReview.lapses);
      expect(leftReview.leeched, rightReview.leeched);
      expect(leftReview.memoryState, rightReview.memoryState);
    }
  }
}
