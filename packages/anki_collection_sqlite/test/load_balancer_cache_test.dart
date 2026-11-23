// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as protoDeck;
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
CREATE TABLE decks (
  id INTEGER PRIMARY KEY NOT NULL,
  name TEXT NOT NULL COLLATE NOCASE,
  mtime_secs INTEGER NOT NULL,
  usn INTEGER NOT NULL,
  common BLOB NOT NULL,
  kind BLOB NOT NULL
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

  test(
    'derives normal deck presets and groups history while skipping filtered decks',
    () async {
      final presetA = Int64(10);
      final presetB = Int64(20);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(presetA, 'A'),
      );
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(presetB, 'B'),
      );
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(Int64(30), 'Unused'),
      );
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, presetA));
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(8, presetA));
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(9, presetB));
      storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck(10));
      await storage.executeBatch('''
INSERT INTO cards (id, nid, due, did, queue) VALUES
  (1, 100, 10, 7, 0),
  (2, 100, 11, 8, 1),
  (3, 200, 11, 9, 2),
  (4, 300, 10, 10, 0),
  (5, 400, 10, 999, 0);
''');

      final cache = await storage.buildLoadBalancerCacheFromCollection(
        today: 10,
      );

      expect(cache.daysByPreset.keys, containsAll([presetA, presetB]));
      expect(cache.daysByPreset[presetA]![0].cardCount, 1);
      expect(cache.daysByPreset[presetA]![1].cardCount, 1);
      expect(cache.daysByPreset[presetA]![1].hasSibling(Int64(100)), isTrue);
      expect(cache.daysByPreset[presetB]![1].cardCount, 1);
      expect(cache.daysByPreset, isNot(contains(Int64(30))));
      expect(cache.daysByPreset, isNot(contains(Int64(0))));
      expect(
        cache.easyDaysByPreset.keys,
        containsAll([presetA, presetB, Int64(30)]),
      );
    },
  );

  test('normal deck with absent config stays mapped as in Core', () async {
    final missingPreset = Int64(99);
    storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, missingPreset));
    await storage.executeBatch('''
INSERT INTO cards (id, nid, due, did, queue) VALUES
  (1, 100, 10, 7, 0),
  (2, 200, 10, 999, 0);
''');

    final cache = await storage.buildLoadBalancerCacheFromCollection(today: 10);

    expect(cache.daysByPreset.keys, [missingPreset]);
    expect(cache.daysByPreset[missingPreset]![0].cardCount, 1);
    expect(cache.easyDaysByPreset, isEmpty);
  });

  test('empty decks and configs produce an empty cache', () async {
    final cache = await storage.buildLoadBalancerCacheFromCollection(today: 10);

    expect(cache.daysByPreset, isEmpty);
    expect(cache.easyDaysByPreset, isEmpty);
  });

  test(
    'current load-balancer context uses one injected timing snapshot',
    () async {
      const creationSecs = 1_700_000_000;
      final now = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      await storage.executeBatch('''
CREATE TABLE col (crt INTEGER NOT NULL, conf TEXT NOT NULL);
CREATE TABLE config (key TEXT PRIMARY KEY, usn INTEGER, mtime_secs INTEGER, val BLOB);
INSERT INTO col VALUES ($creationSecs, '{}');
''');
      final preset = Int64(10);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(preset, 'A'),
      );
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, preset));
      storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck(8));
      await storage.executeBatch('''
INSERT INTO cards (id, nid, due, did, queue) VALUES
  (1, 100, 12, 7, 0),
  (2, 200, 13, 7, 1),
  (3, 300, 12, 8, 0),
  (4, 400, 12, 99, 0);
''');

      final timing = storage.timingTodayForNow(now: now);
      final context = await storage.loadBalancerContextForNow(now: now);

      expect(context.daysElapsed, timing.daysElapsed);
      expect(context.nextDayAt, TimestampSecs(timing.nextDayAt));
      expect(context.cache.daysByPreset.keys, [preset]);
      expect(context.cache.daysByPreset[preset]![0].cardCount, 1);
      expect(context.cache.daysByPreset[preset]![1].cardCount, 1);
    },
  );

  test(
    'collection interval decision composes the selected cached context',
    () async {
      const creationSecs = 1_700_000_000;
      final now = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      await _prepareTimingCollection(storage, creationSecs);
      final preset = Int64(10);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(preset, 'A'),
      );
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, preset));
      await storage.executeBatch('''
INSERT INTO cards (id, nid, due, did, queue) VALUES
  (1, 100, 16, 7, 0);
''');

      final context = await storage.loadBalancerContextForNow(now: now);
      final result = await storage.findLoadBalancedIntervalForNow(
        deckConfigId: preset,
        noteId: Int64(100),
        interval: 5,
        minimum: 1,
        maximum: 20,
        fuzzSeed: BigInt.zero,
        now: now,
      );
      final expected = findLoadBalancedInterval(
        daysByPreset: context.cache.daysByPreset,
        easyDaysByPreset: context.cache.easyDaysByPreset,
        nextDayAt: context.nextDayAt,
        deckConfigId: preset,
        noteId: Int64(100),
        interval: 5,
        minimum: 1,
        maximum: 20,
        fuzzSeed: BigInt.zero,
      );

      expect(result, expected);
      expect(
        context.cache.daysByPreset[preset]![4].hasSibling(Int64(100)),
        isTrue,
      );
    },
  );

  test(
    'collection interval decision returns null for a missing preset',
    () async {
      const creationSecs = 1_700_000_000;
      final now = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      await _prepareTimingCollection(storage, creationSecs);
      final presentPreset = Int64(10);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(presentPreset, 'A'),
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        _normalDeck(7, presentPreset),
      );

      expect(
        await storage.findLoadBalancedIntervalForNow(
          deckConfigId: Int64(99),
          noteId: null,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.zero,
          now: now,
        ),
        isNull,
      );
    },
  );

  test(
    'collection interval decision forwards nullable note and seed',
    () async {
      const creationSecs = 1_700_000_000;
      final now = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      await _prepareTimingCollection(storage, creationSecs);
      final preset = Int64(10);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(preset, 'A'),
      );
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, preset));

      final context = await storage.loadBalancerContextForNow(now: now);
      expect(
        await storage.findLoadBalancedIntervalForNow(
          deckConfigId: preset,
          noteId: null,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.zero,
          now: now,
        ),
        findLoadBalancedInterval(
          daysByPreset: context.cache.daysByPreset,
          easyDaysByPreset: context.cache.easyDaysByPreset,
          nextDayAt: context.nextDayAt,
          deckConfigId: preset,
          noteId: null,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.zero,
        ),
      );
      expect(
        await storage.findLoadBalancedIntervalForNow(
          deckConfigId: preset,
          noteId: null,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: null,
          now: now,
        ),
        isNull,
      );
    },
  );

  test(
    'context resolver matches pure decisions across intervals and bounds',
    () async {
      const creationSecs = 1_700_000_000;
      final now = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      await _prepareTimingCollection(storage, creationSecs);
      final preset = Int64(10);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(preset, 'A'),
      );
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, preset));
      await storage.executeBatch('''
INSERT INTO cards (id, nid, due, did, queue) VALUES
  (1, 100, 13, 7, 0),
  (2, 100, 14, 7, 0),
  (3, 200, 15, 7, 0);
''');

      final context = await storage.loadBalancerContextForNow(now: now);
      final noteId = Int64(100);
      final fuzzSeed = BigInt.from(0x123456789abcdef0);
      final resolver = context.reviewIntervalResolver(
        deckConfigId: preset,
        noteId: noteId,
        fuzzSeed: fuzzSeed,
      );
      // The resolver is assignable directly to the existing scheduling hook.
      final schedulingContext = ReviewSchedulingContext(
        loadBalancedIntervalResolver: resolver,
      );

      for (final input in [
        (interval: 5.0, minimum: 1, maximum: 20),
        (interval: 9.0, minimum: 4, maximum: 30),
        (interval: 12.0, minimum: 10, maximum: 14),
      ]) {
        expect(
          schedulingContext.loadBalancedIntervalResolver!(
            input.interval,
            input.minimum,
            input.maximum,
          ),
          findLoadBalancedInterval(
            daysByPreset: context.cache.daysByPreset,
            easyDaysByPreset: context.cache.easyDaysByPreset,
            nextDayAt: context.nextDayAt,
            deckConfigId: preset,
            noteId: noteId,
            interval: input.interval,
            minimum: input.minimum,
            maximum: input.maximum,
            fuzzSeed: fuzzSeed,
          ),
        );
      }
    },
  );

  test(
    'context resolver returns the pure helper nullable results unchanged',
    () async {
      const creationSecs = 1_700_000_000;
      final now = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      await _prepareTimingCollection(storage, creationSecs);
      final preset = Int64(10);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(preset, 'A'),
      );
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, preset));
      await storage.executeBatch('''
INSERT INTO cards (id, nid, due, did, queue) VALUES
  (1, 100, 13, 7, 0);
''');
      final context = await storage.loadBalancerContextForNow(now: now);

      final missingPresetResolver = context.reviewIntervalResolver(
        deckConfigId: Int64(99),
        noteId: null,
        fuzzSeed: BigInt.zero,
      );
      final nullSeedResolver = context.reviewIntervalResolver(
        deckConfigId: preset,
        noteId: null,
        fuzzSeed: null,
      );
      final schedulingContext = ReviewSchedulingContext(
        loadBalancedIntervalResolver: missingPresetResolver,
      );

      expect(schedulingContext.loadBalancedIntervalResolver!(5, 1, 20), isNull);
      expect(nullSeedResolver(5, 1, 20), isNull);
    },
  );

  test(
    'context resolver keeps its original collection and timing snapshot',
    () async {
      const creationSecs = 1_700_000_000;
      final firstNow = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      final nextDayNow = firstNow.add(const Duration(days: 1));
      await _prepareTimingCollection(storage, creationSecs);
      final preset = Int64(10);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(preset, 'A'),
      );
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, preset));
      await storage.executeBatch('''
INSERT INTO cards (id, nid, due, did, queue) VALUES
  (1, 100, 13, 7, 0);
''');

      final originalContext = await storage.loadBalancerContextForNow(
        now: firstNow,
      );
      final resolver = originalContext.reviewIntervalResolver(
        deckConfigId: preset,
        noteId: Int64(100),
        fuzzSeed: BigInt.from(42),
      );
      final originalDecision = resolver(5, 1, 20);

      await storage.executeBatch('''
INSERT INTO cards (id, nid, due, did, queue) VALUES
  (2, 200, 13, 7, 0);
''');
      final changedContext = await storage.loadBalancerContextForNow(
        now: nextDayNow,
      );

      expect(changedContext.daysElapsed, originalContext.daysElapsed + 1);
      expect(changedContext.nextDayAt, greaterThan(originalContext.nextDayAt));
      expect(
        changedContext.cache.daysByPreset[preset]![0].cardCount,
        greaterThan(originalContext.cache.daysByPreset[preset]![0].cardCount),
      );
      expect(resolver(5, 1, 20), originalDecision);
      expect(
        resolver(5, 1, 20),
        findLoadBalancedInterval(
          daysByPreset: originalContext.cache.daysByPreset,
          easyDaysByPreset: originalContext.cache.easyDaysByPreset,
          nextDayAt: originalContext.nextDayAt,
          deckConfigId: preset,
          noteId: Int64(100),
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.from(42),
        ),
      );
    },
  );

  test(
    'injected now determines the collection day used for the decision',
    () async {
      const creationSecs = 1_700_000_000;
      final firstNow = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      final nextDayNow = firstNow.add(const Duration(days: 1));
      await _prepareTimingCollection(storage, creationSecs);
      final preset = Int64(10);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(preset, 'A'),
      );
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, preset));
      await storage.executeBatch('''
INSERT INTO cards (id, nid, due, did, queue) VALUES
  (1, 100, 13, 7, 0);
''');

      final firstContext = await storage.loadBalancerContextForNow(
        now: firstNow,
      );
      final nextDayContext = await storage.loadBalancerContextForNow(
        now: nextDayNow,
      );
      expect(nextDayContext.daysElapsed, firstContext.daysElapsed + 1);
      expect(nextDayContext.nextDayAt, greaterThan(firstContext.nextDayAt));
      expect(firstContext.cache.daysByPreset[preset]![1].cardCount, 1);
      expect(nextDayContext.cache.daysByPreset[preset]![0].cardCount, 1);
      expect(nextDayContext.cache.daysByPreset[preset]![1].cardCount, 0);

      final result = await storage.findLoadBalancedIntervalForNow(
        deckConfigId: preset,
        noteId: null,
        interval: 5,
        minimum: 1,
        maximum: 20,
        fuzzSeed: BigInt.zero,
        now: nextDayNow,
      );
      expect(
        result,
        findLoadBalancedInterval(
          daysByPreset: nextDayContext.cache.daysByPreset,
          easyDaysByPreset: nextDayContext.cache.easyDaysByPreset,
          nextDayAt: nextDayContext.nextDayAt,
          deckConfigId: preset,
          noteId: null,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.zero,
        ),
      );
    },
  );
}

Future<void> _prepareTimingCollection(
  CollectionSqliteStorage storage,
  int creationSecs,
) async {
  await storage.executeBatch('''
CREATE TABLE col (crt INTEGER NOT NULL, conf TEXT NOT NULL);
CREATE TABLE config (key TEXT PRIMARY KEY, usn INTEGER, mtime_secs INTEGER, val BLOB);
INSERT INTO col VALUES ($creationSecs, '{}');
''');
}

DeckConfig _config(Int64 id, String name) =>
    DeckConfig(id: id, name: name, inner: DeckConfig.defaults().inner);

Deck _normalDeck(int id, Int64 configId) => Deck(
  id: Int64(id),
  name: 'Deck $id',
  kind: NormalDeckKind(protoDeck.Deck_Normal(configId: configId)),
);

Deck _filteredDeck(int id) => Deck(
  id: Int64(id),
  name: 'Filtered $id',
  kind: FilteredDeckKind(protoDeck.Deck_Filtered()),
);
