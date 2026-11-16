// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:ffi';
import 'dart:io';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_storage/anki_backend_storage.dart';
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
  late TagStorage storage;

  setUp(() {
    sqlite = sqlite3.openInMemory();
    sqlite.execute('''
CREATE TABLE tags (
  tag TEXT NOT NULL PRIMARY KEY COLLATE NOCASE,
  usn INTEGER NOT NULL,
  collapsed BOOLEAN NOT NULL,
  config BLOB NULL
) WITHOUT ROWID''');
    storage = TagStorage(_SqliteAdapter(sqlite));
  });

  tearDown(() => sqlite.dispose());

  test('tag reads preserve table order, stored case, and expanded state', () {
    storage.registerTag(Tag(name: 'Zulu', usn: 4, expanded: true));
    storage.registerTag(Tag(name: 'alpha', usn: -1));

    expect(storage.allTags(), [
      Tag(name: 'alpha', usn: -1),
      Tag(name: 'Zulu', usn: 4, expanded: true),
    ]);
    expect(storage.getTag('ZULU'), Tag(name: 'Zulu', usn: 4, expanded: true));
    expect(storage.preferredTagCase('zulu'), 'Zulu');
    expect(storage.getTag('absent'), isNull);
    expect(storage.getTagsByPredicate((name) => name.startsWith('Z')), [
      Tag(name: 'Zulu', usn: 4, expanded: true),
    ]);
    expect(storage.expandedTags(), ['Zulu']);
  });

  test('register replaces, update and remove use Core name semantics', () {
    storage.registerTag(Tag(name: 'Before', usn: 2));
    storage.registerTag(Tag(name: 'BEFORE', usn: 9, expanded: true));
    expect(storage.allTags(), [Tag(name: 'BEFORE', usn: 9, expanded: true)]);
    storage.updateTag(Tag(name: 'BEFORE', usn: 10));
    expect(storage.getTag('before'), Tag(name: 'BEFORE', usn: 10));
    storage.removeSingleTag('Before');
    storage.removeSingleTag('missing');
    expect(storage.allTags(), isEmpty);
  });

  test('expanded restore and sync USN operations match Core predicates', () {
    storage.registerTag(Tag(name: 'one', usn: -1));
    storage.registerTag(Tag(name: 'two', usn: 0));
    storage.registerTag(Tag(name: 'three', usn: 3, expanded: true));
    storage.restoreExpandedTags(['one', 'two']);
    expect(storage.expandedTags(), ['one', 'three', 'two']);
    expect(storage.tagsPendingSync(-1), ['one']);
    expect(storage.tagsPendingSync(0), ['three', 'two']);
    storage.updateTagUsns(['one', 'one', 'three'], 7);
    expect(storage.tagsPendingSync(7), ['one', 'three']);
    storage.clearTagUsns();
    expect(storage.allTags().map((tag) => tag.usn), [0, 0, 0]);
    storage.clearAllTags();
    expect(storage.allTags(), isEmpty);
  });
}

final class _SqliteAdapter implements TagStorageDatabase {
  const _SqliteAdapter(this.database);

  final Database database;

  @override
  List<Map<String, Object?>> select(
    String sql, [
    List<Object?> parameters = const [],
  ]) {
    final rows = database.select(sql, parameters);
    final names = rows.columnNames;
    return rows
        .map(
          (row) => {
            for (var i = 0; i < names.length; i++) names[i]: row.columnAt(i),
          },
        )
        .toList(growable: false);
  }

  @override
  int execute(String sql, [List<Object?> parameters = const []]) {
    database.execute(sql, parameters);
    return database.updatedRows;
  }
}
