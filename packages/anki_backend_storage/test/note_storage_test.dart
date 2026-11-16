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
  late _SqliteAdapter adapter;
  late NoteStorage storage;

  setUp(() {
    sqlite = sqlite3.openInMemory();
    sqlite.execute('''
CREATE TABLE notes (
  id INTEGER PRIMARY KEY,
  guid TEXT NOT NULL,
  mid INTEGER NOT NULL,
  mod INTEGER NOT NULL,
  usn INTEGER NOT NULL,
  tags TEXT NOT NULL,
  flds TEXT NOT NULL,
  sfld INTEGER NOT NULL,
  csum INTEGER NOT NULL,
  flags INTEGER NOT NULL,
  data TEXT NOT NULL
)''');
    adapter = _SqliteAdapter(sqlite);
    storage = NoteStorage(adapter, nowMillis: () => 5000000000);
  });

  tearDown(() => sqlite.dispose());

  test('updates columns in source order and rejects zero IDs', () {
    final original = _note(id: 42, field: 'before');
    storage.addOrUpdateNote(original);
    final replacement = _note(id: 42, field: 'after', tags: ['one', 'two']);

    storage.updateNote(replacement);

    final row = sqlite.select('SELECT * FROM notes WHERE id = 42').single;
    expect(row['guid'], replacement.guid);
    expect(row['mid'], 9);
    expect(row['mod'], 1234567890123);
    expect(row['usn'], -1);
    expect(row['tags'], ' one two ');
    expect(row['flds'], 'after');
    expect(row['sfld'], 'after');
    expect(row['csum'], replacement.checksum);
    expect(() => storage.updateNote(_note()), throwsStateError);
  });

  test('add assigns a generated 64-bit ID and joins fields and tags', () {
    expect(() => storage.addNote(_note(id: 1)), throwsStateError);
    final note = _note(fields: ['front', 'back'], tags: ['tag']);
    storage.addNote(note);

    expect(note.id, Int64(5000000000));
    final row = sqlite.select('SELECT * FROM notes').single;
    expect(row['id'], 5000000000);
    expect(row['tags'], ' tag ');
    expect(row['flds'], 'front\x1fback');
    expect(row['flags'], 0);
    expect(row['data'], '');

    final collidingNote = _note(field: 'next');
    storage.addNote(collidingNote);
    expect(collidingNote.id, Int64(5000000001));
  });

  test(
    'add-if-unique ignores duplicate IDs and propagates trigger failures',
    () {
      final note = _note(id: 12);
      expect(storage.addNoteIfUnique(note), isTrue);
      expect(
        storage.addNoteIfUnique(_note(id: 12, field: 'duplicate')),
        isFalse,
      );
      expect(
        sqlite.select('SELECT guid FROM notes WHERE id = 12').single['guid'],
        note.guid,
      );

      sqlite.execute('''CREATE TRIGGER fail_note_insert BEFORE INSERT ON notes
      WHEN NEW.id = 13 BEGIN SELECT RAISE(ABORT, 'rejected'); END''');
      expect(
        () => storage.addNoteIfUnique(_note(id: 13)),
        throwsA(isA<SqliteException>()),
      );
    },
  );

  test('add-or-update uses replace semantics while preserving the note ID', () {
    storage.addOrUpdateNote(_note(id: 31, field: 'old'));
    storage.addOrUpdateNote(_note(id: 31, field: 'new'));

    expect(sqlite.select('SELECT count(*) AS n FROM notes').single['n'], 1);
    expect(
      sqlite.select('SELECT flds FROM notes WHERE id = 31').single['flds'],
      'new',
    );
  });

  test('remove of a missing ID succeeds and cached statements are reused', () {
    storage.removeNote(Int64(404));
    storage.removeNote(Int64(404));
    expect(sqlite.select('SELECT count(*) AS n FROM notes').single['n'], 0);
    expect(adapter.prepareCount, 1);
  });

  test('writes participate in caller transactions and rollback cleanly', () {
    sqlite.execute('BEGIN');
    storage.addOrUpdateNote(_note(id: 77));
    expect(sqlite.select('SELECT count(*) AS n FROM notes').single['n'], 1);
    sqlite.execute('ROLLBACK');
    expect(sqlite.select('SELECT count(*) AS n FROM notes').single['n'], 0);
  });
}

Note _note({
  int id = 0,
  String field = 'value',
  List<String>? fields,
  List<String> tags = const [],
}) {
  final note = Note(
    id: Int64(id),
    guid: 'guid-$id-$field',
    notetypeId: Int64(9),
    mtimeSecs: Int64(1234567890123),
    usn: -1,
    tags: tags,
    fields: fields ?? [field],
  );
  note.prepareForUpdate(
    Notetype(
      id: NotetypeId(Int64(9)),
      fields: List.generate(
        note.fields.length,
        (index) => NoteField.newField(
          'Field$index',
          randomU64: () => BigInt.from(index + 1),
        ),
      ),
      config: Notetype.defaultConfig(),
    ),
    normalizeText: false,
  );
  return note;
}

class _SqliteAdapter implements NoteStorageDatabase {
  _SqliteAdapter(this.db);

  final Database db;
  final Map<String, _SqliteStatement> _statements = {};
  int prepareCount = 0;

  @override
  Int64 get lastInsertRowId => Int64(db.lastInsertRowId);

  @override
  NoteStorageStatement prepareCached(String sql) =>
      _statements.putIfAbsent(sql, () {
        prepareCount++;
        return _SqliteStatement(db, db.prepare(sql));
      });
}

class _SqliteStatement implements NoteStorageStatement {
  _SqliteStatement(this.db, this.statement);

  final Database db;
  final PreparedStatement statement;

  @override
  int execute(List<Object?> parameters) {
    statement.execute([
      for (final parameter in parameters)
        if (parameter is Int64) parameter.toInt() else parameter,
    ]);
    return db.updatedRows;
  }
}
