/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:io';

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'collection_runtime.dart';

Future<CollectionRuntime> createPlatformCollectionRuntime() async {
  final supportDirectory = await getApplicationSupportDirectory();
  final collectionsDirectory = Directory(
    path.join(supportDirectory.path, 'collections'),
  );
  await collectionsDirectory.create(recursive: true);
  return CollectionRuntime(
    locationForProfile: (profileId) async {
      final profileDirectory = Directory(
        path.join(collectionsDirectory.path, collectionProfileKey(profileId)),
      );
      await profileDirectory.create(recursive: true);
      return path.join(profileDirectory.path, 'collection.anki2');
    },
    createDriver: () async => nativeCollectionSqliteDriver(),
    optionsForProfile: (_) =>
        CollectionSqliteOptions(androidTempStore: Platform.isAndroid),
  );
}
