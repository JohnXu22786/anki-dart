// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CollectionSqliteStorage storage;
  late Database database;

  setUp(() async {
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => database = sqlite3.openInMemory(),
      ),
      location: ':memory:',
    );
    await storage.executeBatch('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY, nid INTEGER NOT NULL, did INTEGER NOT NULL,
        ord INTEGER NOT NULL, mod INTEGER NOT NULL, usn INTEGER NOT NULL,
        type INTEGER NOT NULL, queue INTEGER NOT NULL, due INTEGER NOT NULL,
        ivl INTEGER NOT NULL, factor INTEGER NOT NULL, reps INTEGER NOT NULL,
        lapses INTEGER NOT NULL, left INTEGER NOT NULL, odue INTEGER NOT NULL,
        odid INTEGER NOT NULL, flags INTEGER NOT NULL, data TEXT NOT NULL
      );
      CREATE TABLE revlog (
        id INTEGER PRIMARY KEY, cid INTEGER NOT NULL, usn INTEGER NOT NULL,
        ease INTEGER NOT NULL, ivl INTEGER NOT NULL, lastIvl INTEGER NOT NULL,
        factor INTEGER NOT NULL, time INTEGER NOT NULL, type INTEGER NOT NULL
      );
      INSERT INTO cards VALUES (41, 12, 13, 0, 1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, '{}');
    ''');
  });

  tearDown(() async => storage.close());

  test(
    'persists one answer and undo/redo restores both supplied rows',
    () async {
      final before = await storage.getCard(Int64(41));
      final suppliedCard = _card(id: 41, due: 27);
      final entry = _revlog(id: 1712345678000, cardId: 41);

      await storage.recordCardAnswerResult(card: suppliedCard, revlog: entry);

      expect((await storage.getCard(Int64(41)))!.due, 27);
      expect(storage.revlog.getRevlogEntry(entry.id)!.cardId, Int64(41));
      expect(storage.collectionUndoLabel, 'answerCard');
      expect(
        storage.collectionUndoChanges.map((change) => change.kind),
        containsAll([
          CollectionUndoChangeKind.card,
          CollectionUndoChangeKind.revlog,
        ]),
      );

      await storage.undoLastCollectionOperation();
      expect((await storage.getCard(Int64(41)))!.due, before!.due);
      expect(storage.revlog.getRevlogEntry(entry.id), isNull);

      await storage.redoLastCollectionOperation();
      expect((await storage.getCard(Int64(41)))!.due, 27);
      expect(storage.revlog.getRevlogEntry(entry.id)!.cardId, Int64(41));
    },
  );

  test(
    'unchanged card values still persist a distinct answer revlog',
    () async {
      final before = await storage.getCard(Int64(41));
      final entry = _revlog(id: 1712345678001, cardId: 41);

      await storage.recordCardAnswerResult(card: before!, revlog: entry);

      expect((await storage.getCard(Int64(41)))!.due, before.due);
      expect(storage.revlog.getRevlogEntry(entry.id)!.cardId, Int64(41));
      expect(storage.collectionUndoLabel, 'answerCard');
      await storage.undoLastCollectionOperation();
      expect(storage.revlog.getRevlogEntry(entry.id), isNull);
      expect((await storage.getCard(Int64(41)))!.due, before.due);
    },
  );

  test('mismatched and missing card IDs fail without mutation', () async {
    final generation = storage.collectionUndoGeneration;
    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27),
        revlog: _revlog(id: 1712345678002, cardId: 42),
      ),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 99, due: 27),
        revlog: _revlog(id: 1712345678003, cardId: 99),
      ),
      throwsA(isA<StateError>()),
    );

    expect((await storage.getCard(Int64(41)))!.due, 4);
    expect(await storage.getCard(Int64(99)), isNull);
    expect(database.select('SELECT id FROM revlog'), isEmpty);
    expect(storage.collectionUndoGeneration, generation);
  });

  test('revlog collision rolls back the supplied card update', () async {
    final existing = _revlog(id: 1712345678004, cardId: 41);
    storage.revlog.addRevlogEntry(existing);
    final generation = storage.collectionUndoGeneration;

    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27),
        revlog: existing,
      ),
      throwsA(isA<StateError>()),
    );

    expect((await storage.getCard(Int64(41)))!.due, 4);
    expect(storage.revlog.getRevlogEntry(existing.id)!.cardId, Int64(41));
    expect(database.select('SELECT id FROM revlog'), hasLength(1));
    expect(storage.collectionUndoGeneration, generation);
  });

  test('card update failure rolls back before inserting the revlog', () async {
    await storage.executeBatch('''
      CREATE TRIGGER reject_answer_card BEFORE UPDATE ON cards
      BEGIN SELECT RAISE(ABORT, 'blocked'); END;
    ''');
    final entry = _revlog(id: 1712345678005, cardId: 41);
    final generation = storage.collectionUndoGeneration;

    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27),
        revlog: entry,
      ),
      throwsA(isA<SqliteException>()),
    );

    expect((await storage.getCard(Int64(41)))!.due, 4);
    expect(storage.revlog.getRevlogEntry(entry.id), isNull);
    expect(storage.collectionUndoGeneration, generation);
  });

  test(
    'a suppressed card update rolls back instead of writing only revlog',
    () async {
      await storage.executeBatch('''
      CREATE TRIGGER ignore_answer_card BEFORE UPDATE ON cards
      BEGIN SELECT RAISE(IGNORE); END;
    ''');
      final entry = _revlog(id: 1712345678006, cardId: 41);
      final generation = storage.collectionUndoGeneration;

      await expectLater(
        storage.recordCardAnswerResult(
          card: _card(id: 41, due: 27),
          revlog: entry,
        ),
        throwsA(isA<StateError>()),
      );

      expect((await storage.getCard(Int64(41)))!.due, 4);
      expect(storage.revlog.getRevlogEntry(entry.id), isNull);
      expect(storage.collectionUndoGeneration, generation);
    },
  );
}

Card _card({required int id, required int due}) => Card(
  id: Int64(id),
  noteId: Int64(12),
  deckId: Int64(13),
  mtimeSecs: Int64(1),
  due: due,
);

RevlogEntry _revlog({required int id, required int cardId}) => RevlogEntry(
  id: RevlogId(Int64(id)),
  cardId: Int64(cardId),
  usn: -1,
  buttonChosen: 3,
  interval: 8,
  lastInterval: 4,
  easeFactor: 2500,
  takenMillis: 1200,
  reviewKind: RevlogReviewKind.review,
);
