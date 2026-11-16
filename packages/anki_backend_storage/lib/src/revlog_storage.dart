// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';

/// The portable SQLite surface required by [RevlogStorage].
abstract interface class RevlogStorageDatabase {
  /// Executes a query and retains SQLite's row order.
  List<Map<String, Object?>> select(String sql, [List<Object?> parameters]);

  /// Executes a mutation and returns SQLite's changed-row count.
  int execute(String sql, [List<Object?> parameters]);

  /// The 64-bit row ID from the most recent successful insert on this handle.
  Int64 get lastInsertRowId;
}

/// Reads and writes Anki Core revlog rows without selecting a database driver.
class RevlogStorage {
  RevlogStorage(this.db);

  final RevlogStorageDatabase db;

  /// Adds [entry] if its ID is unique, optionally allocating a new ID on clash.
  /// Returns the inserted ID, or null when an existing ID was ignored.
  RevlogId? addRevlogEntry(RevlogEntry entry, {bool uniquify = false}) {
    final added = db.execute(_addSql, [
      uniquify,
      entry.id.value,
      entry.cardId,
      entry.usn,
      entry.buttonChosen,
      entry.interval,
      entry.lastInterval,
      entry.easeFactor,
      entry.takenMillis,
      entry.reviewKind.value,
    ]);
    return added > 0 ? RevlogId(db.lastInsertRowId) : null;
  }

  /// Returns the row with [id], or null if it does not exist.
  RevlogEntry? getRevlogEntry(RevlogId id) {
    final rows = db.select('$_getSql WHERE id = ?', [id.value]);
    return rows.isEmpty ? null : _entryFromRow(rows.single);
  }

  /// Deletes one row if it exists.
  void removeRevlogEntry(RevlogId id) {
    db.execute('DELETE FROM revlog WHERE id = ?', [id.value]);
  }

  /// Returns a card's entries in Core's natural query order.
  List<RevlogEntry> getRevlogEntriesForCard(Int64 cardId) =>
      _query('WHERE cid = ?', [cardId]);

  /// Returns entries for searched cards on/after [after] in seconds.
  List<RevlogEntry> getRevlogEntriesForSearchedCardsAfterStamp(
    TimestampSecs after,
  ) =>
      _query(
        'WHERE cid IN (SELECT cid FROM search_cids) AND id >= ?',
        [after * Int64(1000)],
      );

  /// Returns entries for searched cards in Core's natural query order.
  List<RevlogEntry> getRevlogEntriesForSearchedCards() =>
      _query('WHERE cid IN (SELECT cid FROM search_cids)');

  /// Returns searched-card entries ordered by card ID and then revlog ID.
  List<RevlogEntry> getRevlogEntriesForSearchedCardsInCardOrder() =>
      _query('WHERE cid IN (SELECT cid FROM search_cids) ORDER BY cid, id');

  /// Returns entries included in Core's export dataset, ordered by card.
  List<RevlogEntry> getRevlogEntriesForExportDataset() => _query(
        'WHERE (ease BETWEEN 1 AND 4) OR (ease = 0 AND factor = 0) '
        'ORDER BY cid, id',
      );

  /// Returns every entry ordered by card ID and then revlog ID.
  List<RevlogEntry> getAllRevlogEntriesInCardOrder() =>
      _query('ORDER BY cid, id');

  /// Returns entries on/after [after] in seconds in Core's natural query order.
  List<RevlogEntry> getAllRevlogEntries(TimestampSecs after) =>
      _query('WHERE id >= ?', [after * Int64(1000)]);

  /// Clears pending sync markers, preserving other USN values.
  void clearPendingRevlogUsns() {
    db.execute('UPDATE revlog SET usn = 0 WHERE usn = -1');
  }

  /// Repairs stored interval, time, and review-kind values using Core's SQL.
  int fixRevlogProperties() => db.execute(_fixPropertiesSql);

  List<RevlogEntry> _query(
          [String suffix = '', List<Object?> parameters = const []]) =>
      db
          .select('$_getSql $suffix', parameters)
          .map(_entryFromRow)
          .toList(growable: false);

