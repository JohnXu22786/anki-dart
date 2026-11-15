// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_collection_sqlite/anki_collection_sqlite_web.dart';

Future<void> main() async {
  await experimentalWebCollectionSqliteDriver(
    sqliteWasmUrl: 'sqlite3.wasm',
    indexedDbName: 'anki-collection',
  );
}
