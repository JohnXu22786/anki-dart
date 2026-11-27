// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

const _nextDayAt = 300000;

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
CREATE TABLE revlog (
  id INTEGER PRIMARY KEY, cid INTEGER, usn INTEGER, ease INTEGER, ivl INTEGER,
  lastIvl INTEGER, factor INTEGER, time INTEGER, type INTEGER
);
''');
  });

  tearDown(() async => storage.close());

  test('returns an empty result when the collection has no revlog history', () {
    final result = storage.fsrsTrainingItems(
      nextDayAt: Int64(_nextDayAt),
      ignoreRevlogsBefore: Int64.ZERO,
    );

    expect(result.items, isEmpty);
    expect(result.reviewCount, 0);
  });

  test(
    'groups cards and preserves globally ordered items and review counts',
    () {
      for (final entry in [
        _entry(100000, cardId: -2, rating: 4, kind: RevlogReviewKind.learning),
        _entry(110000, cardId: 2, rating: 1, kind: RevlogReviewKind.learning),
        _entry(150000, cardId: 2, rating: 3),
        _entry(190000, cardId: -2, rating: 2),
        _entry(220000, cardId: 2, rating: 4),
        _entry(260000, cardId: -2, rating: 1),
        _entry(120000, cardId: 3, rating: 3),
        _entry(180000, cardId: 3, rating: 2),
      ]) {
        storage.revlog.addRevlogEntry(entry);
      }

      final result = storage.fsrsTrainingItems(
        nextDayAt: Int64(_nextDayAt),
        ignoreRevlogsBefore: Int64.ZERO,
      );

      expect(result.reviewCount, 6);
      expect(result.items, hasLength(4));
      expect(result.items.map((item) => item.reviews.last.rating), [
        3,
        2,
        4,
        1,
      ]);
      expect(result.items.map((item) => item.reviews.length), [2, 2, 3, 3]);
    },
  );
}

RevlogEntry _entry(
  int secs, {
  required int cardId,
  int rating = 3,
  RevlogReviewKind kind = RevlogReviewKind.review,
}) => RevlogEntry(
  id: RevlogId(Int64(secs * 1000)),
  cardId: Int64(cardId),
  buttonChosen: rating,
  interval: 1,
  reviewKind: kind,
);
