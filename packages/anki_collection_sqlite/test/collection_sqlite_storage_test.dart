// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:io';
import 'dart:convert';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as config_proto;
import 'package:anki_backend_protocol/anki/decks.pb.dart' as proto;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as notetype_proto;
import 'package:anki_collection_schema/anki_collection_schema.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
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

  test('source callbacks create localized defaults and reopen unchanged', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    var random = BigInt.zero;
    final migrations = _Callbacks(database);
    final callbacks = CollectionSqliteInitializationCallbacks(
      storage: database,
      text: _InitialText(),
      migrations: migrations,
      localMinutesWest: (_) => -480,
      randomU64: () {
        final value = random;
        random += BigInt.one;
        return value;
      },
      clock: () => DateTime.utc(2026, 5, 9, 12),
    );

    final result = await openOrCreateCollection(
      database,
      callbacks,
      serverMode: false,
    );

    expect(result.created, isTrue);
    expect(await database.queryInt('select ver from col'), 18);
    expect(
      await database.queryInt('select crt from col'),
      DateTime.utc(2026, 5, 8, 20).millisecondsSinceEpoch ~/ 1000,
    );
    expect(
      await database.queryInt('select scm from col'),
      DateTime.utc(2026, 5, 9, 12).millisecondsSinceEpoch,
    );
    final config = jsonDecode(
      await database.queryString('select conf from col'),
    );
    expect(config['activeDecks'], [1]);
    expect(config['creationOffset'], -480);
    expect(await database.queryString('select name from decks'), 'Default');
    expect(await database.queryInt('select id from deck_config'), 1);
    expect(
      await database.queryString('select name from deck_config'),
      'Default',
    );
    expect(
      await database.queryString('select hex(config) from deck_config'),
      DeckConfig.defaults().inner
          .writeToBuffer()
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase(),
    );
    expect(await database.queryInt('select count(*) from notetypes'), 6);
    expect(
      await database.queryString(
        "select group_concat(name, '|') from (select name from notetypes order by id)",
      ),
      'Basic|Basic (and reversed card)|Basic (optional reversed card)|Basic (type answer)|Cloze|Image Occlusion',
    );
    final basicConfig = notetype_proto.Notetype_Config.fromBuffer(
      _decodeHex(
        await database.queryString(
          "select hex(config) from notetypes where name = 'Basic'",
        ),
      ),
    );
    expect(
      basicConfig.reqs.single.kind,
      notetype_proto.Notetype_Config_CardRequirement_Kind.KIND_ANY,
    );
    expect(basicConfig.reqs.single.fieldOrds, [0]);
    final optionalConfig = notetype_proto.Notetype_Config.fromBuffer(
      _decodeHex(
        await database.queryString(
          "select hex(config) from notetypes where name = 'Basic (optional reversed card)'",
        ),
      ),
    );
    expect(optionalConfig.reqs.map((req) => req.kind), [
      notetype_proto.Notetype_Config_CardRequirement_Kind.KIND_ANY,
      notetype_proto.Notetype_Config_CardRequirement_Kind.KIND_ALL,
    ]);
    expect(optionalConfig.reqs[1].fieldOrds, [1, 2]);
    final stockRequirements = <String, List<String>>{
      'Basic': ['1:0'],
      'Basic (and reversed card)': ['1:0', '1:1'],
      'Basic (optional reversed card)': ['1:0', '2:1,2'],
      'Basic (type answer)': ['1:0,1'],
      'Cloze': ['1:0'],
      'Image Occlusion': ['1:0,1,2'],
    };
    for (final entry in stockRequirements.entries) {
      final stockConfig = notetype_proto.Notetype_Config.fromBuffer(
        _decodeHex(
          await database.queryString(
            "select hex(config) from notetypes where name = '${entry.key}'",
          ),
        ),
      );
      expect(
        stockConfig.reqs
            .map((req) => '${req.kind.value}:${req.fieldOrds.join(',')}')
            .toList(),
        entry.value,
        reason: entry.key,
      );
    }
    expect(
      await database.queryInt('select count(*) from fields'),
      greaterThan(6),
    );
    expect(
      await database.queryInt('select count(*) from templates'),
      greaterThan(6),
    );
    expect(await database.queryString('select key from config'), 'curModel');
    expect(
      await database.queryInt(
        'select cast(val as text) = cast((select id from notetypes order by id limit 1) as text) from config',
      ),
      1,
    );

    await database.close();
    final reopened = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    final reopenedResult = await openOrCreateCollection(
      reopened,
      callbacks,
      serverMode: false,
    );
    expect(reopenedResult.created, isFalse);
    expect(await reopened.queryInt('select count(*) from notetypes'), 6);
    await reopened.close();
  });

  test(
    'server creation omits the timezone offset and callback failure rolls back',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
        options: _schemaOptions,
      );
      final callbacks = CollectionSqliteInitializationCallbacks(
        storage: database,
        text: _InitialText(),
        migrations: _Callbacks(database),
        localMinutesWest: (_) => 300,
        randomU64: () => BigInt.one,
        clock: () => DateTime.utc(2026, 5, 9, 12),
      );
      await openOrCreateCollection(database, callbacks, serverMode: true);
      final config = jsonDecode(
        await database.queryString('select conf from col'),
      );
      expect(config['creationOffset'], isNull);
      await database.close();

      final failingPath = '$path.failure';
      final failingDatabase = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: failingPath,
        options: _schemaOptions,
      );
      final failingCallbacks = CollectionSqliteInitializationCallbacks(
        storage: failingDatabase,
        text: _InitialText(),
        migrations: _Callbacks(failingDatabase),
        localMinutesWest: (_) => 300,
        randomU64: () => throw StateError('random source failed'),
        clock: () => DateTime.utc(2026, 5, 9, 12),
      );
      await expectLater(
        openOrCreateCollection(
          failingDatabase,
          failingCallbacks,
          serverMode: true,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        await failingDatabase.queryInt(
          "select count(*) from sqlite_master where type = 'table' and name = 'col'",
        ),
        0,
      );
      await failingDatabase.close();
    },
  );

  test('exposes revlog row storage through an opened collection', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );
    final entry = RevlogEntry(
      id: RevlogId(Int64.parseInt('9007199254740993')),
      cardId: Int64.parseInt('9007199254740995'),
      usn: -1,
      buttonChosen: 3,
      interval: -60,
      lastInterval: 30,
      easeFactor: 2500,
      takenMillis: 1200,
      reviewKind: RevlogReviewKind.review,
    );

    expect(database.revlog.addRevlogEntry(entry), entry.id);
    final loaded = database.revlog.getRevlogEntry(entry.id)!;
    expect(loaded.id, entry.id);
    expect(loaded.cardId, entry.cardId);
    expect(loaded.interval, -60);
    expect(loaded.reviewKind, RevlogReviewKind.review);
    database.revlog.removeRevlogEntry(entry.id);
    expect(database.revlog.getRevlogEntry(entry.id), isNull);
    await database.close();
  });

  test(
    'registers Core field_at_index semantics on each collection connection',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );

      expect(
        await database.queryString(
          "SELECT field_at_index('first' || char(31) || '' || char(31) || 'third', 0)",
        ),
        'first',
      );
      expect(
        await database.queryString(
          "SELECT field_at_index('first' || char(31) || '' || char(31) || 'third', 1)",
        ),
        '',
      );
      expect(
        await database.queryString(
          "SELECT field_at_index('first' || char(31) || '' || char(31) || 'third', 2)",
        ),
        'third',
      );
      expect(
        await database.queryString(
          "SELECT process_text('Über {{c1::café::hint}}', 3)",
        ),
        'Uber cafe',
      );
      expect(
        await database.queryInt(
          "SELECT extract_original_position('{\"pos\":42}')",
        ),
        42,
      );
      expect(
        await database.queryString(
          "SELECT extract_custom_data('{\"cd\":\"{\\\"x\\\":true}\"}', 'x')",
        ),
        'true',
      );
      expect(
        await database.queryInt(
          "SELECT extract_fsrs_variable('{\"s\":1.25}', 's') = 1.25",
        ),
        1,
      );
      expect(
        await database.queryInt("SELECT regexp('needle', 'hay needle')"),
        1,
      );
      expect(
        await database.queryInt(
          r"SELECT regexp_fields('^c$', 'a' || char(31) || 'b' || char(31) || 'c', 2)",
        ),
        1,
      );
      expect(await database.queryInt(r"SELECT regexp_tags('^b$', 'a  b')"), 1);
      expect(
        await database.queryInt('SELECT fnvhash(1, 2)'),
        8581494755304202342,
      );
      expect(
        await database.queryString("SELECT field_at_index('only', 65535)"),
        '',
      );
      expect(
        await database.queryString("SELECT field_at_index('only', 1)"),
        '',
      );
      await expectLater(
        database.queryString("SELECT field_at_index('only', 65536)"),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        database.queryString('SELECT field_at_index(NULL, 0)'),
        throwsA(isA<SqliteException>()),
      );
      await database.close();

      final reopened = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );
      expect(
        await reopened.queryString(
          "SELECT field_at_index('first' || char(31) || 'second', 1)",
        ),
        'second',
      );
      expect(
        await reopened.queryString(
          "SELECT process_text('Über {{c1::café::hint}}', 3)",
        ),
        'Uber cafe',
      );
      expect(
        await reopened.queryInt(
          "SELECT extract_original_position('{\"pos\":42}')",
        ),
        42,
      );
      expect(
        await reopened.queryString(
          "SELECT extract_custom_data('{\"cd\":\"{\\\"x\\\":true}\"}', 'x')",
        ),
        'true',
      );
      expect(
        await reopened.queryInt(
          "SELECT extract_fsrs_variable('{\"s\":1.25}', 's') = 1.25",
        ),
        1,
      );
      expect(
        await reopened.queryInt("SELECT regexp('needle', 'hay needle')"),
        1,
      );
      expect(
        await reopened.queryInt('SELECT fnvhash(1, 2)'),
        8581494755304202342,
      );
      await reopened.close();
    },
  );

  test('deck storage persists rows through the collection connection', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );

    final added = database.decks.addDeck(
      Deck(
        name: 'Parent :: Child',
        mtimeSecs: Int64(123),
        usn: 4,
        common: proto.Deck_Common(studyCollapsed: true),
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(7))),
      ),
    );

    expect(added.id, isNot(Int64.ZERO));
    expect(database.decks.getDeck(added.id)!.name, 'Parent::Child');
    expect(database.decks.getDeckByName('parent\x1fchild')!.id, added.id);
    expect(database.decks.getDeckId('parent\x1fchild'), added.id);
    expect(
      database.decks.getDeck(added.id)!.toProto().normal.configId,
      Int64(7),
    );
    expect(
      database.decks.getAllDeckNames(),
      contains((added.id, 'Parent::Child')),
    );
    database.decks.db.execute(
      "UPDATE decks SET name = '  Parent' || char(31) || 'Child  ' WHERE id = ?",
      [added.id.toInt()],
    );
    expect(database.decks.getDeck(added.id)!.name, '  Parent::Child  ');
    database.decks.removeDeck(added.id);
    expect(database.decks.getDeck(added.id), isNull);

    final largeId = Int64.parseInt('9007199254740993');
    database.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: largeId,
        name: 'Large ID',
        mtimeSecs: Int64(456),
        usn: 5,
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(7))),
      ),
    );
    expect(database.decks.getDeck(largeId)!.id, largeId);
    await database.close();
  });

  test('deck hierarchy reads use the schema unicase name collation', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );

    final parent = database.decks.addDeck(
      Deck(
        name: 'Parent',
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(1))),
      ),
    );
    final childId = Int64.parseInt('9007199254740993');
    database.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: childId,
        name: 'parent::Child',
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(1))),
      ),
    );
    database.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: Int64.parseInt('9007199254740994'),
        name: 'PARENT::Child::Grandchild',
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(1))),
      ),
    );
    database.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: Int64.parseInt('9007199254740995'),
        name: 'Parentish::Outside',
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(1))),
      ),
    );

    expect(database.decks.childDecks(parent).map((deck) => deck.name), [
      'parent::Child',
      'PARENT::Child::Grandchild',
    ]);
    expect(database.decks.deckIdWithChildren(parent).toSet(), {
      parent.id,
      childId,
      Int64.parseInt('9007199254740994'),
    });
    expect(
      database.decks
          .deckWithChildren(parent.id)
          .map((deck) => deck.name)
          .toSet(),
      {'Parent', 'parent::Child', 'PARENT::Child::Grandchild'},
    );

    database.decks.db.execute(
      "UPDATE decks SET name = 'Parent  ' WHERE id = ?",
      [BigInt.parse(parent.id.toString())],
    );
    database.decks.db.execute(
      "UPDATE decks SET name = 'Parent  ' || char(31) || 'Child' WHERE id = ?",
      [BigInt.parse(childId.toString())],
    );
    final storedParent = database.decks.getDeck(parent.id)!;
    expect(
      database.decks.childDecks(storedParent).single.name,
      'Parent  ::Child',
    );
    expect(
      database.decks
          .deckWithChildren(parent.id)
          .map((deck) => deck.name)
          .toSet(),
      {'Parent  ', 'Parent  ::Child'},
    );
    await database.close();
  });

  test('deck config storage uses the collection connection', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );
    final id = Int64.parseInt('9007199254740993');
    final config = DeckConfig(
      id: id,
      name: 'Custom',
      mtimeSecs: Int64(123),
      usn: -2,
      inner: config_proto.DeckConfig_Config(newPerDay: 45, initialEase: 2.4),
    );

    database.deckConfigs.addOrUpdateDeckConfigWithExistingId(config);

    final loaded = database.deckConfigs.getDeckConfig(id)!;
    expect(loaded.name, 'Custom');
    expect(loaded.mtimeSecs, Int64(123));
    expect(loaded.usn, -2);
    expect(loaded.inner.newPerDay, 45);
    expect(loaded.inner.initialEase, closeTo(2.4, 0.000001));
    expect(database.deckConfigs.getDeckConfigIdByName('Custom'), id);
    expect(database.deckConfigs.getDeckConfigIdByName('custom'), id);
    expect(database.deckConfigs.getDeckConfigMap().keys, contains(id));
    await database.close();
  });

  test('tag storage uses schema unicase matching and sync state', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );
    await database.executeBatch('''
DROP TABLE tags;
CREATE TABLE tags (
  tag text NOT NULL PRIMARY KEY COLLATE unicase,
  usn integer NOT NULL,
  collapsed boolean NOT NULL,
  config blob NULL
) without rowid;''');
    database.tags.registerTag(Tag(name: 'TagName', usn: -1, expanded: true));

    expect(
      database.tags.getTag('TAGNAME'),
      Tag(name: 'TagName', usn: -1, expanded: true),
    );
    expect(database.tags.preferredTagCase('tagname'), 'TagName');
    expect(database.tags.expandedTags(), ['TagName']);
    expect(database.tags.tagsPendingSync(-1), ['TagName']);
    await database.close();
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

  test('quick check reports healthy databases as not corrupt', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
    );

    expect(await database.quickCheckCorrupt(), isFalse);

    await database.close();
  });

  test('quick check reports SQLite integrity findings as corruption', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
    );
    await database.executeBatch('''
      create table checked (value integer check (value > 0));
      pragma ignore_check_constraints = on;
      insert into checked values (-1);
      pragma ignore_check_constraints = off;
    ''');

    expect(await database.quickCheckCorrupt(), isTrue);

    await database.close();
  });

  test('checkpoint truncates WAL and flushes driver persistence', () async {
    var flushes = 0;
    final database = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (location) => sqlite3.open(location),
        flush: () => flushes++,
      ),
      location: path,
    );
    await database.executeBatch('create table checkpointed (id integer);');

    await database.checkpoint();

    expect(flushes, 3, reason: 'checkpoint awaits driver persistence');
    expect(await database.queryString('pragma journal_mode'), 'wal');
    await database.close();
  });

  test(
    'checkpoint rejects active transactions without committing them',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );
      await database.beginExclusive();
      await database.executeBatch(
        'create table still_transactional (id integer);',
      );

      await expectLater(database.checkpoint(), throwsStateError);

      await database.rollback();
      await database.close();
      final reopened = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );
      expect(
        await reopened.queryExists(
          "select null from sqlite_master where name = 'still_transactional'",
        ),
        isFalse,
      );
      await reopened.close();
    },
  );

  test(
    'optimize analyzes and leaves the file-backed database usable',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );
      await database.executeBatch('''
      create table optimized (id integer primary key, value text);
      create index optimized_value on optimized(value);
      insert into optimized(value) values ('first'), ('second'), ('third');
    ''');

      await database.optimize();

      expect(
        await database.queryInt('select count(*) from sqlite_stat1'),
        greaterThan(0),
      );
      expect(
        await database.queryString("select value from optimized where id = 2"),
        'second',
      );
      await database.close();
    },
  );

  test('close to schema 18 is a no-op', () async {
    final database = await _openLatestCollection(path);
    final callbacks = _Callbacks(database, calls: []);

    await database.close(desiredVersion: 18, callbacks: callbacks);

    final reopened = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    expect(await reopened.queryInt('select ver from col'), 18);
    expect(await reopened.queryString('pragma journal_mode'), 'wal');
    expect(callbacks.calls, isEmpty);
    await reopened.close();
  });

  test(
    'close to schema 11 applies catalog downgrade and journal mode',
    () async {
      final database = await _openLatestCollection(path);
      final callbackCalls = <String>[];
      final callbacks = _Callbacks(database, calls: callbackCalls);

      await database.close(desiredVersion: 11, callbacks: callbacks);

      expect(callbackCalls, [
        'downgradeDeckConfFrom16',
        'downgradeDecksFrom15',
        'downgradeNotetypesFrom15',
        'downgradeConfigFrom14',
        'downgradeTagsFrom14',
      ]);
      final reopened = sqlite3.open(path);
      expect(reopened.select('select ver from col').first['ver'], 11);
      expect(
        reopened.select('pragma journal_mode').first.columnAt(0),
        'delete',
      );
      reopened.close();
    },
  );

  test(
    'invalid close target closes resources but preserves the collection',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );
      await database.executeBatch('create table retained (id integer);');

      await expectLater(
        database.close(desiredVersion: 14),
        throwsArgumentError,
      );

      expect(await File(path).exists(), isTrue);
      final reopened = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );
      expect(await reopened.queryInt('select count(*) from retained'), 0);
      await reopened.close();
    },
  );

  test(
    'downgrade callback failure rolls back and still closes database',
    () async {
      final database = await _openLatestCollection(path);
      final failure = StateError('downgrade callback failed');
      final callbacks = _Callbacks(
        database,
        failure: failure,
        failureName: 'downgradeNotetypesFrom15',
      );

      await expectLater(
        database.close(desiredVersion: 11, callbacks: callbacks),
        throwsA(same(failure)),
      );

      expect(await File(path).exists(), isTrue);
      final reopened = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
        options: _schemaOptions,
      );
      expect(await reopened.queryInt('select ver from col'), 18);
      expect(await reopened.queryString('pragma journal_mode'), 'wal');
      await reopened.close();
    },
  );
}

