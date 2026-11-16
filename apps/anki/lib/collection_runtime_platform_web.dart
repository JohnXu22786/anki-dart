/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_collection_sqlite/anki_collection_sqlite_web.dart';

import 'collection_runtime.dart';

const _webSqliteAsset = 'sqlite3.wasm';
const _webIndexedDbName = 'anki.collection.sqlite.v1';

Future<CollectionRuntime> createPlatformCollectionRuntime() async =>
    CollectionRuntime(
      locationForProfile: (profileId) async =>
          'profiles/${collectionProfileKey(profileId)}/collection.anki2',
      createDriver: () => experimentalWebCollectionSqliteDriver(
        sqliteWasmUrl: _webSqliteAsset,
        indexedDbName: _webIndexedDbName,
      ),
    );
