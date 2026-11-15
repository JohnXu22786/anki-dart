// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:io';

import 'package:anki_collection_schema/anki_collection_schema.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late String path;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('anki-collection-');
    path = '${directory.path}/collection.anki2';
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('creates schema 11 and current-schema reopen is a no-op', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    final result = await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );

    expect(result, const CollectionOpenResult(created: true, upgraded: true));
    expect(await database.queryInt('select ver from col'), 18);
    expect(await database.queryInt('pragma page_size'), 4096);
    expect(await database.queryInt('pragma busy_timeout'), 0);
    expect(await database.queryString('pragma locking_mode'), 'exclusive');
    expect(await database.queryInt('pragma cache_size'), -40960);
    expect(await database.queryString('pragma journal_mode'), 'wal');
    await database.close();

    final reopened = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    expect(
      await openOrCreateCollection(
        reopened,
        _Callbacks(reopened),
        serverMode: true,
      ),
      const CollectionOpenResult(created: false, upgraded: false),
    );
    expect(await reopened.queryInt('select count(*) from col'), 1);
    await reopened.close();
  });

  test('upgrades supported schema 14 fixture using the real database', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await database.executeBatch(collectionSchema11Sql);
    await database.executeBatch(
      collectionSchemaSqlByPath['rslib/src/storage/upgrades/schema14_upgrade.sql']!,
    );
    await database.close();

    final reopened = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    final result = await openOrCreateCollection(
      reopened,
      _Callbacks(reopened),
      serverMode: true,
    );
    expect(result, const CollectionOpenResult(created: false, upgraded: true));
    expect(await reopened.queryInt('select ver from col'), 18);
    await reopened.close();
  });

  test(
    'integrity check reads SQLite result and propagates corruption result',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
        options: _schemaOptions,
      );
      final callbacks = _Callbacks(database);
      await openOrCreateCollection(database, callbacks, serverMode: true);
      expect(
        await openOrCreateCollection(
          database,
          callbacks,
          serverMode: true,
          checkIntegrity: true,
        ),
        const CollectionOpenResult(created: false, upgraded: false),
      );
      await database.executeBatch('''
      create table checked (value integer check (value > 0));
      pragma ignore_check_constraints = on;
      insert into checked values (-1);
      pragma ignore_check_constraints = off;
    ''');
      await expectLater(
        openOrCreateCollection(
          database,
          callbacks,
          serverMode: true,
          checkIntegrity: true,
        ),
        throwsA(isA<CollectionIntegrityException>()),
      );
      await database.close();
    },
  );

  test(
    'callback failure rolls back schema creation and preserves exception',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
        options: _schemaOptions,
      );
      final failure = StateError('metadata failed');
      await expectLater(
        openOrCreateCollection(
          database,
          _Callbacks(database, failure: failure),
          serverMode: true,
        ),
        throwsA(same(failure)),
      );
      expect(
        await database.queryExists(
          "select null from sqlite_master where type='table' and name='col'",
        ),
        isFalse,
      );
      await database.close();
    },
  );

  test('close is idempotent and does not remove the collection file', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
    );
    await database.executeBatch('create table retained (id integer);');
    await database.close();
    await database.close();

    expect(await File(path).exists(), isTrue);
    final reopened = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
    );
    expect(await reopened.queryInt('select count(*) from retained'), 0);
    await reopened.close();
  });

  test('driver persistence is awaited after a committed write', () async {
    var flushes = 0;
    final driver = CollectionSqliteDriver(
      openDatabase: (location) => sqlite3.open(location),
      flush: () => flushes++,
    );
    final database = await CollectionSqliteStorage.open(
      driver: driver,
      location: path,
    );
    expect(flushes, 1, reason: 'connection pragmas are persisted');
    await database.commit();
    await database.rollback();
    expect(flushes, 1, reason: 'idle transaction controls are no-ops');

    await database.beginExclusive();
    await database.executeBatch('create table persisted (id integer);');
    expect(flushes, 1, reason: 'transaction writes wait for commit');
    await database.commit();
    expect(flushes, 2, reason: 'commit flushes platform storage');
    await database.beginExclusive();
    await database.executeBatch("insert into persisted values (1);");
    await database.commit();
    expect(
      flushes,
      3,
      reason: 'cached begin and commit statements are reusable',
    );
    await database.close();
    expect(flushes, 4, reason: 'close flushes platform storage');
  });

  test('Android temporary storage option selects memory', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: const CollectionSqliteOptions(androidTempStore: true),
    );
    expect(await database.queryInt('pragma temp_store'), 2);
    await database.close();
  });
}

final CollectionSqliteDriver _nativeDriver = CollectionSqliteDriver(
  openDatabase: (location) => sqlite3.open(location),
);

final CollectionSqliteOptions _schemaOptions = CollectionSqliteOptions(
  configureConnection: (database) => database.createCollation(
    name: 'unicase',
    function: (left, right) =>
        (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase()),
  ),
);

final class _Callbacks implements CollectionOpenCallbacks {
  _Callbacks(this.database, {this.failure});

  final CollectionSqliteStorage database;
  final Object? failure;

  @override
  void initializeCollectionMetadata({required bool serverMode}) {
    if (failure != null) throw failure!;
    database.executeBatch('update col set crt=1, scm=1, ver=11, conf=\'{}\'');
  }

  @override
  void addDefaultDeckConfig() {}

  @override
  void addDefaultDeck() {}

  @override
  void addStockNoteTypes() {}

  @override
  void run(String name, {bool? serverMode}) {}
}
