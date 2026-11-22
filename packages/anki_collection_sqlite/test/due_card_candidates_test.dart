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
        id INTEGER PRIMARY KEY, nid INTEGER, due INTEGER, ivl NUMERIC,
        mod NUMERIC, did INTEGER, odid INTEGER, reps INTEGER, queue INTEGER,
        factor INTEGER, ord INTEGER, data TEXT, odue INTEGER DEFAULT 0
      );
    ''');
  });

  tearDown(() async {
    await storage.close();
  });

  test('filters queue, active decks and inclusive due-day cutoff', () async {
    await storage.executeBatch('''
      INSERT INTO cards (id, nid, due, ivl, mod, did, odid, reps, queue, factor, ord, data) VALUES
        (1, 11, 5, 2, 101, 7, 70, 1, 2, 2500, 0, '{}'),
        (2, 12, 6, 2, 102, 7, 70, 1, 2, 2500, 0, '{}'),
        (3, 13, 5, 2, 103, 8, 80, 1, 2, 2500, 0, '{}'),
        (4, 14, 5, 2, 104, 7, 70, 1, 3, 2500, 0, '{}'),
        (5, 15, 5, 2, 105, 7, 70, 1, 1, 2500, 0, '{}');
    ''');

    final reviews = await storage.dueCardCandidates(
      activeDeckIds: [Int64(7)],
      kind: DueCardKind.review,
      reviewOrder: ReviewCardOrder.day,
      fsrsEnabled: false,
      daysElapsed: 5,
      now: Int64(1700000000),
      nextDayAt: Int64(1700040000),
    );
    final learning = await storage.dueCardCandidates(
      activeDeckIds: [Int64(7)],
      kind: DueCardKind.interdayLearning,
      reviewOrder: ReviewCardOrder.day,
      fsrsEnabled: false,
      daysElapsed: 5,
      now: Int64(1700000000),
      nextDayAt: Int64(1700040000),
    );

    expect(reviews.map((card) => card.id), [Int64(1)]);
    expect(learning.map((card) => card.id), [Int64(4)]);
  });

  test(
    'projects exact int64 values and applies Core due and reps conversions',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards (id, nid, due, ivl, mod, did, odid, reps, queue, factor, ord, data) VALUES
        (9007199254740993, 9007199254740995, 2147483647, 123.9,
         -9007199254740997, 9007199254740999, -9007199254741001,
         4294967295, 2, 2500, 0, '{}'),
        (9007199254740994, 9007199254740996, 2147483648, 2147483648.9,
         99, 9007199254740999, 0, 1, 2, 2500, 0, '{}');
    ''');

      final candidates = await storage.dueCardCandidates(
        activeDeckIds: [Int64.parseInt('9007199254740999')],
        kind: DueCardKind.review,
        reviewOrder: ReviewCardOrder.day,
        fsrsEnabled: false,
        daysElapsed: 0xffffffff,
        now: Int64.parseInt('9007199254740999'),
        nextDayAt: Int64.parseInt('9007199254741001'),
      );

      expect(candidates, hasLength(2));
      expect(candidates.first.id, Int64.parseInt('9007199254740993'));
      expect(candidates.first.noteId, Int64.parseInt('9007199254740995'));
      expect(candidates.first.due, 2147483647);
      expect(candidates.first.interval, Int64(123));
      expect(candidates.first.mtimeSecs, Int64.parseInt('-9007199254740997'));
      expect(
        candidates.first.currentDeckId,
        Int64.parseInt('9007199254740999'),
      );
      expect(
        candidates.first.originalDeckId,
        Int64.parseInt('-9007199254741001'),
      );
      expect(candidates.first.reps, 4294967295);
      expect(candidates.last.due, 0);
      expect(candidates.last.interval, Int64.parseInt('2147483648'));
      expect(candidates.last.reps, 1);
    },
  );

  test(
    'returns empty for empty decks and deduplicates deck rank input',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards (id, nid, due, ivl, mod, did, odid, reps, queue, factor, ord, data) VALUES
        (1, 1, 1, 1, 1, 8, 80, 1, 2, 2500, 0, '{}'),
        (2, 2, 1, 1, 2, 7, 70, 1, 2, 2500, 0, '{}');
    ''');

      final empty = await storage.dueCardCandidates(
        activeDeckIds: const [],
        kind: DueCardKind.review,
        reviewOrder: ReviewCardOrder.day,
        fsrsEnabled: false,
        daysElapsed: 1,
        now: Int64(10),
        nextDayAt: Int64(20),
      );
      final duplicates = await storage.dueCardCandidates(
        activeDeckIds: [Int64(7), Int64(8), Int64(7)],
        kind: DueCardKind.review,
        reviewOrder: ReviewCardOrder.deckThenDay,
        fsrsEnabled: false,
        daysElapsed: 1,
        now: Int64(10),
        nextDayAt: Int64(20),
      );

      expect(empty, isEmpty);
      expect(duplicates.map((card) => card.id), [Int64(2), Int64(1)]);
    },
  );

  test('rejects reps outside Core uint32 range', () async {
    await storage.executeBatch('''
      INSERT INTO cards (id, nid, due, ivl, mod, did, odid, reps, queue, factor, ord, data) VALUES
        (1, 1, 0, 1, 1, 7, 0, 4294967296, 2, 2500, 0, '{}');
    ''');

    await expectLater(
      storage.dueCardCandidates(
        activeDeckIds: [Int64(7)],
        kind: DueCardKind.review,
        reviewOrder: ReviewCardOrder.day,
        fsrsEnabled: false,
        daysElapsed: 0,
        now: Int64(1),
        nextDayAt: Int64(2),
      ),
      throwsFormatException,
    );
  });

  test(
    'orders with every Core review order and preserves active-deck order',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards (id, nid, due, ivl, mod, did, odid, reps, queue, factor, ord, data) VALUES
        (11, 110, 2, 8, 11, 7, 70, 1, 2, 2500, 1, '{}'),
        (12, 120, 1, 4, 12, 8, 80, 1, 2, 2200, 0, '{}'),
        (13, 120, 1, 4, 13, 7, 70, 1, 2, 2800, 0, '{}'),
        (14, 100, 3, 12, 14, 8, 80, 1, 2, 2500, 0, '{}');
    ''');
      const orders = ReviewCardOrder.values;
      const expectedByOrder = <ReviewCardOrder, List<int>>{
        ReviewCardOrder.day: [13, 12, 11, 14],
        ReviewCardOrder.dayThenDeck: [12, 13, 11, 14],
        ReviewCardOrder.deckThenDay: [12, 14, 13, 11],
        ReviewCardOrder.intervalsAscending: [13, 12, 11, 14],
        ReviewCardOrder.intervalsDescending: [14, 11, 13, 12],
        ReviewCardOrder.easeAscending: [12, 14, 11, 13],
        ReviewCardOrder.easeDescending: [13, 14, 11, 12],
        ReviewCardOrder.retrievabilityAscending: [14, 13, 11, 12],
        ReviewCardOrder.random: [14, 13, 11, 12],
        ReviewCardOrder.added: [14, 11, 13, 12],
        ReviewCardOrder.reverseAdded: [13, 12, 11, 14],
        ReviewCardOrder.retrievabilityDescending: [14, 13, 11, 12],
        ReviewCardOrder.relativeOverdueness: [13, 12, 11, 14],
      };
      for (final order in orders) {
        final candidates = await storage.dueCardCandidates(
          activeDeckIds: [Int64(8), Int64(7)],
          kind: DueCardKind.review,
          reviewOrder: order,
          fsrsEnabled: false,
          daysElapsed: 3,
          now: Int64(1700000000),
          nextDayAt: Int64(1700040000),
        );
        expect(candidates, hasLength(4), reason: order.name);
        expect(
          candidates.map((card) => card.id.toInt()),
          expectedByOrder[order],
          reason: order.name,
        );
      }
      final deckFirst = await storage.dueCardCandidates(
        activeDeckIds: [Int64(8), Int64(7)],
        kind: DueCardKind.review,
        reviewOrder: ReviewCardOrder.deckThenDay,
        fsrsEnabled: false,
        daysElapsed: 3,
        now: Int64(1700000000),
        nextDayAt: Int64(1700040000),
      );
      expect(deckFirst.map((card) => card.id), [
        Int64(12),
        Int64(14),
        Int64(13),
        Int64(11),
      ]);
    },
  );

  test(
    'FSRS ease, retrievability and relative order use explicit timing',
    () async {
      await storage.executeBatch('''
      INSERT INTO cards (id, nid, due, ivl, mod, did, odid, reps, queue, factor, ord, data) VALUES
        (1, 11, 8, 4, 101, 7, 70, 1, 2, 1500, 0,
         '{"s":1.0,"d":2.0,"r":0.9,"lrt":1699990000}'),
        (2, 12, 10, 4, 102, 7, 70, 1, 2, 2500, 0,
         '{"s":30.0,"d":8.0,"r":0.9,"lrt":1699000000}'),
        (3, 13, 12, 4, 103, 7, 70, 1, 2, 3000, 0,
         '{"s":10.0,"d":5.0,"r":0.9,"lrt":1690000000}');
    ''');

      for (final order in [
        ReviewCardOrder.easeAscending,
        ReviewCardOrder.easeDescending,
        ReviewCardOrder.retrievabilityAscending,
        ReviewCardOrder.retrievabilityDescending,
        ReviewCardOrder.relativeOverdueness,
      ]) {
        final fsrs = await storage.dueCardCandidates(
          activeDeckIds: [Int64(7)],
          kind: DueCardKind.review,
          reviewOrder: order,
          fsrsEnabled: true,
          daysElapsed: 20,
          now: Int64(1700000000),
          nextDayAt: Int64(1700040000),
        );
        final expected = switch (order) {
          ReviewCardOrder.easeAscending => [Int64(2), Int64(3), Int64(1)],
          ReviewCardOrder.easeDescending => [Int64(1), Int64(3), Int64(2)],
          ReviewCardOrder.retrievabilityAscending => [
            Int64(3),
            Int64(2),
            Int64(1),
          ],
          ReviewCardOrder.retrievabilityDescending => [
            Int64(1),
            Int64(2),
            Int64(3),
          ],
          ReviewCardOrder.relativeOverdueness => [Int64(1), Int64(2), Int64(3)],
          _ => throw StateError('unexpected FSRS order'),
        };
        expect(fsrs.map((card) => card.id), expected, reason: order.name);
      }

      final fsrsEaseAscending = await storage.dueCardCandidates(
        activeDeckIds: [Int64(7)],
        kind: DueCardKind.review,
        reviewOrder: ReviewCardOrder.easeAscending,
        fsrsEnabled: true,
        daysElapsed: 20,
        now: Int64(1700000000),
        nextDayAt: Int64(1700040000),
      );
      final sm2EaseAscending = await storage.dueCardCandidates(
        activeDeckIds: [Int64(7)],
        kind: DueCardKind.review,
        reviewOrder: ReviewCardOrder.easeAscending,
        fsrsEnabled: false,
        daysElapsed: 20,
        now: Int64(1700000000),
        nextDayAt: Int64(1700040000),
      );
      expect(fsrsEaseAscending.map((card) => card.id), [
        Int64(2),
        Int64(3),
        Int64(1),
      ]);
      expect(sm2EaseAscending.map((card) => card.id), [
        Int64(1),
        Int64(2),
        Int64(3),
      ]);
      final sm2RelativeOverdueness = await storage.dueCardCandidates(
        activeDeckIds: [Int64(7)],
        kind: DueCardKind.review,
        reviewOrder: ReviewCardOrder.relativeOverdueness,
        fsrsEnabled: false,
        daysElapsed: 20,
        now: Int64(1700000000),
        nextDayAt: Int64(1700040000),
      );
      expect(sm2RelativeOverdueness.map((card) => card.id), [
        Int64(1),
        Int64(2),
        Int64(3),
      ]);
    },
  );

  test('large active deck lists avoid SQLite variable limits', () async {
    await storage.executeBatch('''
      INSERT INTO cards (id, nid, due, ivl, mod, did, odid, reps, queue, factor, ord, data) VALUES (1, 1, 0, 1, 1, 1200, 0, 1, 2, 2500, 0, '{}');
    ''');
    final candidates = await storage.dueCardCandidates(
      activeDeckIds: [for (var id = 1; id <= 1200; id++) Int64(id)],
      kind: DueCardKind.review,
      reviewOrder: ReviewCardOrder.day,
      fsrsEnabled: false,
      daysElapsed: 0,
      now: Int64(1),
      nextDayAt: Int64(2),
    );
    expect(candidates.map((card) => card.id), [Int64(1)]);
  });
}
