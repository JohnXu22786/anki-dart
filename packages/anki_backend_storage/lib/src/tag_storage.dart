// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';

/// The portable SQL query surface required by [TagStorage].
abstract interface class TagStorageDatabase {
  /// Executes a query and retains SQLite's row order.
  List<Map<String, Object?>> select(String sql, [List<Object?> parameters]);

  /// Executes a mutation and returns SQLite's changed-row count.
  int execute(String sql, [List<Object?> parameters]);
}

/// Reads and writes Anki Core `tags` rows without selecting a database driver.
class TagStorage {
  TagStorage(this.db);

  final TagStorageDatabase db;

  /// Returns tags in the table's natural (unicase primary-key) order.
  List<Tag> allTags() =>
      db.select(_getTagsSql).map(_tagFromRow).toList(growable: false);

  /// Returns a tag by its schema-collated name, or null when absent.
  Tag? getTag(String name) {
    final rows = db.select('$_getTagsSql WHERE tag = ?', [name]);
    return rows.isEmpty ? null : _tagFromRow(rows.single);
  }

  /// Returns the stored spelling for a schema-collated tag name.
  String? preferredTagCase(String name) {
    final rows = db.select('SELECT tag FROM tags WHERE tag = ?', [name]);
    return rows.isEmpty ? null : _string(rows.single['tag'], 'tag');
  }

  /// Returns only tags accepted by [want], preserving Core query order.
  List<Tag> getTagsByPredicate(bool Function(String name) want) => db
      .select(_getTagsSql)
      .where((row) => want(_string(row['tag'], 'tag')))
      .map(_tagFromRow)
      .toList(growable: false);

  /// Returns names whose rows are currently expanded.
  List<String> expandedTags() => db
      .select('SELECT tag FROM tags WHERE collapsed = false')
      .map((row) => _string(row['tag'], 'tag'))
      .toList(growable: false);

  /// Restores expanded state for the exact supplied names, in caller order.
  void restoreExpandedTags(Iterable<String> names) {
    for (final name in names) {
      db.execute('UPDATE tags SET collapsed = false WHERE tag = ?', [name]);
    }
  }

  /// Inserts or replaces a tag row, storing the inverse collapsed flag.
  void registerTag(Tag tag) {
    db.execute(_addTagSql, [tag.name, tag.usn, !tag.expanded]);
  }

  /// Updates USN and expanded state using Core's `update.sql` parameters.
  void updateTag(Tag tag) {
    db.execute(_updateTagSql, [tag.name, tag.usn, !tag.expanded]);
  }

  /// Removes one schema-collated tag name if it exists.
  void removeSingleTag(String name) {
    db.execute('DELETE FROM tags WHERE tag = ?', [name]);
  }

  /// Deletes every tag row.
  void clearAllTags() {
    db.execute('DELETE FROM tags');
  }

  /// Sets nonzero sync USNs to zero.
  void clearTagUsns() {
    db.execute('UPDATE tags SET usn = 0 WHERE usn != 0');
  }

  /// Returns names pending synchronization according to Core's USN clause.
  List<String> tagsPendingSync(int usn) {
    final clause = usn == -1 ? 'usn = ?' : 'usn >= ?';
    return db
        .select('SELECT tag FROM tags WHERE $clause', [usn])
        .map((row) => _string(row['tag'], 'tag'))
        .toList(growable: false);
  }

  /// Updates supplied tag USNs in order; repeated names are preserved.
  void updateTagUsns(Iterable<String> names, int newUsn) {
    for (final name in names) {
      db.execute('UPDATE tags SET usn = ? WHERE tag = ?', [newUsn, name]);
    }
  }

  static Tag _tagFromRow(Map<String, Object?> row) => Tag(
        name: _string(row['tag'], 'tag'),
        usn: _int32(row['usn'], 'usn'),
        expanded: !_bool(row['collapsed'], 'collapsed'),
      );

  static String _string(Object? value, String field) => value is String
      ? value
      : throw FormatException('invalid text tag $field');

  static int _int32(Object? value, String field) {
    final integer = switch (value) {
      int value => value,
      BigInt value
          when value >= BigInt.from(-0x80000000) &&
              value <= BigInt.from(0x7fffffff) =>
        value.toInt(),
      _ => throw FormatException('invalid signed 32-bit tag $field'),
    };
    if (integer < -0x80000000 || integer > 0x7fffffff) {
      throw FormatException('invalid signed 32-bit tag $field');
    }
    return integer;
  }

  static bool _bool(Object? value, String field) => switch (value) {
        bool value => value,
        int value when value == 0 => false,
        int value when value == 1 => true,
        BigInt value when value == BigInt.zero => false,
        BigInt value when value == BigInt.one => true,
        _ => throw FormatException('invalid SQLite tag $field'),
      };

  static const _getTagsSql = 'SELECT tag, usn, collapsed FROM tags';

  static const _addTagSql = '''
INSERT OR REPLACE INTO tags (tag, usn, collapsed)
VALUES (?, ?, ?)''';

  static const _updateTagSql = '''
UPDATE tags
SET tag = ?1, usn = ?, collapsed = ?
WHERE tag = ?1''';
}
