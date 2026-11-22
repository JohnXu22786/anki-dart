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
        id INTEGER PRIMARY KEY, nid INTEGER, due INTEGER, mod NUMERIC,
        did INTEGER, odid INTEGER, reps INTEGER, queue INTEGER
      );
    ''');
  });

  tearDown(() async {
    await storage.close();
  });

  test(
    'filters by active deck, learning queue, and inclusive cutoff',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards VALUES
        (1, 11, 100, 10, 7, 70, 1, 1),
        (2, 12, 100, 20, 7, 70, 2, 4),
        (3, 13, 101, 30, 7, 70, 3, 1),
        (4, 14, 100, 40, 8, 80, 4, 1),
        (5, 15, 100, 50, 7, 70, 5, 2),
        (6, 16, 100, 60, 7, 70, 6, 0),
        (7, 17, NULL, 70, 7, 70, 7, 1),
        (8, 18, 10.5, 80, 7, 70, 8, 1);
    ''');

      final candidates = await storage.intradayLearningCandidates(
        activeDeckIds: [Int64(7), Int64(7)],
        learnCutoffSecs: Int64(100),
      );

      expect(candidates.map((candidate) => candidate.id), [
        Int64(1),
        Int64(2),
        Int64(8),
      ]);
      expect(candidates.last.due, 0);
    },
  );

  test(
    'projects all fields as signed 64-bit values without precision loss',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards VALUES
        (9007199254740993, 9007199254740995, 2147483647,
         -9007199254740997, 9007199254740999, -9007199254741001,
         4294967295, 4);
    ''');

      final candidate = (await storage.intradayLearningCandidates(
        activeDeckIds: [Int64.parseInt('9007199254740999')],
        learnCutoffSecs: Int64(2147483647),
      )).single;

      expect(candidate.id, Int64.parseInt('9007199254740993'));
      expect(candidate.noteId, Int64.parseInt('9007199254740995'));
      expect(candidate.due, 2147483647);
      expect(candidate.mtimeSecs, Int64.parseInt('-9007199254740997'));
      expect(candidate.currentDeckId, Int64.parseInt('9007199254740999'));
      expect(candidate.originalDeckId, Int64.parseInt('-9007199254741001'));
      expect(candidate.reps, 4294967295);
    },
  );

  test('empty active deck input returns no candidates', () async {
    final candidates = await storage.intradayLearningCandidates(
      activeDeckIds: const [],
      learnCutoffSecs: Int64(100),
    );

    expect(candidates, isEmpty);
  });

  test('large active deck sets exceed the SQLite bind limit safely', () async {
    await storage.executeBatch('''
      INSERT INTO cards VALUES (1, 11, 100, 10, 1200, 70, 1, 1);
    ''');
    final candidates = await storage.intradayLearningCandidates(
      activeDeckIds: [for (var id = 1; id <= 1200; id++) Int64(id)],
      learnCutoffSecs: Int64(100),
    );

    expect(candidates.map((candidate) => candidate.id), [Int64(1)]);
  });
}
