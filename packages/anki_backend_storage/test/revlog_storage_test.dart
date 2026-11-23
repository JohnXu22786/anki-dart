// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:ffi';
import 'dart:io';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_storage/anki_backend_storage.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/open.dart' as sqliteOpen;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  if (Platform.isLinux) {
    sqliteOpen.open.overrideFor(
      sqliteOpen.OperatingSystem.linux,
      () => DynamicLibrary.open('libsqlite3.so.0'),
    );
  }

  late Database sqlite;
  late RevlogStorage storage;

  setUp(() {
    sqlite = sqlite3.openInMemory();
    sqlite.execute('''
CREATE TABLE revlog (
  id INTEGER PRIMARY KEY,
  cid INTEGER NOT NULL,
  usn INTEGER NOT NULL,
  ease INTEGER NOT NULL,
  ivl INTEGER NOT NULL,
  lastIvl INTEGER NOT NULL,
  factor INTEGER NOT NULL,
  time INTEGER,
  type INTEGER
)
''');
    sqlite.execute('CREATE TABLE search_cids (cid INTEGER PRIMARY KEY)');
    storage = RevlogStorage(_SqliteAdapter(sqlite));
  });

  tearDown(() => sqlite.dispose());

  test('add-if-unique returns the row ID and optionally allocates collisions',
      () {
    final id = Int64.parseInt('9007199254740993');
    final entry = _entry(id: id, cardId: 7);
    expect(storage.addRevlogEntry(entry), RevlogId(id));
    expect(storage.addRevlogEntry(entry), isNull);

    final allocated = storage.addRevlogEntry(entry, uniquify: true);
    expect(allocated, RevlogId(id + Int64.ONE));
    final loaded = storage.getRevlogEntry(allocated!)!;
    expect(loaded.id, allocated);
    expect(loaded.cardId, Int64(7));
    expect(
        storage.addRevlogEntry(_entry(id: id + Int64(2), cardId: 9),
            uniquify: true),
        RevlogId(id + Int64(2)));
  });

  test(
      'queries preserve Core filters, order, and seconds-to-milliseconds cutoff',
      () {
    _insert(sqlite, _entry(id: 1000, cardId: 20, ease: 4));
    _insert(sqlite, _entry(id: 5000, cardId: 10, ease: 0, factor: 0));
    _insert(sqlite, _entry(id: 3000, cardId: 10, ease: 2));
    _insert(sqlite, _entry(id: 4000, cardId: 30, ease: 5));
    sqlite.execute('INSERT INTO search_cids VALUES (10), (20)');

    expect(storage.getRevlogEntriesForCard(Int64(10)).map((e) => e.id.value),
        [Int64(3000), Int64(5000)]);
    expect(storage.getAllRevlogEntries(TimestampSecs(3)).map((e) => e.id.value),
        [Int64(3000), Int64(4000), Int64(5000)]);
    expect(
        storage
            .getRevlogEntriesForSearchedCardsAfterStamp(TimestampSecs(4))
            .map((e) => e.id.value),
        [Int64(5000)]);
    expect(storage.getRevlogEntriesForSearchedCards().map((e) => e.id.value),
        [Int64(1000), Int64(3000), Int64(5000)]);
    expect(
        storage
            .getRevlogEntriesForSearchedCardsInCardOrder()
            .map((e) => e.id.value),
        [Int64(3000), Int64(5000), Int64(1000)]);
    expect(storage.getAllRevlogEntriesInCardOrder().map((e) => e.id.value),
        [Int64(3000), Int64(5000), Int64(1000), Int64(4000)]);
    expect(storage.getRevlogEntriesForExportDataset().map((e) => e.id.value),
        [Int64(3000), Int64(5000), Int64(1000)]);
  });

  test('last review time follows Core review and cramming filters', () {
    // Older qualifying rows establish that the query chooses the latest one.
    _insert(sqlite, _entry(id: 1000, cardId: 10, ease: 1));
    _insert(sqlite, _entry(id: 2000, cardId: 10, ease: 4));
    _insert(sqlite, _entry(id: 3000, cardId: 10, ease: 0));
    _insert(sqlite, _entry(id: 4000, cardId: 10, ease: 5));
    _insert(
      sqlite,
      _entry(
        id: 5000,
        cardId: 10,
        ease: 3,
        factor: 0,
        kind: RevlogReviewKind.filtered,
      ),
    );
    _insert(
      sqlite,
      _entry(
        id: 6000,
        cardId: 10,
        ease: 3,
        factor: 1,
        kind: RevlogReviewKind.filtered,
      ),
    );
    _insert(sqlite, _entry(id: 7000, cardId: 11));

    expect(storage.timeOfLastReview(Int64(10)), TimestampSecs(6));
    expect(storage.timeOfLastReview(Int64(11)), TimestampSecs(7));
  });

  test('last review time is null when there is no qualifying review', () {
    _insert(sqlite, _entry(id: 1000, cardId: 10, ease: 0));
    _insert(
      sqlite,
      _entry(
        id: 2000,
        cardId: 10,
        ease: 2,
        factor: 0,
        kind: RevlogReviewKind.filtered,
      ),
    );

    expect(storage.timeOfLastReview(Int64(10)), isNull);
    expect(storage.timeOfLastReview(Int64(99)), isNull);
  });

  test('last review time retains integer precision for large revlog IDs', () {
    final id = Int64.parseInt('9007199254740993');
    _insert(sqlite, _entry(id: id, cardId: 10));

    expect(storage.timeOfLastReview(Int64(10)), TimestampSecs(9007199254740));
  });

  test(
      'row decoding keeps wide IDs and applies Core nullable and width defaults',
      () {
    final wideId = Int64.parseInt('9007199254740993');
    sqlite.execute('''
INSERT INTO revlog VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
''', [
      wideId.toString(),
      Int64.parseInt('9007199254740995').toString(),
      -1,
      255,
      2147483647,
      -2147483648,
      4294967295,
      null,
      257
    ]);
    final entry = storage.getRevlogEntry(RevlogId(wideId))!;
    expect(entry.id.value, wideId);
    expect(entry.cardId, Int64.parseInt('9007199254740995'));
    expect(entry.usn, -1);
    expect(entry.buttonChosen, 255);
    expect(entry.interval, 2147483647);
    expect(entry.lastInterval, -2147483648);
    expect(entry.easeFactor, 4294967295);
    expect(entry.takenMillis, 0);
    expect(entry.reviewKind, RevlogReviewKind.review);

    sqlite.execute('INSERT INTO revlog VALUES (1, 2, 0, 1, 0, 0, 0, -1, 99)');
    final invalid = storage.getRevlogEntry(RevlogId(Int64.ONE))!;
    expect(invalid.takenMillis, 0);
    expect(invalid.reviewKind, RevlogReviewKind.learning);

    sqlite.execute(
        'INSERT INTO revlog VALUES (3, 2, 0, 1, 0, 0, 4294967296, 0, 1)');
    expect(() => storage.getRevlogEntry(RevlogId(Int64(3))),
        throwsFormatException);
  });

  test('maintenance repairs properties and clears only pending sync USNs', () {
    sqlite.execute(
        'INSERT INTO revlog VALUES (1, 10, -1, 0, 1.6, -2.6, 0, 0, 0)');
    sqlite.execute(
        'INSERT INTO revlog VALUES (3, 10, 0, 1, 0, 0, 1, 4294967296, 1)');
    _insert(sqlite, _entry(id: 2, cardId: 20, usn: 8));

    expect(storage.fixRevlogProperties(), 2);
    expect(
        sqlite
            .select('SELECT ivl, lastIvl, time, type FROM revlog WHERE id=1')
            .single
            .values
            .toList(),
        [2, -3, 0, 5]);
    expect(
        sqlite
            .select('SELECT ivl, lastIvl, time, type FROM revlog WHERE id=3')
            .single
            .values
            .toList(),
        [0, 0, 2147483647, 1]);
    storage.clearPendingRevlogUsns();
    expect(
        sqlite
            .select('SELECT id, usn FROM revlog ORDER BY id')
            .map((row) => [row['id'], row['usn']])
            .toList(),
        [
          [1, 0],
          [2, 8],
          [3, 0]
        ]);
  });
}

