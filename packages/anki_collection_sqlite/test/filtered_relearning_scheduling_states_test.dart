// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as protoDeck;
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as protoScheduler;
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
  id INTEGER PRIMARY KEY NOT NULL, name TEXT NOT NULL COLLATE NOCASE,
  mtime_secs INTEGER NOT NULL, usn INTEGER NOT NULL, config BLOB NOT NULL
);
CREATE TABLE config (key TEXT PRIMARY KEY, usn INTEGER, mtime_secs INTEGER, val BLOB);
CREATE TABLE decks (
  id INTEGER PRIMARY KEY NOT NULL, name TEXT NOT NULL COLLATE NOCASE,
  mtime_secs INTEGER NOT NULL, usn INTEGER NOT NULL, common BLOB NOT NULL,
  kind BLOB NOT NULL
);
''');
    storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(_config());
    storage.decks.addOrUpdateDeckWithExistingId(_homeDeck());
    storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck());
    await storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES (1, 100, 7, 0, 0, 0, 3, 1, 999, 19, 2375, 8, 5, 2002, 0, 8, 0,
          '{"s":2,"d":4}');
''');
  });

  tearDown(() async => storage.close());

  group('reschedulingFilteredRelearningCardSchedulingStatesForCard', () {
    test(
      'wraps paired current state and all answer transitions with exact timings',
      () async {
        const scheduledSecs = 617;
        const elapsedSecs = 281;
        final base = ReviewSchedulingContext(fuzzFactor: 0.37);
        final result = await storage
            .reschedulingFilteredRelearningCardSchedulingStatesForCard(
              cardId: Int64(1),
              scheduledSecs: scheduledSecs,
              elapsedSecs: elapsedSecs,
              baseContext: base,
            );
        for (final state in [
          result.current,
          result.again,
          result.hard,
          result.good,
          result.easy,
        ]) {
          expect(
            state.whichKind(),
            protoScheduler.SchedulingState_Kind.filtered,
          );
          expect(
            state.filtered.whichKind(),
            protoScheduler.SchedulingState_Filtered_Kind.rescheduling,
          );
        }
        final current = result.current.filtered.rescheduling.originalState;
        expect(
          current.whichKind(),
          protoScheduler.SchedulingState_Normal_Kind.relearning,
        );
        expect(current.relearning.learning.remainingSteps, 2);
        expect(current.relearning.learning.scheduledSecs, scheduledSecs);
        expect(current.relearning.learning.elapsedSecs, elapsedSecs);
        expect(current.relearning.review.scheduledDays, 19);
        expect(current.relearning.review.elapsedDays, 19);
        expect(current.relearning.review.easeFactor, 2.375);
        expect(current.relearning.review.lapses, 5);
        expect(current.relearning.review.memoryState.stability, 2.0);
        final card = (await storage.getCard(Int64(1)))!;
        final expected =
            RelearningCardState.fromCard(
              card,
              scheduledSecs: scheduledSecs,
              elapsedSecs: elapsedSecs,
            ).nextStates(
              base
                  .withDeckConfig(_config())
                  .withFsrsShortTermSettings(
                    allowShortTerm: false,
                    shortTermWithStepsEnabled: false,
                  ),
            );
        for (final (actual, transition) in [
          (result.again, expected.again),
          (result.hard, expected.hard),
          (result.good, expected.good),
          (result.easy, expected.easy),
        ]) {
          _expectTransition(
            actual.filtered.rescheduling.originalState,
            transition,
          );
        }
        expect(base.fuzzFactor, 0.37);
      },
    );

    test(
      'uses home config, defaults for missing config rows, and caller context',
      () async {
        final inner = DeckConfig.defaults().inner
          ..relearnSteps.clear()
          ..relearnSteps.addAll([2, 7, 25])
          ..fsrsParams6.addAll(List<double>.filled(21, 0.25));
        final config = DeckConfig(id: Int64(10), name: 'Home', inner: inner);
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
        );
        final result = await storage
            .reschedulingFilteredRelearningCardSchedulingStatesForCard(
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
        final expected = RelearningCardState.fromCard(
          (await storage.getCard(Int64(1)))!,
          scheduledSecs: 120,
          elapsedSecs: 60,
        ).nextStates(expectedContext);
        _expectTransition(
          result.good.filtered.rescheduling.originalState,
          expected.good,
        );
        expect(
          result.good.filtered.rescheduling.originalState.whichKind(),
          protoScheduler.SchedulingState_Normal_Kind.relearning,
        );
        expect(
          result
              .good
              .filtered
              .rescheduling
              .originalState
              .relearning
              .learning
              .scheduledSecs,
          1500,
        );
        expect(expectedContext.relearningStepsMinutes, [2, 7, 25]);
        expect(expectedContext.fsrsAllowShortTerm, isTrue);
        expect(expectedContext.fsrsShortTermWithStepsEnabled, isTrue);
        expect(expectedContext.fuzzFactor, 0.42);
        expect(expectedContext.fsrsParams, [0.8]);
        expect(expectedContext.fsrsDesiredRetention, 0.93);

        storage.deckConfigs.removeDeckConfig(Int64(10));
        final defaults = await storage
            .reschedulingFilteredRelearningCardSchedulingStatesForCard(
              cardId: Int64(1),
              scheduledSecs: 321,
              elapsedSecs: 123,
              baseContext: const ReviewSchedulingContext(),
            );
        final defaultContext = const ReviewSchedulingContext()
            .withDeckConfig(
              DeckConfig(id: Int64(10), inner: DeckConfig.defaults().inner),
            )
            .withFsrsShortTermSettings(
              allowShortTerm: false,
              shortTermWithStepsEnabled: false,
            );
        final defaultExpected = RelearningCardState.fromCard(
          (await storage.getCard(Int64(1)))!,
          scheduledSecs: 321,
          elapsedSecs: 123,
        ).nextStates(defaultContext);
        _expectTransition(
          defaults.again.filtered.rescheduling.originalState,
          defaultExpected.again,
        );
        expect(
          defaults
              .current
              .filtered
              .rescheduling
              .originalState
              .relearning
              .learning
              .scheduledSecs,
          321,
        );
      },
    );

    test(
      'rejects missing/invalid cards, wrong card type, and invalid deck identities',
      () async {
        Future<protoScheduler.SchedulingStates> project([CardId? id]) =>
            storage.reschedulingFilteredRelearningCardSchedulingStatesForCard(
              cardId: id ?? Int64(404),
              scheduledSecs: 60,
              elapsedSecs: 10,
              baseContext: const ReviewSchedulingContext(),
            );
        await expectLater(project(), _stateError('card not found'));
        await storage.executeBatch('UPDATE cards SET type = 9 WHERE id = 1');
        await expectLater(
          project(Int64(1)),
          _stateError('invalid stored card'),
        );
        await storage.executeBatch('UPDATE cards SET type = 1 WHERE id = 1');
        await expectLater(project(Int64(1)), _stateError('not a Relearn card'));
        await storage.executeBatch(
          'UPDATE cards SET type = 3, did = 404 WHERE id = 1',
        );
        await expectLater(project(Int64(1)), _stateError('deck not found'));
        await storage.executeBatch('UPDATE cards SET did = 8 WHERE id = 1');
        await expectLater(
          project(Int64(1)),
          _stateError('filtered deck required'),
        );
        await storage.executeBatch('UPDATE cards SET did = 7 WHERE id = 1');
        storage.decks.addOrUpdateDeckWithExistingId(
          _filteredDeck(reschedule: false),
        );
        await expectLater(
          project(Int64(1)),
          _stateError('does not reschedule'),
        );
        storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck());
        await storage.executeBatch('UPDATE cards SET odid = 0 WHERE id = 1');
        await expectLater(project(Int64(1)), _stateError('original deck ID'));
        await storage.executeBatch('UPDATE cards SET odid = 404 WHERE id = 1');
        await expectLater(
          project(Int64(1)),
          _stateError('home deck not found'),
        );
        await storage.executeBatch('UPDATE cards SET odid = 7 WHERE id = 1');
        await expectLater(project(Int64(1)), _stateError('not a normal deck'));
        await storage.executeBatch('UPDATE cards SET odid = 9 WHERE id = 1');
        storage.decks.addOrUpdateDeckWithExistingId(
          Deck(
            id: Int64(9),
            name: 'Home without config',
            kind: NormalDeckKind(protoDeck.Deck_Normal()),
          ),
        );
        await expectLater(project(Int64(1)), _stateError('no config ID'));
      },
    );
  });
}

