// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:sqlite3/wasm.dart';

import 'src/collection_sqlite_storage.dart';

/// Creates a Web SQLite driver backed by IndexedDB rather than memory-only
/// storage.
///
/// The sqlite3 WebAssembly and IndexedDB implementations are experimental and
/// do not guarantee crash durability. Applications requiring durable
/// collections must treat this driver as unsupported for that requirement or
/// supply a separately validated [CollectionSqliteDriver]. The host must copy
/// the version-matched `sqlite3.wasm` asset to its web assets and provide its
/// URL. [indexedDbName] is owned by the caller and is not inferred from the
/// collection location.
Future<CollectionSqliteDriver> experimentalWebCollectionSqliteDriver({
  required String sqliteWasmUrl,
  required String indexedDbName,
}) async {
  final sqlite = await WasmSqlite3.loadFromUrlString(sqliteWasmUrl);
  final fileSystem = await IndexedDbFileSystem.open(
    dbName: indexedDbName,
    writeAutomatically: false,
  );
  sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);
  return CollectionSqliteDriver(
    openDatabase: (location) => sqlite.open(location),
    flush: fileSystem.flush,
  );
}
