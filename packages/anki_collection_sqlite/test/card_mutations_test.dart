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
    ''');
  });

  tearDown(() async {
    await storage.close();
  });

  test('update and replace persist card columns and compact card data', () async {
    await storage.executeBatch("INSERT INTO cards VALUES ${_values(11)}");
    final updated = _card(
      id: 11,
      noteId: 21,
      deckId: 31,
      templateIdx: 4,
      mtimeSecs: 1712345678,
      usn: -3,
      ctype: CardType.relearn,
      queue: CardQueue.userBuried,
      due: -8,
      interval: 42,
      easeFactorRaw: 2500,
      reps: 9,
      lapses: 2,
      remainingStepsRaw: 1002,
      originalDue: 20,
      originalDeckId: 32,
      flags: 7,
      originalPosition: 99,
      memoryState: FsrsMemoryState(stability: 2.123456, difficulty: 4.56789),
      desiredRetention: 0.87654,
      decay: 0.123456,
      lastReviewTimeSecs: Int64(1712345600),
      customData: '{"k":1}',
    );

    await storage.updateCard(updated);

    final row = database.select('SELECT * FROM cards WHERE id = 11').single;
    expect(row.values, [
      11,
      21,
      31,
      4,
      1712345678,
      -3,
      3,
      -3,
      -8,
      42,
      2500,
      9,
      2,
      1002,
      20,
      32,
      7,
      '{"pos":99,"s":2.1235,"d":4.568,"dr":0.88,"decay":0.123,"lrt":1712345600,"cd":"{\\"k\\":1}"}',
    ]);

    await storage.updateCard(
      _card(
        id: 11,
        memoryState: FsrsMemoryState(stability: 2, difficulty: 4),
        desiredRetention: 1000,
        decay: 0,
      ),
    );
    expect(
      database.select('SELECT data FROM cards WHERE id = 11').single['data'],
      '{"s":2.0,"d":4.0,"dr":1000.0,"decay":0.0}',
    );

    final replacement = _card(
      id: 11,
      noteId: 22,
      deckId: 33,
      templateIdx: 5,
      mtimeSecs: 1712345679,
      usn: 4,
      due: 2,
    );
    await storage.addOrUpdateCard(replacement);
    expect(
      database
          .select(
            'SELECT nid, did, ord, mod, usn, due FROM cards WHERE id = 11',
          )
          .single
          .values,
      [22, 33, 5, 1712345679, 4, 2],
    );
  });

  test(
    'add uses the source time ID and preserves the card modification time',
    () async {
      await storage.executeBatch("INSERT INTO cards VALUES ${_values(50)}");
      final startedAt = DateTime.now().millisecondsSinceEpoch;
      final id = await storage.addCard(
        _card(id: 50, noteId: 60, templateIdx: 1),
      );
      final finishedAt = DateTime.now().millisecondsSinceEpoch;

      expect(id.toInt(), inInclusiveRange(startedAt, finishedAt + 1));
      expect(id, isNot(Int64(50)));
      final card = await storage.getCard(id);
      expect(card, isNotNull);
      expect(card!.noteId, Int64(60));
      expect(card.templateIdx, 1);
      final mod =
          database.select('SELECT mod FROM cards WHERE id = ?', [
                id.toInt(),
              ]).single['mod']
              as int;
      expect(mod, 1, reason: 'addCard leaves mod equal to the supplied value');
    },
  );

  test('add resolves a collision with the source timestamp ID', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const maxExistingId = 8000000000000000000;
    database.execute('''
      WITH RECURSIVE ids(id) AS (
        SELECT ${now - 60000}
        UNION ALL SELECT id + 1 FROM ids WHERE id < ${now + 60000}
      )
      INSERT INTO cards
      SELECT id, 12, 13, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '{}'
      FROM ids
    ''');
    database.execute('''
      INSERT INTO cards VALUES (
        $maxExistingId, 12, 13, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '{}'
      )
    ''');

    final assignedId = await storage.addCard(_card(noteId: 60));

    expect(assignedId, Int64(maxExistingId + 1));
    expect((await storage.getCard(assignedId))!.mtimeSecs, Int64(1));
  });

  test('add-if-unique reports ignored primary-key collisions', () async {
    await storage.executeBatch("INSERT INTO cards VALUES ${_values(71)}");
    final duplicate = _card(id: 71, noteId: 999, templateIdx: 8);

    expect(await storage.addCardIfUnique(duplicate), isFalse);
    expect((await storage.getCard(Int64(71)))!.noteId, Int64(12));

    expect(
      await storage.addCardIfUnique(_card(id: 72, noteId: 13, templateIdx: 1)),
      isTrue,
    );
    expect((await storage.getCard(Int64(72)))!.noteId, Int64(13));
  });

  test(
    'card writes flush in autocommit and defer inside transactions',
    () async {
      var flushes = 0;
      final persistentStorage = await CollectionSqliteStorage.open(
        driver: CollectionSqliteDriver(
          openDatabase: (_) => sqlite3.openInMemory(),
          flush: () => flushes++,
        ),
        location: ':memory:',
      );
      try {
        await persistentStorage.executeBatch('''
        CREATE TABLE cards (
          id INTEGER PRIMARY KEY, nid INTEGER NOT NULL, did INTEGER NOT NULL,
          ord INTEGER NOT NULL, mod INTEGER NOT NULL, usn INTEGER NOT NULL,
          type INTEGER NOT NULL, queue INTEGER NOT NULL, due INTEGER NOT NULL,
          ivl INTEGER NOT NULL, factor INTEGER NOT NULL, reps INTEGER NOT NULL,
          lapses INTEGER NOT NULL, left INTEGER NOT NULL, odue INTEGER NOT NULL,
          odid INTEGER NOT NULL, flags INTEGER NOT NULL, data TEXT NOT NULL
        );
      ''');
        var expectedFlushes = 2; // open and table creation
        expect(flushes, expectedFlushes);

        final addedId = await persistentStorage.addCard(_card());
        expect(flushes, ++expectedFlushes);
        expect(await persistentStorage.addCardIfUnique(_card(id: 501)), isTrue);
        expect(flushes, ++expectedFlushes);
        await persistentStorage.addOrUpdateCard(_card(id: 502));
        expect(flushes, ++expectedFlushes);
        await persistentStorage.updateCard(_card(id: 502, noteId: 20));
        expect(flushes, ++expectedFlushes);
        await persistentStorage.removeCard(addedId);
        expect(flushes, ++expectedFlushes);

        await persistentStorage.beginExclusive();
        await persistentStorage.updateCard(_card(id: 502, noteId: 21));
        await persistentStorage.removeCard(Int64(501));
        expect(flushes, expectedFlushes);
        await persistentStorage.commit();
        expect(flushes, ++expectedFlushes);
      } finally {
        await persistentStorage.close();
      }
    },
  );

  test(
    'remove is harmless for missing rows and failures respect transactions',
    () async {
      await storage.executeBatch("INSERT INTO cards VALUES ${_values(81)}");
      await storage.removeCard(Int64(404));
      await storage.removeCard(Int64(81));
      expect(await storage.getCard(Int64(81)), isNull);

      await storage.executeBatch('''
      CREATE TRIGGER reject_card_update BEFORE UPDATE ON cards
      BEGIN SELECT RAISE(ABORT, 'blocked'); END;
      INSERT INTO cards VALUES ${_values(82)};
    ''');
      await storage.beginExclusive();
      await expectLater(
        storage.updateCard(_card(id: 82, noteId: 123)),
        throwsA(isA<SqliteException>()),
      );
      await storage.rollback();
      expect((await storage.getCard(Int64(82)))!.noteId, Int64(12));
    },
  );
}

String _values(int id) =>
    '($id, 12, 13, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \'{}\')';

Card _card({
  int id = 1,
  int noteId = 2,
  int deckId = 3,
  int templateIdx = 0,
  int mtimeSecs = 1,
  int usn = 0,
  CardType ctype = CardType.newCard,
  CardQueue queue = CardQueue.newCard,
  int due = 0,
  int interval = 0,
  int easeFactorRaw = 0,
  int reps = 0,
  int lapses = 0,
  int remainingStepsRaw = 0,
  int originalDue = 0,
  int originalDeckId = 0,
  int flags = 0,
  int? originalPosition,
  FsrsMemoryState? memoryState,
  double? desiredRetention,
  double? decay,
  Int64? lastReviewTimeSecs,
  String customData = '',
}) => Card(
  id: Int64(id),
  noteId: Int64(noteId),
  deckId: Int64(deckId),
  templateIdx: templateIdx,
  mtimeSecs: Int64(mtimeSecs),
  usn: usn,
  ctype: ctype,
  queue: queue,
  due: due,
  interval: interval,
  easeFactorRaw: easeFactorRaw,
  reps: reps,
  lapses: lapses,
  remainingStepsRaw: remainingStepsRaw,
  originalDue: originalDue,
  originalDeckId: Int64(originalDeckId),
  flags: flags,
  originalPosition: originalPosition,
  memoryState: memoryState,
  desiredRetention: desiredRetention,
  decay: decay,
  lastReviewTimeSecs: lastReviewTimeSecs,
  customData: customData,
);
