// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:anki_backend_protocol/anki/import_export.pb.dart'
    as import_export;
import 'package:anki_backend_protocol/anki/import_export.pbenum.dart'
    as import_export_enum;
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_web.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_web_media.dart';
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/wasm.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:web/web.dart' as web;

Future<void> main() async {
  var phase = 'startup';
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
    phase = 'opened driver';
    final first = await CollectionSqliteStorage.open(
      driver: driver,
      location: 'collection.sqlite',
      nowMillis: () => generatedNoteId,
    );
    phase = 'opened first collection';
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
      CREATE TABLE cards (id INTEGER PRIMARY KEY, nid INTEGER);
      INSERT INTO cards VALUES (1, $generatedNoteId);
      INSERT INTO cards VALUES (2, -1);
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
    phase = 'made snapshot';
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
    phase = 'changed value';

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
    phase = 'media roundtrip';
    final mediaNames = (await first.listMedia()).toList();
    if (!mediaNames.contains('音声.bin')) {
      throw StateError('Web media listing omitted stored item');
    }
    if (await first.readMedia('missing.bin') != null) {
      throw StateError('Web missing media did not return null');
    }

    await mediaStorage.write('photo.png', Uint8List.fromList([1, 2, 3]));
    final exportCollection = await CollectionSqliteStorage.open(
      driver: driver,
      location: 'apkg-export.sqlite',
      nowMillis: () => generatedNoteId,
    );
    phase = 'opened export collection';
    var randomId = BigInt.one;
    final migrations = CollectionSqliteMigrationCallbacks(
      storage: exportCollection,
      randomU64: () {
        final value = randomId;
        randomId += BigInt.one;
        return value;
      },
      clock: () => DateTime.fromMillisecondsSinceEpoch(generatedNoteId),
    );
    await openOrCreateCollection(
      exportCollection,
      CollectionSqliteInitializationCallbacks(
        storage: exportCollection,
        text: _WebCollectionText(),
        migrations: migrations,
        localMinutesWest: (_) => 0,
        randomU64: () {
          final value = randomId;
          randomId += BigInt.one;
          return value;
        },
        clock: () => DateTime.fromMillisecondsSinceEpoch(generatedNoteId),
      ),
      serverMode: false,
    );
    phase = 'initialized export collection';
    final basicId = await exportCollection.queryInt(
      "SELECT id FROM notetypes WHERE name = 'Basic'",
    );
    final basic = (await exportCollection.getNotetypesByIds([
      NotetypeId(Int64(basicId)),
    ])).single;
    final exportNote = Note(
      id: Int64.ZERO,
      guid: 'web-apkg',
      notetypeId: basic.id.value,
      mtimeSecs: Int64(1),
      fields: ['<img src="photo.png">', 'answer'],
    );
    exportNote.prepareForUpdate(basic, normalizeText: false);
    await exportCollection.addNoteToDeck(exportNote, Int64.ONE);
    phase = 'added export note';
    final apkgBytes = await exportCollection.exportApkg();
    phase = 'exported APKG';
    final apkg = ZipDecoder().decodeBytes(apkgBytes);
    final meta = import_export.PackageMetadata.fromBuffer(
      apkg.findFile('meta')!.content as List<int>,
    );
    if (meta.version !=
        import_export_enum.PackageMetadata_Version.VERSION_LATEST) {
      throw StateError('Web APKG metadata did not identify current format');
    }
    final media = import_export.MediaEntries.fromBuffer(
      _decodeRawZstandardFrame(
        Uint8List.fromList(apkg.findFile('media')!.content as List<int>),
      ),
    );
    if (media.entries.length != 1 || media.entries.single.name != 'photo.png') {
      throw StateError('Web APKG media manifest was incomplete');
    }
    if (!_sameBytes(
      _decodeRawZstandardFrame(
        Uint8List.fromList(apkg.findFile('0')!.content as List<int>),
      ),
      [1, 2, 3],
    )) {
      throw StateError('Web APKG media bytes were corrupted');
    }
    final currentVersion = await _readExportVersion(
      Uint8List.fromList(
        _decodeRawZstandardFrame(
          Uint8List.fromList(
            apkg.findFile('collection.anki21b')!.content as List<int>,
          ),
        ),
      ),
      'web-apkg-current',
    );
    final compatibilityVersion = await _readExportVersion(
      Uint8List.fromList(
        apkg.findFile('collection.anki2')!.content as List<int>,
      ),
      'web-apkg-compat',
    );
    if (currentVersion != 18 || compatibilityVersion != 11) {
      throw StateError(
        'Web APKG SQLite versions were $currentVersion/$compatibilityVersion',
      );
    }
    await exportCollection.close();
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
    final secondProfileMedia = await IndexedDbCollectionMediaStorage.open(
      'anki.collection.media.v1.c2Vjb25k',
    );
    await secondProfileMedia.write('音声.bin', Uint8List.fromList([9, 8, 7]));
    final firstProfileRead = await mediaStorage.read('音声.bin');
    final secondProfileRead = await secondProfileMedia.read('音声.bin');
    if (firstProfileRead == null || secondProfileRead == null) {
      throw StateError('Profile-specific Web media store is missing');
    }
    final firstProfileBytes = await firstProfileRead
        .expand((chunk) => chunk)
        .toList();
    final secondProfileBytes = await secondProfileRead
        .expand((chunk) => chunk)
        .toList();
    if (!_sameBytes(mediaBytes, firstProfileBytes) ||
        !_sameBytes([9, 8, 7], secondProfileBytes)) {
      throw StateError('Web profile media stores are not isolated');
    }
    await secondProfileMedia.close();
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
    web.document.body?.textContent = 'FAIL ($phase): $error';
  }
}

