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
    await _insertLearningCard(storage);
  });

  tearDown(() async => storage.close());

  group('reschedulingFilteredLearningCardSchedulingStatesForCard', () {
    test(
      'wraps current and every answer with explicit Learn timings',
      () async {
        const scheduledSecs = 617;
        const elapsedSecs = 281;
        final base = ReviewSchedulingContext(fuzzFactor: 0.37);
        final result = await storage
            .reschedulingFilteredLearningCardSchedulingStatesForCard(
              cardId: Int64(1),
              scheduledSecs: scheduledSecs,
              elapsedSecs: elapsedSecs,
              baseContext: base,
            );

        final wrapped = [
          result.current,
          result.again,
          result.hard,
          result.good,
          result.easy,
        ];
        for (final state in wrapped) {
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
          protoScheduler.SchedulingState_Normal_Kind.learning,
        );
        expect(current.learning.remainingSteps, 2);
        expect(current.learning.scheduledSecs, scheduledSecs);
        expect(current.learning.elapsedSecs, elapsedSecs);
        expect(current.learning.memoryState.stability, 2.0);
        expect(current.learning.memoryState.difficulty, 4.0);

        final card = (await storage.getCard(Int64(1)))!;
        final context = base
            .withDeckConfig(_config())
            .withFsrsShortTermSettings(
              allowShortTerm: false,
              shortTermWithStepsEnabled: false,
            );
        final expected = LearningCardState.fromCard(
          card,
          scheduledSecs: scheduledSecs,
          elapsedSecs: elapsedSecs,
        ).nextStates(context);
        for (final (actual, transition) in [
          (result.again, expected.again),
          (result.hard, expected.hard),
          (result.good, expected.good),
          (result.easy, expected.easy),
        ]) {
          _expectNormalTransition(
            actual.filtered.rescheduling.originalState,
            transition,
          );
        }
        expect(base.fuzzFactor, 0.37);
      },
    );

    test(
      'uses home config and composes FSRS flags without losing context',
      () async {
        final inner = DeckConfig.defaults().inner;
        inner.learnSteps
          ..clear()
          ..addAll([2, 7, 25]);
        inner.fsrsParams6.addAll(List<double>.filled(21, 0.25));
        final homeConfig = DeckConfig(
          id: Int64(10),
          name: 'Home config',
          inner: inner,
        );
        storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(homeConfig);
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
            .reschedulingFilteredLearningCardSchedulingStatesForCard(
              cardId: Int64(1),
              scheduledSecs: 120,
              elapsedSecs: 60,
              baseContext: base,
            );
        final expectedContext = base
            .withDeckConfig(homeConfig)
            .withFsrsShortTermSettings(
              allowShortTerm: true,
              shortTermWithStepsEnabled: true,
            );
        final expected = LearningCardState.fromCard(
          (await storage.getCard(Int64(1)))!,
          scheduledSecs: 120,
          elapsedSecs: 60,
        ).nextStates(expectedContext);
        for (final (actual, transition) in [
          (result.again, expected.again),
          (result.hard, expected.hard),
          (result.good, expected.good),
          (result.easy, expected.easy),
        ]) {
          _expectNormalTransition(
            actual.filtered.rescheduling.originalState,
            transition,
          );
        }
        expect(
          result
              .good
              .filtered
              .rescheduling
              .originalState
              .learning
              .scheduledSecs,
          1500,
        );
        expect(
          result
              .good
              .filtered
              .rescheduling
              .originalState
              .learning
              .remainingSteps,
          1,
        );
        expect(expectedContext.learningStepsMinutes, [2, 7, 25]);
        expect(expectedContext.fsrsAllowShortTerm, isTrue);
        expect(expectedContext.fsrsShortTermWithStepsEnabled, isTrue);
        expect(expectedContext.fuzzFactor, 0.42);
        expect(expectedContext.fsrsParams, [0.8]);
        expect(expectedContext.fsrsDesiredRetention, 0.93);
        expect(expectedContext.fsrsNextStates, base.fsrsNextStates);
      },
    );

    test(
      'uses Core defaults when the home deck config row is absent',
      () async {
        storage.deckConfigs.removeDeckConfig(Int64(10));
        const base = ReviewSchedulingContext();
        final result = await storage
            .reschedulingFilteredLearningCardSchedulingStatesForCard(
              cardId: Int64(1),
              scheduledSecs: 321,
              elapsedSecs: 123,
              baseContext: base,
            );
        final defaultConfig = DeckConfig(
          id: Int64(10),
          inner: DeckConfig.defaults().inner,
        );
        final expected =
            LearningCardState.fromCard(
              (await storage.getCard(Int64(1)))!,
              scheduledSecs: 321,
              elapsedSecs: 123,
            ).nextStates(
              base
                  .withDeckConfig(defaultConfig)
                  .withFsrsShortTermSettings(
                    allowShortTerm: false,
                    shortTermWithStepsEnabled: false,
                  ),
            );
        _expectNormalTransition(
          result.again.filtered.rescheduling.originalState,
          expected.again,
        );
        _expectNormalTransition(
          result.easy.filtered.rescheduling.originalState,
          expected.easy,
        );
      },
    );

    test(
      'rejects missing, invalid, wrong-type, and unsupported deck inputs',
      () async {
        Future<protoScheduler.SchedulingStates> project([CardId? id]) =>
            storage.reschedulingFilteredLearningCardSchedulingStatesForCard(
              cardId: id ?? Int64(404),
              scheduledSecs: 60,
              elapsedSecs: 10,
              baseContext: const ReviewSchedulingContext(),
            );

        await expectLater(project(), _stateError('card not found'));
        await storage.executeBatch('UPDATE cards SET did = 404 WHERE id = 1');
        await expectLater(project(Int64(1)), _stateError('deck not found'));
        await storage.executeBatch(
          'UPDATE cards SET did = 7, type = 9 WHERE id = 1',
        );
        await expectLater(
          project(Int64(1)),
          _stateError('invalid stored card'),
        );
        await storage.executeBatch('UPDATE cards SET type = 0 WHERE id = 1');
        await expectLater(
          project(Int64(1)),
          _stateError('not a learning card'),
        );

        await storage.executeBatch(
          'UPDATE cards SET type = 1, did = 8 WHERE id = 1',
        );
        storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(id: 8));
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
        await storage.executeBatch('UPDATE cards SET odid = 404 WHERE id = 1');
        await expectLater(
          project(Int64(1)),
          _stateError('home deck not found'),
        );
        await storage.executeBatch('UPDATE cards SET odid = 0 WHERE id = 1');
        await expectLater(project(Int64(1)), _stateError('original deck ID'));
        await storage.executeBatch('UPDATE cards SET odid = 8 WHERE id = 1');
        storage.decks.addOrUpdateDeckWithExistingId(
          Deck(
            id: Int64(8),
            name: 'Home without config',
            kind: NormalDeckKind(protoDeck.Deck_Normal()),
          ),
        );
        await expectLater(project(Int64(1)), _stateError('no config ID'));
      },
    );
  });
}