RevlogEntry _entry({
  required Object id,
  required Object cardId,
  int usn = 0,
  int ease = 2,
  int interval = 0,
  int lastInterval = 0,
  int factor = 2500,
  int takenMillis = 50,
  RevlogReviewKind kind = RevlogReviewKind.review,
}) =>
    RevlogEntry(
      id: RevlogId(_toInt64(id)),
      cardId: _toInt64(cardId),
      usn: usn,
      buttonChosen: ease,
      interval: interval,
      lastInterval: lastInterval,
      easeFactor: factor,
      takenMillis: takenMillis,
      reviewKind: kind,
    );

Int64 _toInt64(Object value) => switch (value) {
      Int64 value => value,
      int value => Int64(value),
      BigInt value => Int64.parseInt(value.toString()),
      _ => throw ArgumentError.value(value),
    };

void _insert(Database database, RevlogEntry entry) {
  database.execute('INSERT INTO revlog VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', [
    entry.id.value.toString(),
    entry.cardId.toString(),
    entry.usn,
    entry.buttonChosen,
    entry.interval,
    entry.lastInterval,
    entry.easeFactor,
    entry.takenMillis,
    entry.reviewKind.value,
  ]);
}

final class _SqliteAdapter implements RevlogStorageDatabase {
  const _SqliteAdapter(this.database);

  final Database database;

  @override
  Int64 get lastInsertRowId => Int64(database.lastInsertRowId);

  @override
  List<Map<String, Object?>> select(String sql,
      [List<Object?> parameters = const []]) {
    final rows = database.select(
      sql,
      parameters
          .map((value) => value is Int64 ? value.toString() : value)
          .toList(),
    );
    final names = rows.columnNames;
    return rows
        .map((row) => {
              for (var index = 0; index < names.length; index++)
                names[index]: row.columnAt(index),
            })
        .toList(growable: false);
  }

  @override
  int execute(String sql, [List<Object?> parameters = const []]) {
    database.execute(
      sql,
      parameters
          .map((value) => value is Int64 ? value.toString() : value)
          .toList(),
    );
    return database.updatedRows;
  }
}
