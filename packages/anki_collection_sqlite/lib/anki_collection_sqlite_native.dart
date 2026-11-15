// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:sqlite3/sqlite3.dart';

import 'src/collection_sqlite_storage.dart';

/// Builds a driver for native SQLite platforms using sqlite3's bundled SQLite.
CollectionSqliteDriver nativeCollectionSqliteDriver({Sqlite3? engine}) {
  final sqlite = engine ?? sqlite3;
  return CollectionSqliteDriver(
    openDatabase: (location) => sqlite.open(location),
  );
}
