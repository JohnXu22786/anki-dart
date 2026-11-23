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
  id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER, mod INTEGER,
  usn INTEGER, type INTEGER, queue INTEGER, due INTEGER, ivl INTEGER,
  factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER, odue INTEGER,
  odid INTEGER, flags INTEGER, data TEXT
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
    'current review state clamps future due and preserves stored review data',
    () async {
      const creationSecs = 1_700_000_000;
      final now = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      await _prepareTimingCollection(storage, creationSecs);
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, Int64(10)));
      await _insertReviewContextCard(
        storage,
        cardId: 1,
        noteId: Int64(100),
        deckId: 7,
        due: 40,
        interval: 30,
        factor: 2450,
        lapses: 6,
        data: '{"s":3.25,"d":4.5}',
      );

      final state = await storage.currentReviewCardStateForNow(
        cardId: Int64(1),
        now: now,
      );

      expect(state.scheduledDays, 30);
      expect(state.elapsedDays, 30);
      expect(state.easeFactor, closeTo(2.45, 1e-6));
      expect(state.lapses, 6);
      expect(state.memoryState!.stability, 3.25);
      expect(state.memoryState!.difficulty, 4.5);
    },
  );

  test(
    'current review state uses overdue days from the injected timing',
    () async {
      const creationSecs = 1_700_000_000;
      final now = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      await _prepareTimingCollection(storage, creationSecs);
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, Int64(10)));
      await _insertReviewContextCard(
        storage,
        cardId: 1,
        noteId: Int64(100),
        deckId: 7,
        due: 7,
        interval: 30,
      );

      final state = await storage.currentReviewCardStateForNow(
        cardId: Int64(1),
        now: now,
      );

      expect(state.scheduledDays, 30);
      expect(state.elapsedDays, 35);
    },
  );

  test('current review state rejects missing cards and decks', () async {
    const creationSecs = 1_700_000_000;
    final now = DateTime.fromMillisecondsSinceEpoch(
      (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
      isUtc: true,
    );
    await _prepareTimingCollection(storage, creationSecs);
    await _insertReviewContextCard(
      storage,
      cardId: 1,
      noteId: Int64(100),
      deckId: 7,
    );

    await expectLater(
      storage.currentReviewCardStateForNow(cardId: Int64(999), now: now),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('card not found'),
        ),
      ),
    );
    await expectLater(
      storage.currentReviewCardStateForNow(cardId: Int64(1), now: now),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('deck not found'),
        ),
      ),
    );
  });

  test(
    'current review state rejects filtered decks and non-review cards',
    () async {
      const creationSecs = 1_700_000_000;
      final now = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      await _prepareTimingCollection(storage, creationSecs);
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, Int64(10)));
      storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck(8));
      await _insertReviewContextCard(
        storage,
        cardId: 1,
        noteId: Int64(100),
        deckId: 8,
      );
      await _insertReviewContextCard(
        storage,
        cardId: 2,
        noteId: Int64(200),
        deckId: 7,
        ctype: 0,
      );

      await expectLater(
        storage.currentReviewCardStateForNow(cardId: Int64(1), now: now),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('filtered deck'),
          ),
        ),
      );
      await expectLater(
        storage.currentReviewCardStateForNow(cardId: Int64(2), now: now),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('not a review card'),
          ),
        ),
      );
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
    'review scheduling context uses one injected collection snapshot',
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
      const base = ReviewSchedulingContext(
        hardMultiplier: 1.4,
        easyMultiplier: 1.6,
        intervalMultiplier: 1.1,
        maximumReviewInterval: 300,
        leechThreshold: 10,
        lapseMultiplier: 0.25,
        minimumLapseInterval: 2,
        fuzzFactor: 0.31,
        fsrsParams: [0.1, 0.2],
        fsrsDesiredRetention: 0.9,
        fsrsAllowShortTerm: true,
        learningStepsMinutes: [1, 10],
      );
      final noteId = Int64(100);
      final fuzzSeed = BigInt.from(0x123456789abcdef0);

      final assembled = await storage
          .reviewSchedulingContextWithLoadBalancerForNow(
            baseContext: base,
            deckConfigId: preset,
            noteId: noteId,
            fuzzSeed: fuzzSeed,
            now: now,
          );

      expect(assembled.hardMultiplier, base.hardMultiplier);
      expect(assembled.easyMultiplier, base.easyMultiplier);
      expect(assembled.intervalMultiplier, base.intervalMultiplier);
      expect(assembled.maximumReviewInterval, base.maximumReviewInterval);
      expect(assembled.leechThreshold, base.leechThreshold);
      expect(assembled.lapseMultiplier, base.lapseMultiplier);
      expect(assembled.minimumLapseInterval, base.minimumLapseInterval);
      expect(assembled.fuzzFactor, base.fuzzFactor);
      expect(assembled.fsrsParams, same(base.fsrsParams));
      expect(assembled.fsrsDesiredRetention, base.fsrsDesiredRetention);
      expect(assembled.fsrsAllowShortTerm, base.fsrsAllowShortTerm);
      expect(assembled.learningStepsMinutes, same(base.learningStepsMinutes));

      final expectedContext = await storage.loadBalancerContextForNow(now: now);
      for (final input in [
        (interval: 5.0, minimum: 1, maximum: 20),
        (interval: 9.0, minimum: 4, maximum: 30),
        (interval: 12.0, minimum: 10, maximum: 14),
      ]) {
        expect(
          assembled.loadBalancedIntervalResolver!(
            input.interval,
            input.minimum,
            input.maximum,
          ),
          findLoadBalancedInterval(
            daysByPreset: expectedContext.cache.daysByPreset,
            easyDaysByPreset: expectedContext.cache.easyDaysByPreset,
            nextDayAt: expectedContext.nextDayAt,
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
    'disabled load balancing returns base without looking up the card',
    () async {
      const base = ReviewSchedulingContext(hardMultiplier: 1.4);

      final result = await storage
          .reviewSchedulingContextWithCardLoadBalancerForNow(
            baseContext: base,
            cardId: Int64(999),
            loadBalancerEnabled: false,
            fuzzSeed: null,
          );

      expect(result, same(base));
    },
  );

  test(
    'normal home deck supplies note only when bury reviews is enabled',
    () async {
      const creationSecs = 1_700_000_000;
      final now = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      await _prepareTimingCollection(storage, creationSecs);
      final preset = Int64(10);
      final noteId = Int64(100);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(preset, 'A', buryReviews: true),
      );
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, preset));
      await _insertReviewContextCard(
        storage,
        cardId: 1,
        noteId: noteId,
        deckId: 7,
      );
      await _insertReviewContextCard(
        storage,
        cardId: 2,
        noteId: noteId,
        deckId: 7,
        due: 14,
      );
      await _insertReviewContextCard(
        storage,
        cardId: 3,
        noteId: Int64(200),
        deckId: 7,
        due: 15,
      );

      final buried = await storage
          .reviewSchedulingContextWithCardLoadBalancerForNow(
            baseContext: const ReviewSchedulingContext(intervalMultiplier: 1.2),
            cardId: Int64(1),
            loadBalancerEnabled: true,
            fuzzSeed: BigInt.from(42),
            now: now,
          );
      final context = await storage.loadBalancerContextForNow(now: now);
      expect(
        buried.loadBalancedIntervalResolver!(5, 1, 20),
        findLoadBalancedInterval(
          daysByPreset: context.cache.daysByPreset,
          easyDaysByPreset: context.cache.easyDaysByPreset,
          nextDayAt: context.nextDayAt,
          deckConfigId: preset,
          noteId: noteId,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.from(42),
        ),
      );

      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(preset, 'A', buryReviews: false),
      );
      final notBuried = await storage
          .reviewSchedulingContextWithCardLoadBalancerForNow(
            baseContext: const ReviewSchedulingContext(intervalMultiplier: 1.2),
            cardId: Int64(1),
            loadBalancerEnabled: true,
            fuzzSeed: BigInt.from(42),
            now: now,
          );
      final updatedContext = await storage.loadBalancerContextForNow(now: now);
      expect(
        notBuried.loadBalancedIntervalResolver!(5, 1, 20),
        findLoadBalancedInterval(
          daysByPreset: updatedContext.cache.daysByPreset,
          easyDaysByPreset: updatedContext.cache.easyDaysByPreset,
          nextDayAt: updatedContext.nextDayAt,
          deckConfigId: preset,
          noteId: null,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.from(42),
        ),
      );
      expect(notBuried.intervalMultiplier, 1.2);
    },
  );

  test('filtered card uses original home deck config', () async {
    const creationSecs = 1_700_000_000;
    final now = DateTime.fromMillisecondsSinceEpoch(
      (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
      isUtc: true,
    );
    await _prepareTimingCollection(storage, creationSecs);
    final preset = Int64(10);
    final noteId = Int64(100);
    storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
      _config(preset, 'Home', buryReviews: true),
    );
    storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, preset));
    storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck(8));
    await _insertReviewContextCard(
      storage,
      cardId: 1,
      noteId: noteId,
      deckId: 8,
      originalDeckId: 7,
    );
    await _insertReviewContextCard(
      storage,
      cardId: 2,
      noteId: noteId,
      deckId: 7,
      due: 14,
    );

    final assembled = await storage
        .reviewSchedulingContextWithCardLoadBalancerForNow(
          baseContext: const ReviewSchedulingContext(),
          cardId: Int64(1),
          loadBalancerEnabled: true,
          fuzzSeed: BigInt.from(24),
          now: now,
        );
    final context = await storage.loadBalancerContextForNow(now: now);
    expect(
      assembled.loadBalancedIntervalResolver!(5, 1, 20),
      findLoadBalancedInterval(
        daysByPreset: context.cache.daysByPreset,
        easyDaysByPreset: context.cache.easyDaysByPreset,
        nextDayAt: context.nextDayAt,
        deckConfigId: preset,
        noteId: noteId,
        interval: 5,
        minimum: 1,
        maximum: 20,
        fuzzSeed: BigInt.from(24),
      ),
    );
  });

  test(
    'filtered card without original deck leaves base context unchanged',
    () async {
      final preset = Int64(10);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(preset, 'A'),
      );
      storage.decks.addOrUpdateDeckWithExistingId(_filteredDeck(8));
      await _insertReviewContextCard(
        storage,
        cardId: 1,
        noteId: Int64(100),
        deckId: 8,
      );
      const base = ReviewSchedulingContext(fuzzFactor: 0.25);

      final result = await storage
          .reviewSchedulingContextWithCardLoadBalancerForNow(
            baseContext: base,
            cardId: Int64(1),
            loadBalancerEnabled: true,
            fuzzSeed: BigInt.from(24),
          );

      expect(result, same(base));
    },
  );

  test(
    'missing config row keeps home config ID and supplies no sibling note',
    () async {
      const creationSecs = 1_700_000_000;
      final now = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
        isUtc: true,
      );
      await _prepareTimingCollection(storage, creationSecs);
      final missingPreset = Int64(99);
      storage.decks.addOrUpdateDeckWithExistingId(
        _normalDeck(7, missingPreset),
      );
      await _insertReviewContextCard(
        storage,
        cardId: 1,
        noteId: Int64(100),
        deckId: 7,
      );

      final result = await storage
          .reviewSchedulingContextWithCardLoadBalancerForNow(
            baseContext: const ReviewSchedulingContext(),
            cardId: Int64(1),
            loadBalancerEnabled: true,
            fuzzSeed: BigInt.from(24),
            now: now,
          );

      expect(result.loadBalancedIntervalResolver, isNotNull);
      expect(result.loadBalancedIntervalResolver!(5, 1, 20), isNull);
    },
  );

  test('missing card throws not-found before context assembly', () async {
    await expectLater(
      storage.reviewSchedulingContextWithCardLoadBalancerForNow(
        baseContext: const ReviewSchedulingContext(),
        cardId: Int64(999),
        loadBalancerEnabled: true,
        fuzzSeed: null,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'card not found: 999',
        ),
      ),
    );
  });

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

  group('reviewCardSchedulingStatesWithCardLoadBalancerForNow', () {
    const creationSecs = 1_700_000_000;
    final now = DateTime.fromMillisecondsSinceEpoch(
      (creationSecs + 12 * Duration.secondsPerDay + 1234) * 1000,
      isUtc: true,
    );
    const base = ReviewSchedulingContext(
      intervalMultiplier: 1.2,
      hardMultiplier: 1.4,
      fuzzFactor: 0.25,
    );
    final state = ReviewCardState(
      scheduledDays: 5,
      elapsedDays: 8,
      easeFactor: 2.3,
      lapses: 2,
    );

    setUp(() async {
      await _prepareTimingCollection(storage, creationSecs);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        _config(Int64(10), 'A', buryReviews: true),
      );
      storage.decks.addOrUpdateDeckWithExistingId(_normalDeck(7, Int64(10)));
      await _insertReviewContextCard(
        storage,
        cardId: 1,
        noteId: Int64(100),
        deckId: 7,
      );
    });

    test(
      'enabled output matches direct nextStates with the Unit99 resolver',
      () async {
        const fuzzSeed = 42;
        final composedContext = await storage
            .reviewSchedulingContextWithCardLoadBalancerForNow(
              baseContext: base,
              cardId: Int64(1),
              loadBalancerEnabled: true,
              fuzzSeed: BigInt.from(fuzzSeed),
              now: now,
            );

        final result = await storage
            .reviewCardSchedulingStatesWithCardLoadBalancerForNow(
              state: state,
              baseContext: base,
              cardId: Int64(1),
              loadBalancerEnabled: true,
              fuzzSeed: BigInt.from(fuzzSeed),
              now: now,
            );

        _expectReviewSchedulingStatesEqual(
          result,
          state.nextStates(composedContext),
        );
        expect(composedContext.intervalMultiplier, base.intervalMultiplier);
        expect(composedContext.hardMultiplier, base.hardMultiplier);
        expect(composedContext.fuzzFactor, base.fuzzFactor);
        expect(result.current.review.scheduledDays, state.scheduledDays);
      },
    );

    test(
      'disabled output uses the base context without looking up the card',
      () async {
        final result = await storage
            .reviewCardSchedulingStatesWithCardLoadBalancerForNow(
              state: state,
              baseContext: base,
              cardId: Int64(999),
              loadBalancerEnabled: false,
              fuzzSeed: null,
            );

        _expectReviewSchedulingStatesEqual(result, state.nextStates(base));
      },
    );

    test(
      'injected now selects the collection timing for answer states',
      () async {
        final context = await storage.loadBalancerContextForNow(now: now);
        final expectedContext = base.withLoadBalancedIntervalResolver(
          context.reviewIntervalResolver(
            deckConfigId: Int64(10),
            noteId: Int64(100),
            fuzzSeed: BigInt.from(42),
          ),
        );
        final result = await storage
            .reviewCardSchedulingStatesWithCardLoadBalancerForNow(
              state: state,
              baseContext: base,
              cardId: Int64(1),
              loadBalancerEnabled: true,
              fuzzSeed: BigInt.from(42),
              now: now,
            );

        _expectReviewSchedulingStatesEqual(
          result,
          state.nextStates(expectedContext),
        );
      },
    );
  });

  group('CollectionLoadBalancerContext.addAnsweredReviewCard', () {
    final preset = Int64(10);

    test('adds a review card to its preset, interval, and note bucket', () {
      final context = _loadBalancerContextWithCache(preset);
      final card = Card(
        id: Int64(2),
        noteId: Int64(20),
        queue: CardQueue.review,
        interval: 7,
      );

      context.addAnsweredReviewCard(card, preset);

      final day = context.cache.daysByPreset[preset]![7];
      expect(day.cardCount, 1);
      expect(day.hasSibling(Int64(20)), isTrue);
    });

    test('does not add a card whose resulting queue is not review', () {
      final context = _loadBalancerContextWithCache(preset);
      final card = Card(
        id: Int64(2),
        noteId: Int64(20),
        queue: CardQueue.learn,
        interval: 7,
      );

      context.addAnsweredReviewCard(card, preset);

      expect(context.cache.daysByPreset[preset]![7].cardCount, 0);
    });

    test('does not add a review card when the home config ID is absent', () {
      final context = _loadBalancerContextWithCache(preset);
      final card = Card(
        id: Int64(2),
        noteId: Int64(20),
        queue: CardQueue.review,
        interval: 7,
      );

      context.addAnsweredReviewCard(card, null);

      expect(context.cache.daysByPreset[preset]![7].cardCount, 0);
    });

    test('does not add a review card outside the cached interval range', () {
      final context = _loadBalancerContextWithCache(preset);
      final card = Card(
        id: Int64(2),
        noteId: Int64(20),
        queue: CardQueue.review,
        interval: 99,
      );

      context.addAnsweredReviewCard(card, preset);

      final day = context.cache.daysByPreset[preset]![0];
      expect(day.cardCount, 1);
      expect(day.hasSibling(Int64(10)), isTrue);
      expect(day.hasSibling(Int64(20)), isFalse);
    });
  });
}

