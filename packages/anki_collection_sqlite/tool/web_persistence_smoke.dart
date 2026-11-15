// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_web.dart';
import 'package:web/web.dart' as web;

Future<void> main() async {
  try {
    final store = 'anki-sqlite-smoke-${DateTime.now().microsecondsSinceEpoch}';
    final driver = await experimentalWebCollectionSqliteDriver(
      sqliteWasmUrl: 'sqlite3.wasm',
      indexedDbName: store,
    );
    final first = await CollectionSqliteStorage.open(
      driver: driver,
      location: 'collection.sqlite',
    );
    await first.executeBatch(
      'create table smoke (id integer primary key, value text);'
      "insert into smoke values (1, 'persisted');",
    );
    await first.close();

    final reopened = await CollectionSqliteStorage.open(
      driver: driver,
      location: 'collection.sqlite',
    );
    final value = await reopened.queryString('select value from smoke');
    await reopened.close();
    web.document.body?.textContent = value == 'persisted'
        ? 'PASS'
        : 'FAIL: $value';
  } catch (error) {
    web.document.body?.textContent = 'FAIL: $error';
  }
}