Future<CollectionSqliteStorage> _openLatestCollection(String path) async {
  final database = await CollectionSqliteStorage.open(
    driver: _nativeDriver,
    location: path,
    options: _schemaOptions,
  );
  await openOrCreateCollection(
    database,
    _Callbacks(database),
    serverMode: true,
  );
  return database;
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
  _Callbacks(this.database, {this.failure, this.failureName, this.calls});

  final CollectionSqliteStorage database;
  final Object? failure;
  final String? failureName;
  final List<String>? calls;

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
  void run(String name, {bool? serverMode}) {
    calls?.add(name);
    if (name == failureName) throw failure!;
  }
}

final class _InitialText implements CollectionInitialTextProvider {
  @override
  String get defaultDeckName => 'Default';

  @override
  StockNotetypeNames get stockNotetypeNames => const StockNotetypeNames(
    basic: 'Basic',
    basicTyping: 'Basic (type answer)',
    basicReversed: 'Basic (and reversed card)',
    basicOptionalReversed: 'Basic (optional reversed card)',
    cloze: 'Cloze',
    frontField: 'Front',
    backField: 'Back',
    addReverseField: 'Add Reverse',
    textField: 'Text',
    backExtraField: 'Back Extra',
    commentsField: 'Comments',
    cardOne: 'Card 1',
    cardTwo: 'Card 2',
    imageOcclusion: 'Image Occlusion',
    occlusionsField: 'Occlusions',
    imageField: 'Image',
    headerField: 'Header',
    toggleMasks: 'Toggle Masks',
    errorLoadingImageOcclusion: 'Error loading Image Occlusion',
  );
}

List<int> _decodeHex(String value) => [
  for (var index = 0; index < value.length; index += 2)
    int.parse(value.substring(index, index + 2), radix: 16),
];
