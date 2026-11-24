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
''');
    storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck());
  });

  tearDown(() async => storage.close());

  group('currentReschedulingFilteredRelearningCardState', () {
    test('forwards timing and preserves paired current state fields', () async {
      await _insertRelearningCard(storage);
      final card = (await storage.getCard(Int64(1)))!;

      final state = await storage
          .currentReschedulingFilteredRelearningCardState(
            cardId: card.id,
            scheduledSecs: 617,
            elapsedSecs: 281,
          );

      final expected = RelearningCardState.fromCard(
        card,
        scheduledSecs: 617,
        elapsedSecs: 281,
      );
      expect(state.learning.remainingSteps, expected.learning.remainingSteps);
      expect(state.learning.remainingSteps, 2);
      expect(state.learning.scheduledSecs, 617);
      expect(state.learning.elapsedSecs, 281);
      expect(state.review.scheduledDays, 19);
      expect(state.review.elapsedDays, 19);
      expect(state.review.easeFactor, 2.375);
      expect(state.review.lapses, 5);
      expect(state.review.leeched, isFalse);
      expect(
        state.learning.memoryState!.stability,
        expected.learning.memoryState!.stability,
      );
      expect(
        state.learning.memoryState!.difficulty,
        expected.learning.memoryState!.difficulty,
      );
      expect(
        state.review.memoryState!.stability,
        expected.review.memoryState!.stability,
      );
      expect(
        state.review.memoryState!.difficulty,
        expected.review.memoryState!.difficulty,
      );
    });

    test('rejects missing card/deck and invalid card/deck kinds', () async {
      Future<RelearningCardState> project([CardId? id]) =>
          storage.currentReschedulingFilteredRelearningCardState(
            cardId: id ?? Int64(404),
            scheduledSecs: 60,
            elapsedSecs: 10,
          );

      await expectLater(project(), _stateError('card not found'));

      await _insertRelearningCard(storage);
      await storage.executeBatch('UPDATE cards SET did = 404 WHERE id = 1');
      await expectLater(project(Int64(1)), _stateError('deck not found'));

      await storage.executeBatch(
        'UPDATE cards SET did = 7, type = 2 WHERE id = 1',
      );
      await expectLater(
        project(Int64(1)),
        _stateError('not a relearning card'),
      );

      await storage.executeBatch('UPDATE cards SET type = 3 WHERE id = 1');
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck());
      await expectLater(
        project(Int64(1)),
        _stateError('filtered deck required'),
      );

      storage.decks.addOrUpdateDeckWithExistingId(
        _filteredDeck(reschedule: false),
      );
      await expectLater(project(Int64(1)), _stateError('does not reschedule'));
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

Future<void> _insertRelearningCard(CollectionSqliteStorage storage) =>
    storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES (1, 100, 7, 0, 0, 1, 3, 1, 0, 19, 2375, 8, 5, 2002, 0, 0, 0,
          '{"s":2,"d":4}');
''');

Matcher _stateError(String text) => throwsA(
  isA<StateError>().having((error) => error.message, 'message', contains(text)),
);