void _expectNormalTransition(
  protoScheduler.SchedulingState_Normal actual,
  LearningCardTransition expected,
) {
  switch (expected.kind) {
    case LearningTransitionKind.learning:
      expect(
        actual.whichKind(),
        protoScheduler.SchedulingState_Normal_Kind.learning,
      );
      expect(actual.learning.remainingSteps, expected.learning!.remainingSteps);
      expect(actual.learning.scheduledSecs, expected.learning!.scheduledSecs);
      expect(actual.learning.elapsedSecs, expected.learning!.elapsedSecs);
      expect(
        actual.learning.memoryState.stability,
        expected.learning!.memoryState?.stability ?? 0,
      );
      expect(
        actual.learning.memoryState.difficulty,
        expected.learning!.memoryState?.difficulty ?? 0,
      );
    case LearningTransitionKind.review:
      expect(
        actual.whichKind(),
        protoScheduler.SchedulingState_Normal_Kind.review,
      );
      expect(actual.review.scheduledDays, expected.review!.scheduledDays);
      expect(actual.review.elapsedDays, expected.review!.elapsedDays);
      expect(actual.review.easeFactor, expected.review!.easeFactor);
      expect(actual.review.lapses, expected.review!.lapses);
      expect(actual.review.leeched, expected.review!.leeched);
      expect(
        actual.review.memoryState.stability,
        expected.review!.memoryState?.stability ?? 0,
      );
      expect(
        actual.review.memoryState.difficulty,
        expected.review!.memoryState?.difficulty ?? 0,
      );
    case LearningTransitionKind.newCard:
      fail('Learn card transition cannot become New');
    case LearningTransitionKind.relearning:
      fail('Learn card transition cannot be Relearn');
  }
}

DeckConfig _config() => DeckConfig(
  id: Int64(10),
  name: 'Home config',
  inner: DeckConfig.defaults().inner,
);

Deck _homeDeck() => Deck(
  id: Int64(8),
  name: 'Home',
  kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
);

Deck _normalDeck({required int id}) => Deck(
  id: Int64(id),
  name: 'Normal',
  kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
);

Deck _filteredDeck({bool reschedule = true}) => Deck(
  id: Int64(7),
  name: 'Filtered',
  kind: FilteredDeckKind(protoDeck.Deck_Filtered(reschedule: reschedule)),
);

Future<void> _insertLearningCard(CollectionSqliteStorage storage) =>
    storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES (1, 100, 7, 0, 0, 0, 1, 1, 999, 0, 2500, 3, 0, 1002, 0, 8, 0,
          '{"s":2,"d":4}');
''');

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

Matcher _stateError(String text) => throwsA(
  isA<StateError>().having((error) => error.message, 'message', contains(text)),
);
