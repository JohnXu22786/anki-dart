// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:typed_data';

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_web.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_web_media.dart';
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/wasm.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:web/web.dart' as web;

Future<void> main() async {
  try {
    const generatedNoteId = 5000000000;
    final store = 'anki-sqlite-smoke-${DateTime.now().microsecondsSinceEpoch}';
    var mediaStorage = await IndexedDbCollectionMediaStorage.openForCollection(
      store,
    );
    final driver = await experimentalWebCollectionSqliteDriver(
      sqliteWasmUrl: 'sqlite3.wasm',
      indexedDbName: store,
      mediaStorage: mediaStorage,
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

    final snapshot = await first.createSnapshot();
    final repeatedSnapshot = await first.createSnapshot();
    if (repeatedSnapshot.length != snapshot.length) {
      throw StateError('Repeated Web snapshot changed database size');
    }
    final snapshotReader = await WasmSqlite3.loadFromUrlString('sqlite3.wasm');
    final snapshotVfs = InMemoryFileSystem(name: 'snapshot-read-smoke');
    snapshotReader.registerVirtualFileSystem(snapshotVfs);
    final snapshotPath = snapshotVfs.xFullPathName('snapshot.sqlite');
    snapshotVfs.fileData[snapshotPath] = Uint8Buffer()..addAll(snapshot);
    final snapshotDatabase = snapshotReader.open(
      'snapshot.sqlite',
      vfs: snapshotVfs.name,
    );
    final snapshotValue = snapshotDatabase
        .select('SELECT value FROM smoke')
        .single['value'];
    snapshotDatabase.close();
    snapshotVfs.fileData.clear();
    snapshotReader.unregisterVirtualFileSystem(snapshotVfs);

    await first.executeBatch("UPDATE smoke SET value = 'changed'");
    final changedValue = await first.queryString('SELECT value FROM smoke');

    final mediaBytes = Uint8List.fromList(
      List<int>.generate(150000, (index) => index % 251),
    );
    await mediaStorage.write('音声.bin', mediaBytes);
    final mediaStream = await first.readMedia('音声.bin');
    if (mediaStream == null) throw StateError('Web media missing after write');
    final streamedMedia = <int>[];
    await for (final chunk in mediaStream) {
      if (chunk.length > 64 * 1024) {
        throw StateError('Web media stream exceeded the chunk bound');
      }
      streamedMedia.addAll(chunk);
    }
    if (!_sameBytes(mediaBytes, streamedMedia)) {
      throw StateError('Web media bytes did not round trip');
    }
    final mediaNames = (await first.listMedia()).toList();
    if (!mediaNames.contains('音声.bin')) {
      throw StateError('Web media listing omitted stored item');
    }
    if (await first.readMedia('missing.bin') != null) {
      throw StateError('Web missing media did not return null');
    }
    try {
      await first.readMedia('../unsafe');
      throw StateError('Web media path traversal was accepted');
    } on ArgumentError {
      // The shared collection boundary rejects the unsafe name.
    }
    await first.close();
    mediaStorage.close();
    mediaStorage = await IndexedDbCollectionMediaStorage.openForCollection(
      store,
    );
    final persistedStream = await mediaStorage.read('音声.bin');
    if (persistedStream == null) {
      throw StateError('Web media did not persist across reopen');
    }
    final persistedMedia = <int>[];
    await for (final chunk in persistedStream) {
      persistedMedia.addAll(chunk);
    }
    if (!_sameBytes(mediaBytes, persistedMedia)) {
      throw StateError('Reopened Web media bytes changed');
    }
    mediaStorage.close();

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
        value == 'changed' &&
            changedValue == 'changed' &&
            snapshotValue == 'persisted' &&
            note.endsWith(':persisted note')
        ? 'PASS'
        : 'FAIL: $value / $changedValue / $snapshotValue / $note';
  } catch (error) {
    web.document.body?.textContent = 'FAIL: $error';
  }
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
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
