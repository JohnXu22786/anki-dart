// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CollectionSqliteStorage storage;

  setUp(() async {
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => sqlite3.openInMemory(),
      ),
      location: ':memory:',
    );
    await storage.executeBatch('''
CREATE TABLE cards (
  id INTEGER PRIMARY KEY, nid INTEGER, due INTEGER, did INTEGER, queue INTEGER
);
CREATE TABLE deck_config (
  id INTEGER PRIMARY KEY NOT NULL,
  name TEXT NOT NULL COLLATE NOCASE,
  mtime_secs INTEGER NOT NULL,
  usn INTEGER NOT NULL,
  config BLOB NOT NULL
);
''');
  });

  tearDown(() async => storage.close());

  test(
    'reads Core 99-day history and groups all queues by supplied preset',
    () async {
      final presetA = Int64(10);
      final presetB = Int64(20);
      final presetWithoutCards = Int64(30);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(presetA, 'A'),
      );
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(presetB, 'B'),
      );
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(presetWithoutCards, 'Unused'),
      );
      await storage.executeBatch('''
INSERT INTO cards (id, nid, due, did, queue) VALUES
  (1, 100, 10, 7, 0),
  (2, 100, 11, 8, 1),
  (3, 200, 108, 9, 2),
  (4, 300, 10, 7, 4),
  (5, 400, 109, 7, -2),
  (6, 500, 10, 999, -2);
''');

      final cache = await storage.buildLoadBalancerCache(
        today: 10,
        deckConfigByDeck: {
          Int64(7): presetA,
          Int64(8): presetA,
          Int64(9): presetB,
        },
      );

      expect(cache.daysByPreset.keys, containsAll([presetA, presetB]));
      expect(cache.daysByPreset, isNot(contains(presetWithoutCards)));
      expect(cache.daysByPreset[presetA]![0].cardCount, 2);
      expect(cache.daysByPreset[presetA]![1].cardCount, 1);
      expect(cache.daysByPreset[presetA]![1].hasSibling(Int64(100)), isTrue);
      expect(cache.daysByPreset[presetA]![98].cardCount, 0);
      expect(cache.daysByPreset[presetB]![98].cardCount, 1);
      expect(
        cache.easyDaysByPreset.keys,
        containsAll([presetA, presetB, presetWithoutCards]),
      );
    },
  );

  test('empty history still returns stored presets easy-day values', () async {
    final preset = Int64(10);
    storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
      _config(preset, 'A'),
    );

    final cache = await storage.buildLoadBalancerCache(
      today: 10,
      deckConfigByDeck: {Int64(7): preset},
    );

    expect(cache.daysByPreset, isEmpty);
    expect(cache.easyDaysByPreset[preset], hasLength(7));
  });
}

DeckConfig _config(Int64 id, String name) =>
    DeckConfig(id: id, name: name, inner: DeckConfig.defaults().inner);
