// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite_web.dart';
import 'package:web/web.dart' as web;

Future<void> main() async {
  try {
    final driver = await experimentalWebCollectionSqliteDriver(
      sqliteWasmUrl: 'sqlite3.wasm',
      indexedDbName: 'anki-database-check-smoke',
    );
    final storage = await CollectionSqliteStorage.open(
      driver: driver,
      location: 'database-check.sqlite',
    );
    await storage.executeBatch('''
      CREATE TABLE col (crt INTEGER NOT NULL, conf TEXT NOT NULL, scm INTEGER NOT NULL);
      INSERT INTO col VALUES (0, '{}', 0);
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY, guid TEXT NOT NULL, mid INTEGER NOT NULL,
        mod INTEGER NOT NULL, usn INTEGER NOT NULL, tags TEXT NOT NULL,
        flds TEXT NOT NULL, sfld TEXT NOT NULL, csum INTEGER NOT NULL
      );
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY, nid INTEGER NOT NULL, did INTEGER NOT NULL,
        ord INTEGER NOT NULL, mod INTEGER NOT NULL, usn INTEGER NOT NULL,
        type INTEGER NOT NULL, queue INTEGER NOT NULL, due INTEGER NOT NULL,
        ivl INTEGER NOT NULL, factor INTEGER NOT NULL, reps INTEGER NOT NULL,
        lapses INTEGER NOT NULL, left INTEGER NOT NULL, odue INTEGER NOT NULL,
        odid INTEGER NOT NULL, flags INTEGER NOT NULL, data TEXT NOT NULL
      );
      CREATE TABLE revlog (
        id INTEGER PRIMARY KEY, cid INTEGER NOT NULL, usn INTEGER NOT NULL,
        ease INTEGER NOT NULL, ivl INTEGER NOT NULL, lastIvl INTEGER NOT NULL,
        factor INTEGER NOT NULL, time INTEGER NOT NULL, type INTEGER NOT NULL
      );
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY, name TEXT NOT NULL, mtime_secs INTEGER NOT NULL,
        usn INTEGER NOT NULL, common BLOB NOT NULL, kind BLOB NOT NULL
      );
      CREATE TABLE config (
        key TEXT PRIMARY KEY, usn INTEGER NOT NULL, mtime_secs INTEGER NOT NULL,
        val BLOB NOT NULL
      );
      CREATE TABLE notetypes (
        id INTEGER PRIMARY KEY, name TEXT NOT NULL, mtime_secs INTEGER NOT NULL,
        usn INTEGER NOT NULL, config BLOB NOT NULL
      );
      CREATE TABLE fields (
        ntid INTEGER NOT NULL, ord INTEGER NOT NULL, name TEXT NOT NULL,
        config BLOB NOT NULL
      );
      CREATE TABLE templates (
        ntid INTEGER NOT NULL, ord INTEGER NOT NULL, name TEXT NOT NULL,
        mtime_secs INTEGER NOT NULL, usn INTEGER NOT NULL, config BLOB NOT NULL
      );
      CREATE TABLE tags (
        tag TEXT COLLATE unicase PRIMARY KEY, usn INTEGER NOT NULL,
        collapsed INTEGER NOT NULL
      );
      INSERT INTO notes VALUES (1, 'a', 999, 0, 0, '', 'one', 'one', 1);
      INSERT INTO cards VALUES (10, 1, 1, 0, 0, 0, 0, 0, 1, 0, 2500, 0, 0, 0, 0, 0, 0, '{}');
      INSERT INTO cards VALUES (11, 999, 1, 0, 0, 0, 0, 0, 2, 0, 2500, 0, 0, 0, 0, 0, 0, '{}');
    ''');
    await storage.addInitialDeck('Default');
    final stages = <DatabaseCheckStage>[];
    final result = await storage.checkDatabase(
      onProgress: (progress) => stages.add(progress.stage),
    );
    final remaining = await storage.queryInt('SELECT count(*) FROM cards');
    await storage.close();
    if (result.orphanedCardsRemoved != 1 ||
        !result.isComplete ||
        result.notetypesRecovered != 1 ||
        remaining != 1 ||
        stages.where((stage) => stage == DatabaseCheckStage.notes).length !=
            2) {
      throw StateError('Web database check result mismatch');
    }
    web.document.body?.textContent = 'PASS';
  } catch (error) {
    web.document.body?.textContent = 'FAIL: $error';
  }
}