  static RevlogEntry _entryFromRow(Map<String, Object?> row) => RevlogEntry(
        id: RevlogId(_int64(row['id'], 'id')),
        cardId: _int64(row['cid'], 'cid'),
        usn: _signedInt32(_integer(row['usn'], 'usn'), 'usn'),
        buttonChosen: _unsignedInt8(_integer(row['ease'], 'ease'), 'ease'),
        interval: _signedInt32(_integer(row['ivl'], 'ivl'), 'ivl'),
        lastInterval:
            _signedInt32(_integer(row['lastIvl'], 'lastIvl'), 'lastIvl'),
        easeFactor: _unsignedInt32(_integer(row['factor'], 'factor'), 'factor'),
        takenMillis: _nullableUint32(row['time']),
        reviewKind: _reviewKind(row['type']),
      );

  static Int64 _int64(Object? value, String field) => switch (value) {
        Int64 value => value,
        int value => Int64(value),
        BigInt value => Int64.parseInt(value.toString()),
        _ => throw FormatException('invalid 64-bit revlog $field'),
      };

  static int _integer(Object? value, String field) {
    final big = switch (value) {
      int value => BigInt.from(value),
      BigInt value => value,
      Int64 value => BigInt.parse(value.toString()),
      _ => throw FormatException('invalid integer revlog $field'),
    };
    if (big < BigInt.parse('-9223372036854775808') ||
        big > BigInt.parse('9223372036854775807')) {
      throw FormatException('out-of-range integer revlog $field');
    }
    return big.toInt();
  }

  static int _nullableUint32(Object? value) {
    final big = switch (value) {
      int value => BigInt.from(value),
      BigInt value => value,
      Int64 value => BigInt.parse(value.toString()),
      _ => BigInt.zero,
    };
    if (value is! int && value is! BigInt && value is! Int64) return 0;
    if (big < BigInt.zero || big > BigInt.from(0xffffffff)) {
      return 0;
    }
    return big.toInt();
  }

  static int _signedInt32(int value, String field) {
    if (value < -0x80000000 || value > 0x7fffffff) {
      throw FormatException('out-of-range signed 32-bit revlog $field');
    }
    return value;
  }

  static int _unsignedInt8(int value, String field) {
    if (value < 0 || value > 0xff) {
      throw FormatException('out-of-range unsigned 8-bit revlog $field');
    }
    return value;
  }

  static int _unsignedInt32(int value, String field) {
    if (value < 0 || value > 0xffffffff) {
      throw FormatException('out-of-range unsigned 32-bit revlog $field');
    }
    return value;
  }

  static RevlogReviewKind _reviewKind(Object? value) {
    final raw = switch (value) {
      int value => value.toUnsigned(8),
      BigInt value => value.toUnsigned(8).toInt(),
      Int64 value => BigInt.parse(value.toString()).toUnsigned(8).toInt(),
      _ => -1,
    };
    if (raw < 0) return RevlogReviewKind.learning;
    return RevlogReviewKind.fromRaw(raw);
  }

  static const _getSql = '''
SELECT id,
  cid,
  usn,
  ease,
  CAST(ivl AS INTEGER) AS ivl,
  CAST(lastIvl AS INTEGER) AS lastIvl,
  factor,
  time,
  type
FROM revlog''';

  static const _addSql = '''
INSERT OR IGNORE INTO revlog (
  id, cid, usn, ease, ivl, lastIvl, factor, time, type
)
VALUES (
  CASE WHEN ?1 AND ?2 IN (SELECT id FROM revlog)
    THEN (SELECT max(id) + 1 FROM revlog) ELSE ?2 END,
  ?, ?, ?, ?, ?, ?, ?, ?
)''';

  static const _fixPropertiesSql = '''
UPDATE revlog
SET ivl = min(max(round(ivl), -2147483648), 2147483647),
  lastIvl = min(max(round(lastIvl), -2147483648), 2147483647),
  time = min(max(round(time), 0), 2147483647),
  type = CASE WHEN type = 0 AND time = 0 AND ease = 0 THEN 5 ELSE type END
WHERE ivl != min(max(round(ivl), -2147483648), 2147483647)
  OR lastIvl != min(max(round(lastIvl), -2147483648), 2147483647)
  OR time != min(max(round(time), 0), 2147483647)
  OR type != CASE WHEN type = 0 AND time = 0 AND ease = 0 THEN 5 ELSE type END''';
}
