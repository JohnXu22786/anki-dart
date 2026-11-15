// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_native.dart';

void main() {
  final CollectionSqliteDriver driver = nativeCollectionSqliteDriver();
  assert(driver.flush == null);
}