void _expectTransition(
  protoScheduler.SchedulingState_Normal actual,
  LearningCardTransition expected,
) {
  switch (expected.kind) {
    case LearningTransitionKind.relearning:
      expect(
        actual.whichKind(),
        protoScheduler.SchedulingState_Normal_Kind.relearning,
      );
      expect(
        actual.relearning.learning.remainingSteps,
        expected.learning!.remainingSteps,
      );
      expect(
        actual.relearning.learning.scheduledSecs,
        expected.learning!.scheduledSecs,
      );
      expect(
        actual.relearning.learning.elapsedSecs,
        expected.learning!.elapsedSecs,
      );
      expect(
        actual.relearning.review.scheduledDays,
        expected.review!.scheduledDays,
      );
      expect(actual.relearning.review.easeFactor, expected.review!.easeFactor);
      expect(actual.relearning.review.lapses, expected.review!.lapses);
    case LearningTransitionKind.learning:
      expect(
        actual.whichKind(),
        protoScheduler.SchedulingState_Normal_Kind.learning,
      );
      expect(actual.learning.remainingSteps, expected.learning!.remainingSteps);
      expect(actual.learning.scheduledSecs, expected.learning!.scheduledSecs);
      expect(actual.learning.elapsedSecs, expected.learning!.elapsedSecs);
    case LearningTransitionKind.review:
      expect(
        actual.whichKind(),
        protoScheduler.SchedulingState_Normal_Kind.review,
      );
      expect(actual.review.scheduledDays, expected.review!.scheduledDays);
      expect(actual.review.elapsedDays, expected.review!.elapsedDays);
      expect(actual.review.easeFactor, expected.review!.easeFactor);
      expect(actual.review.lapses, expected.review!.lapses);
    case LearningTransitionKind.newCard:
      fail('Relearn transition cannot be New');
  }
}

DeckConfig _config() =>
    DeckConfig(id: Int64(10), name: 'Home', inner: DeckConfig.defaults().inner);
Deck _homeDeck() => Deck(
  id: Int64(8),
  name: 'Home',
  kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
);
Deck _filteredDeck({bool reschedule = true}) => Deck(
  id: Int64(7),
  name: 'Filtered',
  kind: FilteredDeckKind(protoDeck.Deck_Filtered(reschedule: reschedule)),
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
    interval: 1,
    memoryState: FsrsMemoryState(stability: 5, difficulty: 4),
  ),
);
Matcher _stateError(String text) => throwsA(
  isA<StateError>().having((error) => error.message, 'message', contains(text)),
);
