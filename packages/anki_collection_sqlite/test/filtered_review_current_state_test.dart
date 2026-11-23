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

  group('currentReschedulingFilteredReviewCardStateForNow', () {
    const creationSecs = 1700000000;
    final now = DateTime.fromMillisecondsSinceEpoch(
      (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
      isUtc: true,
    );

    test('uses nonzero original due without clamping to today', () async {
      await _insertReviewCard(storage, due: 5, originalDue: 40);

      final state = await storage
          .currentReschedulingFilteredReviewCardStateForNow(
            cardId: Int64(1),
            now: now,
          );

      expect(state.scheduledDays, 30);
      expect(state.elapsedDays, 2);
    });

    test('falls back to stored due when original due is zero', () async {
      await _insertReviewCard(storage, due: 7, originalDue: 0);

      final state = await storage
          .currentReschedulingFilteredReviewCardStateForNow(
            cardId: Int64(1),
            now: now,
          );

      expect(state.scheduledDays, 30);
      expect(state.elapsedDays, 35);
    });

    test('derives elapsed days from the supplied timing snapshot', () async {
      await _insertReviewCard(storage, due: 32, originalDue: 0);
      final timing = storage.timingTodayForNow(now: now);

      final state = await storage
          .currentReschedulingFilteredReviewCardStateForNow(
            cardId: Int64(1),
            now: now,
          );

      expect(state.elapsedDays, 30 - (32 - timing.daysElapsed));
      expect(state.elapsedDays, 10);
    });

    test('rejects missing card or deck and invalid card/deck kinds', () async {
      await expectLater(
        storage.currentReschedulingFilteredReviewCardStateForNow(
          cardId: Int64(404),
          now: now,
        ),
        _stateError('card not found'),
      );

      await _insertReviewCard(storage, due: 7, originalDue: 0);
      await storage.executeBatch('UPDATE cards SET did = 404 WHERE id = 1');
      await expectLater(
        storage.currentReschedulingFilteredReviewCardStateForNow(
          cardId: Int64(1),
          now: now,
        ),
        _stateError('deck not found'),
      );

      await storage.executeBatch(
        'UPDATE cards SET did = 7, type = 0 WHERE id = 1',
      );
      await expectLater(
        storage.currentReschedulingFilteredReviewCardStateForNow(
          cardId: Int64(1),
          now: now,
        ),
        _stateError('not a review card'),
      );

      await storage.executeBatch('UPDATE cards SET type = 2 WHERE id = 1');
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
      await expectLater(
        storage.currentReschedulingFilteredReviewCardStateForNow(
          cardId: Int64(1),
          now: now,
        ),
        _stateError('filtered deck required'),
      );

      storage.decks.addOrUpdateDeckWithExistingId(
        _filteredDeck(reschedule: false),
      );
      await expectLater(
        storage.currentReschedulingFilteredReviewCardStateForNow(
          cardId: Int64(1),
          now: now,
        ),
        _stateError('does not reschedule'),
      );
    });
  });
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

Future<void> _insertReviewCard(
  CollectionSqliteStorage storage, {
  required int due,
  required int originalDue,
}) => storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES (1, 2, 7, 0, 1, 0, 2, 2, $due, 30, 2450, 4, 6, 0,
          $originalDue, 0, 0, '');
''');

Matcher _stateError(String text) => throwsA(
  isA<StateError>().having((error) => error.message, 'message', contains(text)),
);