void _expectReviewSchedulingStatesEqual(
  ReviewCardSchedulingStates actual,
  ReviewCardSchedulingStates expected,
) {
  for (final pair in [
    (actual.current, expected.current),
    (actual.again, expected.again),
    (actual.hard, expected.hard),
    (actual.good, expected.good),
    (actual.easy, expected.easy),
  ]) {
    expect(pair.$1.kind, pair.$2.kind);
    expect(pair.$1.review.scheduledDays, pair.$2.review.scheduledDays);
    expect(pair.$1.review.elapsedDays, pair.$2.review.elapsedDays);
    expect(pair.$1.review.easeFactor, pair.$2.review.easeFactor);
    expect(pair.$1.review.lapses, pair.$2.review.lapses);
    expect(pair.$1.review.leeched, pair.$2.review.leeched);
  }
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

DeckConfig _config(Int64 id, String name, {bool buryReviews = false}) {
  final inner = DeckConfig.defaults().inner..buryReviews = buryReviews;
  return DeckConfig(id: id, name: name, inner: inner);
}

Future<void> _insertReviewContextCard(
  CollectionSqliteStorage storage, {
  required int cardId,
  required Int64 noteId,
  required int deckId,
  int due = 13,
  int originalDeckId = 0,
  int interval = 5,
  int factor = 2500,
  int lapses = 0,
  int ctype = 2,
  String data = '',
}) async {
  await storage.executeBatch('''
INSERT INTO cards (
  id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses,
  left, odue, odid, flags, data
) VALUES (
  $cardId, $noteId, $deckId, 0, 0, 0, $ctype, 2, $due, $interval, $factor, 1, $lapses,
  0, 0, $originalDeckId, 0, '$data'
);
''');
}

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

CollectionLoadBalancerContext _loadBalancerContextWithCache(
  DeckConfigId preset,
) {
  final history = List.generate(99, (_) => <LoadBalancerHistoryCard>[]);
  history[0].add((Int64(1), Int64(10), Int64(7)));
  return CollectionLoadBalancerContext(
    daysElapsed: 0,
    nextDayAt: Int64.ZERO,
    cache: LoadBalancerCache.fromHistory(
      cardsByDay: history,
      deckConfigByDeck: {Int64(7): preset},
      configs: {preset: DeckConfig.defaults()},
    ),
  );
}
