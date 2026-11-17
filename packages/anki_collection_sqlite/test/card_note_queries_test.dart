// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
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
        id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER,
        mod INTEGER, usn INTEGER, type INTEGER, queue INTEGER, due INTEGER,
        ivl REAL, factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER,
        odue INTEGER, odid INTEGER, flags INTEGER, data TEXT
      );
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY, guid TEXT, mid INTEGER, mod INTEGER,
        usn INTEGER, tags TEXT, flds TEXT, sfld TEXT, csum INTEGER
      );
      CREATE TABLE notetypes (
        id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER,
        config BLOB
      );
      CREATE TABLE fields (
        ntid INTEGER, ord INTEGER, name TEXT, config BLOB,
        PRIMARY KEY (ntid, ord)
      );
      CREATE TABLE templates (
        ntid INTEGER, ord INTEGER, name TEXT, mtime_secs INTEGER, usn INTEGER,
        config BLOB, PRIMARY KEY (ntid, ord)
      );
    ''');
  });

  tearDown(() async {
    await storage.close();
  });

  test(
    'card readers map every stored field and tolerate nullable due values',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards VALUES (
        50000000001, 60000000002, 70000000003, 4, 1712345678, -1,
        3, -3, NULL, 2.75, 2500, 8, 2, 1002, NULL, 70000000004, 9,
        '{"pos":4294967295,"s":12.3456789,"d":4.44444,"dr":0.899,"decay":1.23456,"lrt":1234567890,"cd":"{\\"k\\":1}"}'
      );
      INSERT INTO cards VALUES (
        50000000005, 60000000002, 70000000003, 1, 1, 0,
        0, 0, 10, 3.5, 2500, 0, 0, 0, 11, 0, 0, 'not json'
      );
      INSERT INTO cards VALUES (
        50000000006, 60000000002, 70000000003, 2, 1, 0,
        0, 0, 2147483648, 0, 0, 0, 0, 0, -2147483649, 0, 0, '{}'
      );
      INSERT INTO cards VALUES (
        50000000007, 60000000002, 70000000003, 3, 1, 0,
        0, 0, 1.5, 0, 0, 0, 0, 0, 2.5, 0, 0, '{}'
      );
      INSERT INTO cards VALUES (
        50000000008, 60000000002, 70000000003, 4, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        '{"lrt":9223372036854775808}'
      );
      INSERT INTO cards VALUES (
        50000000009, 60000000002, 70000000003, 5, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        '{"s":1e100,"d":-1e100,"dr":1e100,"decay":-1e100}'
      );
      INSERT INTO cards VALUES (
        50000000010, 60000000002, 70000000003, 6, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        '{"s":12,"d":2,"dr":0.8,"decay":0.2,"cd":3}'
      );
    ''');

      final card = await storage.getCard(Int64(50000000001));
      expect(card, isNotNull);
      expect(card!.id, Int64(50000000001));
      expect(card.noteId, Int64(60000000002));
      expect(card.deckId, Int64(70000000003));
      expect(card.templateIdx, 4);
      expect(card.mtimeSecs, Int64(1712345678));
      expect(card.usn, -1);
      expect(card.ctype, CardType.relearn);
      expect(card.queue, CardQueue.userBuried);
      expect(card.due, 0, reason: 'Anki defaults an unreadable due to zero');
      expect(card.interval, 2, reason: 'ivl is cast to an integer');
      expect(card.easeFactorRaw, 2500);
      expect(card.reps, 8);
      expect(card.lapses, 2);
      expect(card.remainingStepsRaw, 1002);
      expect(card.originalDue, 0);
      expect(card.originalDeckId, Int64(70000000004));
      expect(card.flags, 9);
      expect(card.originalPosition, 4294967295);
      expect(card.memoryState!.stability, closeTo(12.345678, 0.00001));
      expect(card.memoryState!.difficulty, closeTo(4.44444, 0.00001));
      expect(card.desiredRetention, closeTo(0.899, 0.00001));
      expect(card.decay, closeTo(1.23456, 0.00001));
      expect(card.lastReviewTimeSecs, Int64(1234567890));
      expect(card.customData, '{"k":1}');

      final malformedDataCard = (await storage.allCardsOfNote(
        Int64(60000000002),
      )).singleWhere((value) => value.id == Int64(50000000005));
      expect(malformedDataCard.originalPosition, isNull);
      expect(malformedDataCard.memoryState, isNull);
      expect(malformedDataCard.desiredRetention, isNull);
      expect(malformedDataCard.decay, isNull);
      expect(malformedDataCard.lastReviewTimeSecs, isNull);
      expect(malformedDataCard.customData, '');

      final cards = await storage.allCardsOfNote(Int64(60000000002));
      final outOfRangeDue = cards.singleWhere(
        (value) => value.id == Int64(50000000006),
      );
      expect(outOfRangeDue.due, 0);
      expect(outOfRangeDue.originalDue, 0);
      final nonIntegerDue = cards.singleWhere(
        (value) => value.id == Int64(50000000007),
      );
      expect(nonIntegerDue.due, 0);
      expect(nonIntegerDue.originalDue, 0);
      final outOfRangeTimestamp = cards.singleWhere(
        (value) => value.id == Int64(50000000008),
      );
      expect(outOfRangeTimestamp.lastReviewTimeSecs, isNull);
      final outOfRangeFloats = cards.singleWhere(
        (value) => value.id == Int64(50000000009),
      );
      expect(outOfRangeFloats.memoryState, isNull);
      expect(outOfRangeFloats.desiredRetention, isNull);
      expect(outOfRangeFloats.decay, isNull);
      final invalidCustomData = cards.singleWhere(
        (value) => value.id == Int64(50000000010),
      );
      expect(invalidCustomData.memoryState, isNull);
      expect(invalidCustomData.desiredRetention, isNull);
      expect(invalidCustomData.decay, isNull);
      expect(invalidCustomData.customData, '');
    },
  );

  test(
    'card readers preserve missing-row behavior and template order',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards VALUES
        (42, 9, 1, 8, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '{}'),
        (43, 9, 1, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '{}'),
        (44, 9, 1, 5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '{}');
    ''');

      expect(await storage.getCard(Int64(404)), isNull);
      expect(await storage.allCardsOfNote(Int64(404)), isEmpty);
      expect(await storage.allCardIdsOfNoteInTemplateOrder(Int64(9)), [
        Int64(43),
        Int64(44),
        Int64(42),
      ]);
      expect(
        await storage.allCardIdsOfNoteInTemplateOrder(Int64(404)),
        isEmpty,
      );
    },
  );

  test(
    'card and note readers preserve IDs above JavaScript safe integers',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards VALUES (
        9007199254740993, 9007199254740995, 9007199254740997, 0, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 9007199254740999, 0, '{}'
      );
      INSERT INTO notes VALUES (
        9007199254741001, 'wide-id', 9007199254741003, 1, 0,
        '', '', 'sort', 1
      );
    ''');

      final cardId = Int64.parseInt('9007199254740993');
      final card = await storage.getCard(cardId);
      expect(card!.id, cardId);
      expect(card.noteId, Int64.parseInt('9007199254740995'));
      expect(card.deckId, Int64.parseInt('9007199254740997'));
      expect(card.originalDeckId, Int64.parseInt('9007199254740999'));
      expect(await storage.allCardIdsOfNoteInTemplateOrder(card.noteId), [
        cardId,
      ]);

      final noteId = Int64.parseInt('9007199254741001');
      final note = await storage.getNote(noteId);
      expect(note!.id, noteId);
      expect(note.notetypeId, Int64.parseInt('9007199254741003'));
      expect(await storage.getAllNoteIds(), contains(noteId));
    },
  );

  test(
    'bulk card and note readers preserve requested order and duplicates',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards VALUES
        (101, 201, 1, 0, 1, 0, 0, 0, 0, 0, 2500, 0, 0, 0, 0, 0, 0, '{}'),
        (102, 202, 1, 0, 1, 0, 0, 0, 0, 0, 2500, 0, 0, 0, 0, 0, 0, '{}'),
        (103, 201, 2, 1, 1, 0, 0, 0, 0, 0, 2500, 0, 0, 0, 0, 0, 0, '{}');
      INSERT INTO notes VALUES
        (201, 'guid-201', 1, 1, 0, ' alpha ', 'front\u001fback', 'front', 0),
        (202, 'guid-202', 1, 1, 0, ' beta ', 'other', 'other', 0);
    ''');

      final cards = await storage.getCardsByIds([
        Int64(102),
        Int64(999),
        Int64(101),
        Int64(102),
      ]);
      expect(cards.map((card) => card.id.toInt()), [102, 101, 102]);

      final notes = await storage.getNotesByIds([
        Int64(202),
        Int64(999),
        Int64(201),
        Int64(202),
      ]);
      expect(notes.map((note) => note.id.toInt()), [202, 201, 202]);
      expect(notes.map((note) => note.tags), [
        ['beta'],
        ['alpha'],
        ['beta'],
      ]);

      final cardsByNote = await storage.cardsOfNotes([
        Int64(202),
        Int64(201),
        Int64(999),
        Int64(202),
      ]);
      expect(cardsByNote.keys, [Int64(202), Int64(201), Int64(999)]);
      expect(cardsByNote[Int64(202)]!.map((card) => card.id), [Int64(102)]);
      expect(cardsByNote[Int64(201)]!.map((card) => card.id), [
        Int64(101),
        Int64(103),
      ]);
      expect(cardsByNote[Int64(999)], isEmpty);
    },
  );

  test(
    'row conversion rejects invalid stored widths and defaults checksum',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards VALUES
        (61, 9, 1, 65536, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '{}'),
        (62, 9, 1, 0, 1, 2147483648, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '{}'),
        (63, 9, 1, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, '{}'),
        (64, 9, 1, 0, 1, 0, 0, 0, 0, 0, 65536, 0, 0, 0, 0, 0, 0, '{}'),
        (65, 9, 1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, '{}'),
        (66, 9, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 4294967296, 0, 0, 0, 0, '{}'),
        (67, 9, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, '{}'),
        (68, 9, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 256, '{}');
      INSERT INTO notes VALUES
        (69, 'bad-usn', 1, 1, 2147483648, '', '', 'sort', 0),
        (70, 'bad-checksum', 1, 1, 0, '', '', 'sort', 4294967296);
    ''');

      for (final cardId in [61, 62, 63, 64, 65, 66, 67, 68]) {
        await expectLater(
          storage.getCard(Int64(cardId)),
          throwsA(isA<FormatException>()),
        );
      }
      await expectLater(
        storage.getNote(Int64(69)),
        throwsA(isA<FormatException>()),
      );
      expect((await storage.getNote(Int64(70)))!.checksum, 0);
    },
  );

  test(
    'notetype batch lookup preserves 64-bit IDs and requested order',
    () async {
      const id = 9007199254740995;
      await storage.executeBatch('''
      INSERT INTO notetypes VALUES (
        $id, 'Cloze fixture', 123, -1,
        X'${proto.Notetype_Config(sortFieldIdx: 1).writeToBuffer().map((b) => b.toRadixString(16).padLeft(2, '0')).join()}'
      );
      INSERT INTO fields VALUES ($id, 0, 'Front', X'');
      INSERT INTO fields VALUES ($id, 1, 'Back', X'');
      INSERT INTO templates VALUES ($id, 0, 'Card 1', 0, -1, X'');
      INSERT INTO templates VALUES ($id, 1, 'Card 2', 0, -1, X'');
    ''');

      final result = await storage.getNotetypesByIds([
        NotetypeId(Int64(id)),
        NotetypeId(Int64(42)),
        NotetypeId(Int64(id)),
      ]);

      expect(result.map((value) => value.id.value), [Int64(id), Int64(id)]);
      expect(result.first.name, 'Cloze fixture');
      expect(result.first.config.sortFieldIdx, 1);
      expect(result.first.fields.map((field) => field.name), ['Front', 'Back']);
      expect(result.first.templates.map((template) => template.name), [
        'Card 1',
        'Card 2',
      ]);
      await storage.executeBatch(
        "UPDATE notetypes SET name = 'Reloaded' WHERE id = $id",
      );
      expect(
        (await storage.getNotetypesByIds([NotetypeId(Int64(id))])).single.name,
        'Reloaded',
      );
      await storage.executeBatch('''
        INSERT INTO notetypes VALUES (77, 'Malformed', 0, 0, X'0F');
      ''');
      await expectLater(
        storage.getNotetypesByIds([NotetypeId(Int64(77))]),
        throwsA(isA<Object>()),
      );
    },
  );

  test(
    'note readers split source fields and tags, and omit fields on request',
    () async {
      await storage.executeBatch('''
      INSERT INTO notes VALUES
        (80000000001, 'guid-1', 90000000002, 1712345678, -2,
         ' alpha　beta  gamma ', 'front\u001fback\u001f', 'sort', 4294967295),
        (80000000003, 'guid-2', 90000000004, 2, 0,
         '', 'hidden\u001ffields', 'sort-2', NULL),
        (80000000005, 'guid-3', 90000000006, 3, 0,
         '', '', 'sort-3', 4294967296);
    ''');

      final note = await storage.getNote(Int64(80000000001));
      expect(note, isNotNull);
      expect(note!.id, Int64(80000000001));
      expect(note.guid, 'guid-1');
      expect(note.notetypeId, Int64(90000000002));
      expect(note.mtimeSecs, Int64(1712345678));
      expect(note.usn, -2);
      expect(note.tags, ['alpha', 'beta', 'gamma']);
      expect(note.fields, ['front', 'back', '']);
      expect(note.sortField, 'sort');
      expect(note.checksum, 4294967295);

      final withoutFields = await storage.getNoteWithoutFields(
        Int64(80000000001),
      );
      expect(withoutFields, isNotNull);
      expect(withoutFields!.fields, ['']);
      expect(withoutFields.sortField, 'sort');

      final nullChecksum = await storage.getNote(Int64(80000000003));
      expect(nullChecksum!.checksum, 0);
      expect((await storage.getNote(Int64(80000000005)))!.checksum, 0);
      expect(await storage.getNote(Int64(123)), isNull);
      expect(await storage.getNoteWithoutFields(Int64(123)), isNull);
      expect(await storage.getAllNoteIds(), {
        Int64(80000000001),
        Int64(80000000003),
        Int64(80000000005),
      });
    },
  );
}
