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
    await _insertCard(storage, due: 17, originalDue: -8);
  });

  tearDown(() async => storage.close());

  group('reschedulingFilteredNewCardSchedulingStatesForCard', () {
    test(
      'wraps current and every answer outcome using the effective position',
      () async {
        final result = await storage
            .reschedulingFilteredNewCardSchedulingStatesForCard(
              cardId: Int64(1),
              baseContext: const ReviewSchedulingContext(),
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
          protoScheduler.SchedulingState_Normal_Kind.new_1,
        );
        expect(current.new_1.position, 0);

        final outcomes = [result.again, result.hard, result.good, result.easy];
        expect(
          outcomes.map(
            (state) => state.filtered.rescheduling.originalState.whichKind(),
          ),
          [
            protoScheduler.SchedulingState_Normal_Kind.learning,
            protoScheduler.SchedulingState_Normal_Kind.learning,
            protoScheduler.SchedulingState_Normal_Kind.learning,
            protoScheduler.SchedulingState_Normal_Kind.review,
          ],
        );
        expect(
          outcomes
              .take(3)
              .map(
                (state) => state
                    .filtered
                    .rescheduling
                    .originalState
                    .learning
                    .scheduledSecs,
              ),
          [60, 330, 600],
        );
        expect(
          outcomes
              .take(3)
              .map(
                (state) => state
                    .filtered
                    .rescheduling
                    .originalState
                    .learning
                    .remainingSteps,
              ),
          [2, 2, 1],
        );
        expect(
          outcomes
              .last
              .filtered
              .rescheduling
              .originalState
              .review
              .scheduledDays,
          4,
        );
      },
    );

    test(
      'uses the home deck config and preserves caller context fields',
      () async {
        final inner = DeckConfig.defaults().inner;
        inner.learnSteps
          ..clear()
          ..addAll([0.5, 3]);
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
            .reschedulingFilteredNewCardSchedulingStatesForCard(
              cardId: Int64(1),
              baseContext: base,
            );

        final good = result.good.filtered.rescheduling.originalState.learning;
        expect(good.scheduledSecs, 180);
        expect(good.remainingSteps, 1);
        final expected = base
            .withDeckConfig(homeConfig)
            .withFsrsShortTermSettings(
              allowShortTerm: true,
              shortTermWithStepsEnabled: true,
            );
        final direct = NewCardState(position: 0).nextStates(expected);
        expect(
          result
              .good
              .filtered
              .rescheduling
              .originalState
              .learning
              .scheduledSecs,
          direct.good.learning!.scheduledSecs,
        );
        expect(expected.fuzzFactor, 0.42);
        expect(expected.fsrsParams, [0.8]);
        expect(expected.fsrsDesiredRetention, 0.93);
        expect(expected.fsrsAllowShortTerm, isTrue);
        expect(expected.fsrsShortTermWithStepsEnabled, isTrue);
        expect(expected.fsrsNextStates, base.fsrsNextStates);
      },
    );

    test('uses Core defaults when the home config row is missing', () async {
      storage.deckConfigs.removeDeckConfig(Int64(10));

      final result = await storage
          .reschedulingFilteredNewCardSchedulingStatesForCard(
            cardId: Int64(1),
            baseContext: const ReviewSchedulingContext(),
          );

      final expected = NewCardState(position: 0).nextStates(
        const ReviewSchedulingContext().withDeckConfig(
          DeckConfig(id: Int64(10), inner: DeckConfig.defaults().inner),
        ),
      );
      expect(
        result.good.filtered.rescheduling.originalState.learning.scheduledSecs,
        expected.good.learning!.scheduledSecs,
      );
    });

    test(
      'rejects missing or invalid cards, filtered decks, and home deck config identity',
      () async {
        Future<protoScheduler.SchedulingStates> project([CardId? id]) =>
            storage.reschedulingFilteredNewCardSchedulingStatesForCard(
              cardId: id ?? Int64(404),
              baseContext: const ReviewSchedulingContext(),
            );

        await expectLater(project(), _stateError('card not found'));
        await storage.executeBatch('UPDATE cards SET did = 404 WHERE id = 1');
        await expectLater(project(Int64(1)), _stateError('deck not found'));
        await storage.executeBatch('UPDATE cards SET did = 7 WHERE id = 1');
        await storage.executeBatch('UPDATE cards SET type = 9 WHERE id = 1');
        await expectLater(
          project(Int64(1)),
          _stateError('invalid stored card'),
        );
        await storage.executeBatch('UPDATE cards SET type = 0 WHERE id = 1');
        await storage.executeBatch('UPDATE cards SET type = 2 WHERE id = 1');
        await expectLater(project(Int64(1)), _stateError('not a new card'));
        await storage.executeBatch(
          'UPDATE cards SET type = 0, did = 8 WHERE id = 1',
        );
        storage.decks.addOrUpdateDeckWithExistingId(_homeDeck(id: 8));
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

DeckConfig _config() => DeckConfig(
  id: Int64(10),
  name: 'Home config',
  inner: DeckConfig.defaults().inner,
);

Deck _homeDeck({int id = 8}) => Deck(
  id: Int64(id),
  name: 'Home',
  kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64(10))),
);

Deck _filteredDeck({bool reschedule = true}) => Deck(
  id: Int64(7),
  name: 'Filtered',
  kind: FilteredDeckKind(protoDeck.Deck_Filtered(reschedule: reschedule)),
);

Future<void> _insertCard(
  CollectionSqliteStorage storage, {
  required int due,
  required int originalDue,
}) => storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES (1, 100, 7, 0, 0, 0, 0, 0, $due, 0, 0, 0, 0, 0, $originalDue, 8, 0, '');
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

Matcher _stateError(String message) => throwsA(
  isA<StateError>().having(
    (error) => error.message,
    'message',
    contains(message),
  ),
);