Future<int> _readExportVersion(Uint8List bytes, String filename) async {
  final sqlite = await WasmSqlite3.loadFromUrlString('sqlite3.wasm');
  final vfs = InMemoryFileSystem(name: '$filename-vfs');
  sqlite.registerVirtualFileSystem(vfs);
  final path = vfs.xFullPathName('$filename.sqlite');
  vfs.fileData[path] = Uint8Buffer()..addAll(bytes);
  try {
    final database = sqlite.open('$filename.sqlite', vfs: vfs.name);
    database.createCollation(
      name: 'unicase',
      function: (left, right) =>
          (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase()),
    );
    final version = database.select('select ver from col').single['ver'] as int;
    database.close();
    return version;
  } finally {
    vfs.fileData.clear();
    sqlite.unregisterVirtualFileSystem(vfs);
  }
}

final class _WebCollectionText implements CollectionInitialTextProvider {
  @override
  String get defaultDeckName => 'Default';

  @override
  StockNotetypeNames get stockNotetypeNames => const StockNotetypeNames(
    basic: 'Basic',
    basicTyping: 'Basic (type answer)',
    basicReversed: 'Basic (and reversed card)',
    basicOptionalReversed: 'Basic (optional reversed card)',
    cloze: 'Cloze',
    frontField: 'Front',
    backField: 'Back',
    addReverseField: 'Add Reverse',
    textField: 'Text',
    backExtraField: 'Back Extra',
    commentsField: 'Comments',
    cardOne: 'Card 1',
    cardTwo: 'Card 2',
    imageOcclusion: 'Image Occlusion',
    occlusionsField: 'Occlusions',
    imageField: 'Image',
    headerField: 'Header',
    toggleMasks: 'Toggle Masks',
    errorLoadingImageOcclusion: 'Error loading Image Occlusion',
  );
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

Uint8List _decodeRawZstandardFrame(Uint8List frame) {
  if (frame.length < 6 ||
      frame[0] != 0x28 ||
      frame[1] != 0xb5 ||
      frame[2] != 0x2f ||
      frame[3] != 0xfd) {
    throw StateError('invalid Zstandard frame header');
  }
  final descriptor = frame[4];
  if ((descriptor & 0x20) == 0 || (descriptor & 0x1f) != 0) {
    throw StateError('unsupported Zstandard frame flags');
  }
  final sizeFlag = descriptor >> 6;
  final sizeWidth = switch (sizeFlag) {
    0 => 1,
    1 => 2,
    2 => 4,
    _ => 8,
  };
  var offset = 5;
  var contentSize = 0;
  for (var index = 0; index < sizeWidth; index++) {
    contentSize += frame[offset + index] << (8 * index);
  }
  if (sizeFlag == 1) contentSize += 256;
  offset += sizeWidth;
  final output = BytesBuilder(copy: false);
  var lastBlock = false;
  while (!lastBlock) {
    final header =
        frame[offset] | (frame[offset + 1] << 8) | (frame[offset + 2] << 16);
    offset += 3;
    lastBlock = (header & 1) != 0;
    final blockType = (header >> 1) & 3;
    final blockSize = header >> 3;
    if (blockType != 0 || offset + blockSize > frame.length) {
      throw StateError('unsupported or truncated Zstandard block');
    }
    output.add(frame.sublist(offset, offset + blockSize));
    offset += blockSize;
  }
  final bytes = output.takeBytes();
  if (offset != frame.length || bytes.length != contentSize) {
    throw StateError('Zstandard frame content size mismatch');
  }
  return bytes;
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
