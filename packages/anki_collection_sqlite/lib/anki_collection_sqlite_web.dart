// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:typed_data';

import 'package:sqlite3/wasm.dart';

import 'src/collection_sqlite_storage.dart';
import 'src/portable_package_io.dart';

var _snapshotVfsSerial = 0;

/// Creates a Web SQLite driver backed by IndexedDB rather than memory-only
/// storage.
///
/// The sqlite3 WebAssembly and IndexedDB implementations are experimental and
/// do not guarantee crash durability. Applications requiring durable
/// collections must treat this driver as unsupported for that requirement or
/// supply a separately validated [CollectionSqliteDriver]. Snapshots use
/// SQLite's `VACUUM INTO` command with a temporary in-memory VFS. The host must copy
/// the version-matched `sqlite3.wasm` asset to its web assets and provide its
/// URL. [indexedDbName] is owned by the caller and is not inferred from the
/// collection location. Pass an opened [CollectionMediaStorage] to expose
/// Web media through the shared collection API.
Future<CollectionSqliteDriver> experimentalWebCollectionSqliteDriver({
  required String sqliteWasmUrl,
  required String indexedDbName,
  CollectionMediaStorage? mediaStorage,
}) async {
  final sqlite = await WasmSqlite3.loadFromUrlString(sqliteWasmUrl);
  final fileSystem = await IndexedDbFileSystem.open(
    dbName: indexedDbName,
    writeAutomatically: false,
  );
  sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);
  return CollectionSqliteDriver(
    openDatabase: (location) => sqlite.open(location, uri: true),
    flush: fileSystem.flush,
    mediaStorage: mediaStorage,
    snapshot: (database) async {
      final vfsName = 'anki-snapshot-${_snapshotVfsSerial++}';
      final snapshotVfs = InMemoryFileSystem(name: vfsName);
      sqlite.registerVirtualFileSystem(snapshotVfs);
      try {
        database.execute(
          "VACUUM INTO 'file:collection-snapshot.db?vfs=$vfsName'",
        );
        final data = snapshotVfs.fileData.values.single;
        if (data == null || data.isEmpty) {
          throw StateError('SQLite returned an empty Web snapshot');
        }
        return Uint8List.fromList(data);
      } finally {
        snapshotVfs.fileData.clear();
        sqlite.unregisterVirtualFileSystem(snapshotVfs);
      }
    },
  );
}
