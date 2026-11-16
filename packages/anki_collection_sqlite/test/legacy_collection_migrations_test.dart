// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:convert';
import 'dart:io';

import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as deckconfig;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as notetype;
import 'package:anki_collection_schema/anki_collection_schema.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late String path;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('anki-migrations-');
    path = '${directory.path}/collection.anki2';
  });

  tearDown(() async => directory.delete(recursive: true));

  test(
    'runs each legacy callback in source order and round trips user values',
    () async {
      final (storage, database) = await _open(path);
      final fixture =
          jsonDecode(
                await File(
                  'test/fixtures/legacy/schema11_collection_values.json',
                ).readAsString(),
              )
              as Map<String, Object?>;
      await storage.executeBatch(collectionSchema11Sql);
      database.execute('UPDATE col SET ver = 11');
      database.execute(
        'UPDATE col SET conf = ?, dconf = ?, decks = ?, models = ?, tags = ?, usn = 42',
        [
          jsonEncode(fixture['conf']),
          jsonEncode(fixture['dconf']),
          jsonEncode(fixture['decks']),
          jsonEncode(fixture['models']),
          jsonEncode(fixture['tags']),
        ],
      );
      database.execute('''
        INSERT INTO cards (
          id, nid, did, ord, mod, usn, type, queue, due, ivl, factor,
          reps, lapses, left, odue, odid, flags, data
        ) VALUES (300, 200, 1, 0, 10, 8, 2, 2, 4, 5, 1800, 3, 1, 0, 0, 0, 0, '')
      ''');

      final callbacks = _migrations(storage);
      await storage.beginExclusive();
      await executeCollectionSchemaUpgradesInTransaction(
        storage,
        callbacks,
        fromVersion: 11,
        serverMode: false,
      );
      await storage.commit();

      expect(await storage.queryInt('SELECT ver FROM col'), 18);
      expect(
        await storage.queryInt('SELECT factor FROM cards WHERE id = 300'),
        2500,
      );
      expect(
        await storage.queryInt('SELECT usn FROM cards WHERE id = 300'),
        -1,
      );
      expect(
        database
            .select('SELECT name, mtime_secs, usn FROM decks WHERE id = 2')
            .single
            .columnAt(0),
        'default_',
      );
      expect(
        database
            .select('SELECT mtime_secs FROM decks WHERE id = 2')
            .single
            .columnAt(0),
        DateTime.utc(2026, 1, 2).millisecondsSinceEpoch ~/ 1000,
      );
      expect(
        database
            .select('SELECT usn FROM decks WHERE id = 2')
            .single
            .columnAt(0),
        -1,
      );
      expect(
        database
            .select('SELECT tag FROM tags ORDER BY tag')
            .map((row) => row.columnAt(0))
            .toList(),
        ['alpha', 'beta'],
      );
      expect(
        database
            .select('SELECT tag, collapsed FROM tags ORDER BY tag')
            .map((row) => [row.columnAt(0), row.columnAt(1)])
            .toList(),
        [
          ['alpha', 1],
          ['beta', 1],
        ],
      );
      final configValue =
          database
                  .select('SELECT val FROM config WHERE key = ?', [
                    'customConfig',
                  ])
                  .single
                  .columnAt(0)
              as List<int>;
      expect(jsonDecode(utf8.decode(configValue)), {'preserve': true});
      final cardConfig = deckconfig.DeckConfig_Config.fromBuffer(
        database
                .select('SELECT config FROM deck_config WHERE id = 1')
                .single
                .columnAt(0)
            as List<int>,
      );
      expect(cardConfig.initialEase, 2.5);
      expect(cardConfig.other, isNotEmpty);
      expect(
        jsonDecode(utf8.decode(cardConfig.other))['new']['customNew'],
        'keep',
      );
      final higherEase = deckconfig.DeckConfig_Config.fromBuffer(
        database
                .select('SELECT config FROM deck_config WHERE id = 2')
                .single
                .columnAt(0)
            as List<int>,
      );
      expect(higherEase.initialEase, 3);
      final migratedDeck = storage.decks.getAllDecks().singleWhere(
        (deck) => deck.id.toInt() == 1,
      );
      expect(migratedDeck.common.lastDayStudied, 4);
      expect(migratedDeck.common.learningStudied, 0);
      final storedNotetype = notetype.Notetype_Config.fromBuffer(
        database
                .select('SELECT config FROM notetypes WHERE id = 100')
                .single
                .columnAt(0)
            as List<int>,
      );
      expect(
        jsonDecode(utf8.decode(storedNotetype.other))['userNotetypeValue'],
        'keep',
      );
      expect(
        jsonDecode(
          utf8.decode(
            notetype.Notetype_Field_Config.fromBuffer(
              database
                      .select(
                        'SELECT config FROM fields WHERE ntid = 100 AND ord = 0',
                      )
                      .single
                      .columnAt(0)
                  as List<int>,
            ).other,
          ),
        )['userFieldValue'],
        'keep',
      );
      expect(
        jsonDecode(
          utf8.decode(
            notetype.Notetype_Template_Config.fromBuffer(
              database
                      .select(
                        'SELECT config FROM templates WHERE ntid = 100 AND ord = 0',
                      )
                      .single
                      .columnAt(0)
                  as List<int>,
            ).other,
          ),
        )['userTemplateValue'],
        'keep',
      );

      await downgradeCollectionSchema(storage, callbacks, toVersion: 11);
      expect(await storage.queryInt('SELECT ver FROM col'), 11);
      final roundTrip = database
          .select('SELECT conf, dconf, decks, models, tags FROM col')
          .single;
      final config =
          jsonDecode(roundTrip.columnAt(0) as String) as Map<String, Object?>;
      final deckConfig =
          jsonDecode(roundTrip.columnAt(1) as String) as Map<String, Object?>;
      final decks =
          jsonDecode(roundTrip.columnAt(2) as String) as Map<String, Object?>;
      final notetypes =
          jsonDecode(roundTrip.columnAt(3) as String) as Map<String, Object?>;
      final tags =
          jsonDecode(roundTrip.columnAt(4) as String) as Map<String, Object?>;
      final legacyDeckConfig = deckConfig['1'] as Map<String, Object?>;
      final legacyDeck = decks['1'] as Map<String, Object?>;
      final legacyNotetype = notetypes['100'] as Map<String, Object?>;
      expect(config['customConfig'], {'preserve': true});
      expect(legacyDeckConfig['customTop'], {'keep': 42});
      expect(
        (legacyDeckConfig['new'] as Map<String, Object?>)['customNew'],
        'keep',
      );
      expect(
        ((deckConfig['2'] as Map<String, Object?>)['new']
            as Map<String, Object?>)['initialFactor'],
        3000,
      );
      expect(legacyDeck['userDeckValue'], 'keep');
      expect(legacyDeck['id'], isA<int>());
      expect(legacyDeck['mod'], isA<int>());
      expect(legacyDeck['conf'], isA<int>());
      expect(legacyDeck['revToday'], [4, 5]);
      expect(legacyDeck['lrnToday'], [4, 0]);
      expect(legacyNotetype['userNotetypeValue'], 'keep');
      expect((legacyNotetype['flds'] as List).first['userFieldValue'], 'keep');
      expect(
        (legacyNotetype['tmpls'] as List).first['userTemplateValue'],
        'keep',
      );
      expect(tags, {'alpha': 5, 'beta': -1});
      await storage.close();
    },
  );

  test(
    'rolls back all earlier callback writes when a later callback fails',
    () async {
      final (storage, database) = await _open(path);
      await storage.executeBatch(collectionSchema11Sql);
      database.execute('UPDATE col SET ver = 11');
      database.execute("UPDATE col SET conf = '['");

      await expectLater(
        upgradeCollectionSchemaToLatest(
          storage,
          _migrations(storage),
          fromVersion: 11,
          serverMode: false,
        ),
        throwsFormatException,
      );
      expect(await storage.queryInt('SELECT ver FROM col'), 11);
      expect(database.select('SELECT conf FROM col').single.columnAt(0), '[');
      expect(
        await storage.queryInt(
          "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = 'config'",
        ),
        0,
      );
      await storage.close();
    },
  );
}

Future<(CollectionSqliteStorage, CommonDatabase)> _open(String path) async {
  late CommonDatabase database;
  final storage = await CollectionSqliteStorage.open(
    driver: CollectionSqliteDriver(
      openDatabase: (location) => database = sqlite3.open(location),
    ),
    location: path,
    options: const CollectionSqliteOptions(),
  );
  return (storage, database);
}

CollectionSqliteMigrationCallbacks _migrations(
  CollectionSqliteStorage storage,
) => CollectionSqliteMigrationCallbacks(
  storage: storage,
  randomU64: () => BigInt.from(123456),
  clock: () => DateTime.utc(2026, 1, 2),
);
