// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

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
        id INTEGER PRIMARY KEY, nid INTEGER, due INTEGER, did INTEGER,
        queue INTEGER
      );
    ''');
  });

  tearDown(() async {
    await storage.close();
  });

  test(
    'groups the half-open due range across all queues in natural order',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards (id, nid, due, did, queue) VALUES
        (9, 90, 10, 900, 0),
        (3, 30, 12, 300, 1),
        (8, 80, 10, 800, 2),
        (2, 20, 12, 200, 3),
        (7, 70, 10, 700, 4),
        (1, 10, 12, 100, -1),
        (6, 60, 10, 600, -2),
        (4, 40, 12, 400, -3),
        (5, 50, 9, 500, 2),
        (10, 100, 13, 1000, 2);
    ''');

      final buckets = await storage.getAllCardsDueInRange(
        minDay: 10,
        maxDay: 13,
      );

      expect(buckets, hasLength(3));
      expect(buckets[0].map((card) => card.id), [
        Int64(6),
        Int64(7),
        Int64(8),
        Int64(9),
      ]);
      expect(buckets[1], isEmpty);
      expect(buckets[2].map((card) => card.id), [
        Int64(1),
        Int64(2),
        Int64(3),
        Int64(4),
      ]);
      expect(buckets[0].map((card) => card.dueDay), [10, 10, 10, 10]);
      expect(buckets[2].map((card) => card.dueDay), [12, 12, 12, 12]);
    },
  );

  test(
    'preserves signed int64 identifiers and rejects invalid ranges',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards (id, nid, due, did, queue) VALUES
        (9007199254740993, -9007199254740995, 2147483646,
         9007199254740999, 2);
    ''');

      final buckets = await storage.getAllCardsDueInRange(
        minDay: 2147483646,
        maxDay: 2147483647,
      );
      final card = buckets.single.single;
      expect(card.id, Int64.parseInt('9007199254740993'));
      expect(card.noteId, Int64.parseInt('-9007199254740995'));
      expect(card.deckId, Int64.parseInt('9007199254740999'));
      expect(card.dueDay, 2147483646);

      await expectLater(
        storage.getAllCardsDueInRange(minDay: 4, maxDay: 4),
        throwsArgumentError,
      );
      await expectLater(
        storage.getAllCardsDueInRange(minDay: 5, maxDay: 4),
        throwsArgumentError,
      );
      await expectLater(
        storage.getAllCardsDueInRange(minDay: -0x80000001, maxDay: 1),
        throwsRangeError,
      );
      await expectLater(
        storage.getAllCardsDueInRange(minDay: -0x80000000, maxDay: 0x7fffffff),
        throwsRangeError,
      );
    },
  );
}
