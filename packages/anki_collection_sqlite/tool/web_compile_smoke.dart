// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_web.dart';

Future<void> main() async {
  final driver = await experimentalWebCollectionSqliteDriver(
    sqliteWasmUrl: 'sqlite3.wasm',
    indexedDbName: 'anki-collection',
  );
  final database = await Future.sync(() => driver.openDatabase(':memory:'));
  final executor = CollectionSqliteSearchExecutor(database);
  await executor.queryIds('SELECT 1', const []);
  database.close();
}
