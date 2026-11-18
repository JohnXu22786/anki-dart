// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:io';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  const generatedNoteId = 5000000000;
  late Directory directory;
  late String path;
  late CollectionSqliteStorage storage;
  late Database database;
  late int flushes;

  setUp(() async {
    flushes = 0;
    directory = await Directory.systemTemp.createTemp('anki-notes-');
    path = '${directory.path}/collection.anki2';
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (location) => database = sqlite3.open(location),
        flush: () => flushes++,
      ),
      location: path,
      nowMillis: () => generatedNoteId,
    );
    await storage.executeBatch('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY, guid TEXT NOT NULL, mid INTEGER NOT NULL,
        mod INTEGER NOT NULL, usn INTEGER NOT NULL, tags TEXT NOT NULL,
        flds TEXT NOT NULL, sfld INTEGER NOT NULL, csum INTEGER NOT NULL,
        flags INTEGER NOT NULL, data TEXT NOT NULL
      );
    ''');
  });

  tearDown(() async {
    await storage.close();
    await directory.delete(recursive: true);
  });

  test('all note mutations preserve shared NoteStorage behavior', () async {
    final inserted = _note(fields: ['front', 'back'], tags: ['one', 'two']);
    await storage.addNote(inserted);

    expect(inserted.id, Int64(generatedNoteId));
    expect(database.select('SELECT * FROM notes').single.values, [
      inserted.id.toInt(),
      inserted.guid,
      9,
      1234567890123,
      -1,
      ' one two ',
      'front\x1fback',
      'front',
      inserted.checksum,
      0,
      '',
    ]);

    final update = _note(id: inserted.id, field: 'changed', tags: ['updated']);
    await storage.updateNote(update);
    expect(
      update.id,
      inserted.id,
      reason: 'update does not replace model identity',
    );
    expect(
      database.select('SELECT tags, flds, sfld, csum FROM notes').single.values,
      [' updated ', 'changed', 'changed', update.checksum],
    );

    final unique = _note(id: Int64(101), field: 'unique');
    expect(await storage.addNoteIfUnique(unique), isTrue);
    expect(await storage.addNoteIfUnique(_note(id: Int64(101))), isFalse);
    expect(
      database.select('SELECT flds FROM notes WHERE id = 101').single['flds'],
      'unique',
    );

    await storage.addOrUpdateNote(_note(id: Int64(101), field: 'replaced'));
    expect(
      database.select('SELECT flds FROM notes WHERE id = 101').single['flds'],
      'replaced',
    );
    await storage.removeNote(Int64(999));
    await storage.removeNote(Int64(101));
    await storage.updateNote(_note(id: Int64(404), field: 'missing'));
    expect(database.select('SELECT id FROM notes').map((row) => row['id']), [
      inserted.id.toInt(),
    ]);
  });

  test(
    'prepared note preconditions, duplicate IDs, and SQLite errors propagate',
    () async {
      await expectLater(storage.updateNote(_note()), throwsStateError);
      await expectLater(storage.addNote(_note(id: Int64(1))), throwsStateError);
      final dirty = Note(id: Int64(1), notetypeId: Int64(9), fields: ['dirty']);
      await expectLater(storage.addOrUpdateNote(dirty), throwsStateError);
      await expectLater(storage.addNoteIfUnique(dirty), throwsStateError);

      await storage.addOrUpdateNote(_note(id: Int64(10), field: 'first'));
      await expectLater(
        storage.addNoteIfUnique(_note(id: Int64(10), field: 'duplicate')),
        completion(isFalse),
      );
      await storage.executeBatch('''
      CREATE TRIGGER reject_note BEFORE INSERT ON notes
      WHEN NEW.id = 13 BEGIN SELECT RAISE(ABORT, 'rejected'); END;
    ''');
      await expectLater(
        storage.addNoteIfUnique(_note(id: Int64(13))),
        throwsA(isA<SqliteException>()),
      );
    },
  );

  test(
    'mutations stay in caller transaction and rollback without flush',
    () async {
      final flushesBeforeTransaction = flushes;
      await storage.executeBatch('BEGIN');
      await storage.addOrUpdateNote(_note(id: Int64(77)));
      expect(flushes, flushesBeforeTransaction);
      expect(
        database.select('SELECT count(*) FROM notes').single.columnAt(0),
        1,
      );
      await storage.executeBatch('ROLLBACK');
      expect(
        database.select('SELECT count(*) FROM notes').single.columnAt(0),
        0,
      );
      expect(flushes, flushesBeforeTransaction + 1);
    },
  );

  test('autocommit note writes flush and survive close and reopen', () async {
    final beforeWrite = flushes;
    await storage.addOrUpdateNote(_note(id: Int64(81), field: 'persisted'));
    expect(flushes, beforeWrite + 1);
    await storage.updateNote(_note(id: Int64(81), field: 'updated'));
    expect(flushes, beforeWrite + 2);
    await storage.close();

    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (location) => database = sqlite3.open(location),
        flush: () => flushes++,
      ),
      location: path,
      nowMillis: () => generatedNoteId,
    );
    expect(
      database.select('SELECT flds FROM notes WHERE id = 81').single['flds'],
      'updated',
    );
  });

  test(
    'addNote returns an exact 64-bit ID above JavaScript safe integer range',
    () async {
      database.execute('''
      INSERT INTO notes VALUES (
        9007199254740993, 'large', 9, 1, 0, '', '', '', 0, 0, ''
      )
    ''');

      final note = _note();
      database.execute('''
      INSERT INTO notes VALUES (
        $generatedNoteId, 'timestamp', 9, 1, 0, '', '', '', 0, 0, ''
      )
    ''');
      await storage.addNote(note);
      expect(note.id, isNot(Int64.parseInt('9007199254740993')));
      expect(note.id.toString(), '9007199254740994');
      expect(
        database
            .select("SELECT guid FROM notes WHERE id = 9007199254740994")
            .single['guid'],
        note.guid,
      );
    },
  );
}

Note _note({
  Int64 id = Int64.ZERO,
  String field = 'value',
  List<String>? fields,
  List<String> tags = const [],
}) {
  final note = Note(
    id: id,
    guid: 'guid-${id.toString()}-$field',
    notetypeId: Int64(9),
    mtimeSecs: Int64.parseInt('1234567890123'),
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
