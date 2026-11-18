// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_web.dart';
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';
import 'package:web/web.dart' as web;

Future<void> main() async {
  try {
    const generatedNoteId = 5000000000;
    final store = 'anki-sqlite-smoke-${DateTime.now().microsecondsSinceEpoch}';
    final driver = await experimentalWebCollectionSqliteDriver(
      sqliteWasmUrl: 'sqlite3.wasm',
      indexedDbName: store,
    );
    final first = await CollectionSqliteStorage.open(
      driver: driver,
      location: 'collection.sqlite',
      nowMillis: () => generatedNoteId,
    );
    await first.executeBatch(
      'create table smoke (id integer primary key, value text);'
      "insert into smoke values (1, 'persisted');",
    );
    await first.executeBatch('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY, guid TEXT NOT NULL, mid INTEGER NOT NULL,
        mod INTEGER NOT NULL, usn INTEGER NOT NULL, tags TEXT NOT NULL,
        flds TEXT NOT NULL, sfld INTEGER NOT NULL, csum INTEGER NOT NULL,
        flags INTEGER NOT NULL, data TEXT NOT NULL
      );
    ''');
    await first.executeBatch('''
      INSERT INTO notes VALUES (
        $generatedNoteId, 'timestamp', 9, 1, 0, '', '', '', 0, 0, ''
      );
    ''');
    await first.addOrUpdateNote(_note(Int64.parseInt('9007199254740993')));
    final generated = _note(Int64.ZERO, field: 'before');
    await first.addNote(generated);
    if (generated.id.toString() != '9007199254740994') {
      throw StateError('inexact generated note ID: ${generated.id}');
    }
    await first.updateNote(_note(generated.id, field: 'persisted note'));
    await first.removeNote(Int64.parseInt('9007199254740993'));
    await first.close();

    final reopened = await CollectionSqliteStorage.open(
      driver: driver,
      location: 'collection.sqlite',
      nowMillis: () => generatedNoteId,
    );
    final value = await reopened.queryString('select value from smoke');
    final note = await reopened.queryString(
      "SELECT guid || ':' || flds FROM notes WHERE id = 9007199254740994",
    );
    await reopened.close();
    web.document.body?.textContent =
        value == 'persisted' && note.endsWith(':persisted note')
        ? 'PASS'
        : 'FAIL: $value / $note';
  } catch (error) {
    web.document.body?.textContent = 'FAIL: $error';
  }
}

Note _note(Int64 id, {String field = 'value'}) {
  final note = Note(
    id: id,
    guid: 'web-$id-$field',
    notetypeId: Int64(9),
    mtimeSecs: Int64(1),
    fields: [field],
  );
  note.prepareForUpdate(
    Notetype(
      id: NotetypeId(Int64(9)),
      fields: [NoteField.newField('Front', randomU64: () => BigInt.one)],
      config: Notetype.defaultConfig(),
    ),
    normalizeText: false,
  );
  return note;
}
