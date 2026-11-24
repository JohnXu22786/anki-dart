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
CREATE TABLE decks (
  id INTEGER PRIMARY KEY NOT NULL,
  name TEXT NOT NULL COLLATE NOCASE,
  mtime_secs INTEGER NOT NULL,
  usn INTEGER NOT NULL,
  common BLOB NOT NULL,
  kind BLOB NOT NULL
);
CREATE TABLE col (crt INTEGER NOT NULL, conf TEXT NOT NULL);
CREATE TABLE config (key TEXT PRIMARY KEY, usn INTEGER, mtime_secs INTEGER, val BLOB);
INSERT INTO col VALUES (1700000000, '{}');
''');
    storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck());
  });

  tearDown(() async => storage.close());

  test('wraps each current card state and preserves its fields', () async {
    await _insertCard(
      storage,
      id: 1,
      type: CardType.newCard,
      due: 27,
      originalDue: 31,
    );
    await _insertCard(
      storage,
      id: 2,
      type: CardType.learn,
      due: 88,
      left: 2002,
      data: '{"s":2.5,"d":4.5}',
    );
    await _insertCard(
      storage,
      id: 3,
      type: CardType.review,
      due: 5,
      interval: 30,
      originalDue: 40,
      easeFactor: 2300,
      lapses: 6,
      data: '{"s":3.5,"d":5.5}',
    );
    await _insertCard(
      storage,
      id: 4,
      type: CardType.relearn,
      due: 88,
      interval: 30,
      left: 1001,
      easeFactor: 2300,
      lapses: 6,
      data: '{"s":3.5,"d":5.5}',
    );

    final newState = await _project(storage, 1);
    expect(newState.whichKind(), protoScheduler.SchedulingState_Kind.filtered);
    expect(
      newState.filtered.whichKind(),
      protoScheduler.SchedulingState_Filtered_Kind.rescheduling,
    );
    expect(
      newState.filtered.rescheduling.originalState.whichKind(),
      protoScheduler.SchedulingState_Normal_Kind.new_1,
    );
    expect(newState.filtered.rescheduling.originalState.new_1.position, 31);

    final learnState = await _project(storage, 2);
    final learning = learnState.filtered.rescheduling.originalState.learning;
    expect(
      learnState.filtered.rescheduling.originalState.whichKind(),
      protoScheduler.SchedulingState_Normal_Kind.learning,
    );
    expect(learning.remainingSteps, 2);
    expect(learning.scheduledSecs, 617);
    expect(learning.elapsedSecs, 281);
    expect(learning.memoryState.stability, 2.5);
    expect(learning.memoryState.difficulty, 4.5);

    final reviewState = await _project(storage, 3);
    final review = reviewState.filtered.rescheduling.originalState.review;
    expect(
      reviewState.filtered.rescheduling.originalState.whichKind(),
      protoScheduler.SchedulingState_Normal_Kind.review,
    );
    expect(review.scheduledDays, 30);
    expect(review.elapsedDays, 2);
    expect(review.easeFactor, closeTo(2.3, 0.0001));
    expect(review.lapses, 6);
    expect(review.leeched, isFalse);
    expect(review.memoryState.stability, 3.5);
    expect(review.memoryState.difficulty, 5.5);

    final relearnState = await _project(storage, 4);
    final relearning =
        relearnState.filtered.rescheduling.originalState.relearning;
    expect(
      relearnState.filtered.rescheduling.originalState.whichKind(),
      protoScheduler.SchedulingState_Normal_Kind.relearning,
    );
    expect(relearning.learning.remainingSteps, 1);
    expect(relearning.learning.scheduledSecs, 617);
    expect(relearning.learning.elapsedSecs, 281);
    expect(relearning.review.scheduledDays, 30);
    expect(relearning.review.elapsedDays, 30);
    expect(relearning.review.easeFactor, closeTo(2.3, 0.0001));
    expect(relearning.review.lapses, 6);
    expect(relearning.review.leeched, isFalse);
    expect(relearning.review.memoryState.stability, 3.5);
    expect(relearning.review.memoryState.difficulty, 5.5);
  });

  test(
    'requires explicit timing and rejects missing or unsupported kinds',
    () async {
      await expectLater(_project(storage, 404), _stateError('card not found'));

      await _insertCard(storage, id: 1, type: CardType.learn);
      await expectLater(
        storage.currentReschedulingFilteredCardSchedulingState(
          cardId: Int64(1),
        ),
        _stateError('scheduledSecs and elapsedSecs are required'),
      );
      await _insertCard(storage, id: 2, type: CardType.relearn, left: 1001);
      await expectLater(
        storage.currentReschedulingFilteredCardSchedulingState(
          cardId: Int64(2),
        ),
        _stateError('scheduledSecs and elapsedSecs are required'),
      );
      await storage.executeBatch('UPDATE cards SET did = 404 WHERE id = 1');
      await expectLater(_project(storage, 1), _stateError('deck not found'));

      await storage.executeBatch(
        'UPDATE cards SET did = 7, type = 5 WHERE id = 1',
      );
      await expectLater(
        _project(storage, 1),
        _stateError('unsupported card type'),
      );

      await storage.executeBatch('UPDATE cards SET type = 1 WHERE id = 1');
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
      await expectLater(
        _project(storage, 1),
        _stateError('filtered deck required'),
      );

      storage.decks.addOrUpdateDeckWithExistingId(
        _filteredDeck(reschedule: false),
      );
      await expectLater(
        _project(storage, 1),
        _stateError('does not reschedule'),
      );
    },
  );
}

Deck _filteredDeck({bool reschedule = true}) => Deck(
  id: Int64(7),
  name: 'Filtered',
  kind: FilteredDeckKind(protoDeck.Deck_Filtered(reschedule: reschedule)),
);

Deck _normalDeck() => Deck(
  id: Int64(7),
  name: 'Normal',
  kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64.ONE)),
);

Future<void> _insertCard(
  CollectionSqliteStorage storage, {
  required int id,
  required CardType type,
  int due = 0,
  int originalDue = 0,
  int interval = 0,
  int easeFactor = 2500,
  int lapses = 0,
  int left = 0,
  String data = '',
}) => storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES ($id, 2, 7, 0, 1, 0, ${type.value}, ${type.value}, $due, $interval,
          $easeFactor, 3, $lapses, $left, $originalDue, 0, 0, '$data');
''');

Matcher _stateError(String text) => throwsA(
  isA<StateError>().having((error) => error.message, 'message', contains(text)),
);

Future<protoScheduler.SchedulingState> _project(
  CollectionSqliteStorage storage,
  int id,
) => storage.currentReschedulingFilteredCardSchedulingState(
  cardId: Int64(id),
  scheduledSecs: 617,
  elapsedSecs: 281,
  now: DateTime.fromMillisecondsSinceEpoch(
    (1700000000 + 12 * Duration.secondsPerDay + 1234) * 1000,
    isUtc: true,
  ),
);
