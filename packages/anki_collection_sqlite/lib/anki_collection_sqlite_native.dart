// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/common.dart';

import 'src/collection_sqlite_storage.dart';
import 'src/portable_package_io.dart';

/// Flat, directory-backed Anki media storage for native application hosts.
final class DirectoryCollectionMediaStorage implements CollectionMediaStorage {
  const DirectoryCollectionMediaStorage(this.directory);

  final Directory directory;

  @override
  Future<Uint8List?> read(String filename) async {
    final name = validateAnkiMediaFilename(filename);
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      return null;
    }
    return file.readAsBytes();
  }

  @override
  Future<Iterable<String>> list() async {
    final names = <String>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (await FileSystemEntity.type(entity.path, followLinks: false) ==
          FileSystemEntityType.file) {
        names.add(entity.uri.pathSegments.last);
      }
    }
    return names;
  }
}

/// Builds a driver for native SQLite platforms using sqlite3's bundled SQLite.
CollectionSqliteDriver nativeCollectionSqliteDriver({
  Sqlite3? engine,
  CollectionMediaStorage? mediaStorage,
}) {
  final sqlite = engine ?? sqlite3;
  return CollectionSqliteDriver(
    openDatabase: (location) => sqlite.open(location),
    mediaStorage: mediaStorage,
    snapshot: (CommonDatabase database) async {
      final source = database as Database;
      final directory = await Directory.systemTemp.createTemp('anki-snapshot-');
      final path = '${directory.path}${Platform.pathSeparator}collection.db';
      Database? destination;
      try {
        destination = sqlite.open(path);
        await source.backup(destination).drain<void>();
        destination.close();
        destination = null;
        return await File(path).readAsBytes();
      } finally {
        destination?.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
