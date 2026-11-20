// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CollectionSqliteStorage storage;
  late Database database;
  late int failFlushCount;
  late int flushCount;

  setUp(() async {
    failFlushCount = 0;
    flushCount = 0;
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => database = sqlite3.openInMemory(),
        flush: () {
          flushCount++;
          if (failFlushCount > 0) {
            failFlushCount--;
            throw StateError('injected flush failure');
          }
        },
      ),
      location: ':memory:',
    );
    await storage.executeBatch('''
      CREATE TABLE col (mod INTEGER NOT NULL, crt INTEGER NOT NULL, conf TEXT NOT NULL);
      CREATE TABLE config (key TEXT PRIMARY KEY, usn INTEGER, mtime_secs INTEGER, val BLOB);
      CREATE TABLE decks (id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER, common BLOB, kind BLOB);
      CREATE TABLE deck_config (id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER, config BLOB);
      CREATE TABLE cards (id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER, mod INTEGER, usn INTEGER, type INTEGER, queue INTEGER, due INTEGER, ivl REAL, factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER, odue INTEGER, odid INTEGER, flags INTEGER, data TEXT);
      CREATE TABLE notes (id INTEGER PRIMARY KEY, guid TEXT, mid INTEGER, mod INTEGER, usn INTEGER, tags TEXT, flds TEXT, sfld TEXT, csum INTEGER, flags INTEGER DEFAULT 0, data TEXT DEFAULT '');
      CREATE TABLE revlog (id INTEGER PRIMARY KEY, cid INTEGER, usn INTEGER, ease INTEGER, ivl INTEGER, lastIvl INTEGER, factor INTEGER, time INTEGER, type INTEGER);
      CREATE TABLE graves (usn INTEGER, oid INTEGER, type INTEGER, UNIQUE(oid, type));
    ''');
    database.execute("INSERT INTO col VALUES (123, 0, '{}')");
    final configId = Int64.parseInt('9007199254740997');
    final config = DeckConfig.defaults();
    config.inner.newPerDay = 37;
    config.inner.reviewsPerDay = 241;
    config.inner.buryNew = true;
    storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
      DeckConfig(id: configId, name: 'Shared', inner: config.inner),
    );
    final deckId = Int64.parseInt('9007199254740995');
    final deck = Deck(
      id: deckId,
      name: 'Exact',
      kind: NormalDeckKind(deck_proto.Deck_Normal(configId: configId)),
    );
    storage.decks.addOrUpdateDeckWithExistingId(deck);
    storage.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: Int64(12),
        name: 'Also shared',
        kind: NormalDeckKind(deck_proto.Deck_Normal(configId: configId)),
      ),
    );
    storage.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: Int64(900),
        name: 'Filtered',
        kind: FilteredDeckKind(deck_proto.Deck_Filtered()),
      ),
    );
  });

  tearDown(() async => storage.close());

  test(
    'daily limits edit the exact shared preset and remain undoable',
    () async {
      final deckId = Int64.parseInt('9007199254740995');
      final configId = storage.decks.getDeck(deckId)!.configId!;
      final before = storage.deckConfigs.getDeckConfig(configId)!;

      await storage.updateDeckDailyLimits(
        deckId,
        newPerDay: 0,
        reviewsPerDay: 9999,
      );

      var saved = storage.deckConfigs.getDeckConfig(configId)!;
      expect(saved.inner.newPerDay, 0);
      expect(saved.inner.reviewsPerDay, 9999);
      expect(saved.inner.buryNew, isTrue);
      expect(storage.decks.getDeck(Int64(12))!.configId, configId);
      expect(storage.canUndoCollectionOperation, isTrue);

      await storage.undoLastCollectionOperation();
      saved = storage.deckConfigs.getDeckConfig(configId)!;
      expect(saved.inner.newPerDay, before.inner.newPerDay);
      expect(saved.inner.reviewsPerDay, before.inner.reviewsPerDay);
      expect(saved.inner.buryNew, isTrue);
      await storage.redoLastCollectionOperation();
      expect(storage.deckConfigs.getDeckConfig(configId)!.inner.newPerDay, 0);
    },
  );

  test('rejects invalid limits and filtered decks without writing', () async {
    final configId = Int64.parseInt('9007199254740997');
    final before = storage.deckConfigs.getDeckConfig(configId)!;
    await expectLater(
      storage.updateDeckDailyLimits(
        Int64.parseInt('9007199254740995'),
        newPerDay: 10000,
        reviewsPerDay: 5,
      ),
      throwsArgumentError,
    );
    await expectLater(
      storage.updateDeckDailyLimits(Int64(900), newPerDay: 5, reviewsPerDay: 5),
      throwsStateError,
    );
    expect(
      storage.deckConfigs.getDeckConfig(configId)!.inner.writeToBuffer(),
      before.inner.writeToBuffer(),
    );
  });

  test(
    'today queue extensions preserve selected deck values and undo/redo',
    () async {
      final deckId = Int64.parseInt('9007199254740995');
      final today = storage.timingTodayForNow().daysElapsed;
      final deck = storage.decks.getDeck(deckId)!;
      final common = deck.common.deepCopy()
        ..lastDayStudied = today
        ..newStudied = 4
        ..reviewStudied = 9;
      final original = Deck(
        id: deck.id,
        name: deck.name,
        common: common,
        kind: NormalDeckKind(
          deck_proto.Deck_Normal(configId: deck.configId!)
            ..extendNew = 2
            ..extendReview = 3,
        ),
      );
      storage.decks.updateDeck(original);

      await storage.extendCustomStudyLimits(deckId, newDelta: 7);
      var changed = storage.decks.getDeck(deckId)!;
      expect(changed.common.newStudied, -3);
      expect(changed.common.reviewStudied, 9);
      expect((changed.kind as NormalDeckKind).value.extendNew, 7);
      expect((changed.kind as NormalDeckKind).value.extendReview, 3);
      expect(storage.decks.getDeck(Int64(12))!.common.newStudied, 0);

      await storage.undoLastCollectionOperation();
      changed = storage.decks.getDeck(deckId)!;
      expect(changed.common.newStudied, 4);
      expect((changed.kind as NormalDeckKind).value.extendNew, 2);
      await storage.redoLastCollectionOperation();
      expect(storage.decks.getDeck(deckId)!.common.newStudied, -3);
    },
  );

  test(
    "zero is a no-op; negative values reduce today available queue only",
    () async {
      final deckId = Int64.parseInt('9007199254740995');
      final today = storage.timingTodayForNow().daysElapsed;
      final deck = storage.decks.getDeck(deckId)!;
      final original = Deck(
        id: deck.id,
        name: deck.name,
        common: deck_proto.Deck_Common(
          lastDayStudied: today,
          newStudied: 5,
          reviewStudied: 6,
        ),
        kind: NormalDeckKind(
          deck_proto.Deck_Normal(configId: deck.configId!)..extendNew = 2,
        ),
      );
      storage.decks.updateDeck(original);
      await storage.extendCustomStudyLimits(deckId, newDelta: 0);
      expect(storage.canUndoCollectionOperation, isFalse);
      await storage.extendCustomStudyLimits(deckId, newDelta: -3);
      final changed = storage.decks.getDeck(deckId)!;
      expect(changed.common.newStudied, 8);
      expect((changed.kind as NormalDeckKind).value.extendNew, 2);
    },
  );

  test(
    'queue defaults separate selected deck counts from child counts',
    () async {
      final deckId = Int64.parseInt('9007199254740995');
      final childId = Int64.parseInt('9007199254740996');
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: childId,
          name: 'Exact::Child',
          kind: NormalDeckKind(
            deck_proto.Deck_Normal(
              configId: storage.decks.getDeck(deckId)!.configId!,
            ),
          ),
        ),
      );
      final today = storage.timingTodayForNow().daysElapsed;
      database.execute('INSERT INTO config VALUES (?, -1, 0, ?)', [
        'lastUnburied',
        '[${today}]'.codeUnits,
      ]);
      database.execute(
        'INSERT INTO cards (id,nid,did,type,queue,due) VALUES (1,1,?,0,0,0)',
        [deckId.toInt()],
      );
      database.execute(
        'INSERT INTO cards (id,nid,did,type,queue,due) VALUES (2,2,?,2,2,?)',
        [deckId.toInt(), today],
      );
      database.execute(
        'INSERT INTO cards (id,nid,did,type,queue,due) VALUES (3,3,?,0,0,0)',
        [childId.toInt()],
      );
      database.execute(
        'INSERT INTO cards (id,nid,did,type,queue,due) VALUES (4,4,?,2,2,?)',
        [childId.toInt(), today],
      );
      final defaults = await storage.customStudyLimitDefaults(deckId);
      expect(defaults.availableNew, 1);
      expect(defaults.availableReview, 1);
      expect(defaults.availableNewInChildren, 1);
      expect(defaults.availableReviewInChildren, 1);
      expect(defaults.extendNew, 0);
      expect(defaults.extendReview, 0);
    },
  );

  test('failed queue extension rolls back deck state and undo history', () async {
    final deckId = Int64.parseInt('9007199254740995');
    final before = storage.decks.getDeck(deckId)!;
    database.execute(
      "CREATE TRIGGER fail_deck_replace BEFORE UPDATE ON decks WHEN new.id = ${deckId.toInt()} BEGIN SELECT RAISE(ABORT, 'blocked'); END",
    );
    await expectLater(
      storage.extendCustomStudyLimits(deckId, newDelta: 4),
      throwsA(anything),
    );
    database.execute('DROP TRIGGER fail_deck_replace');
    final after = storage.decks.getDeck(deckId)!;
    expect(after.common.writeToBuffer(), before.common.writeToBuffer());
    expect(
      (after.kind as NormalDeckKind).value.writeToBuffer(),
      (before.kind as NormalDeckKind).value.writeToBuffer(),
    );
    expect(storage.canUndoCollectionOperation, isFalse);
  });

  test('retrying a committed limit save flushes unchanged values', () async {
    final deckId = Int64.parseInt('9007199254740995');
    failFlushCount = 1;

    await expectLater(
      storage.updateDeckDailyLimits(deckId, newPerDay: 42, reviewsPerDay: 250),
      throwsStateError,
    );
    expect(storage.canUndoCollectionOperation, isTrue);
    expect(
      storage.deckConfigs
          .getDeckConfig(Int64.parseInt('9007199254740997'))!
          .inner
          .newPerDay,
      42,
    );
    final flushesBeforeRetry = flushCount;

    await storage.updateDeckDailyLimits(
      deckId,
      newPerDay: 42,
      reviewsPerDay: 250,
    );

    expect(flushCount, flushesBeforeRetry + 1);
    expect(storage.canUndoCollectionOperation, isTrue);
  });
}
