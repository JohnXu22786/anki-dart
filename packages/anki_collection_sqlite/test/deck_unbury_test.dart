// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CollectionSqliteStorage storage;
  late Database database;
  var failFlushCount = 0;

  setUp(() async {
    failFlushCount = 0;
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => database = sqlite3.openInMemory(),
        flush: () {
          if (failFlushCount > 0) {
            failFlushCount--;
            throw StateError('flush failed');
          }
        },
      ),
      location: ':memory:',
    );
    _activeStorage = storage;
    await storage.executeBatch('''
      CREATE TABLE col (mod INTEGER NOT NULL);
      CREATE TABLE config (key TEXT PRIMARY KEY, usn INTEGER, mtime_secs INTEGER, val BLOB);
      CREATE TABLE decks (id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER, common BLOB, kind BLOB);
      CREATE TABLE deck_config (id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER, config BLOB);
      CREATE TABLE cards (id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER, mod INTEGER, usn INTEGER, type INTEGER, queue INTEGER, due INTEGER, ivl REAL, factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER, odue INTEGER, odid INTEGER, flags INTEGER, data TEXT);
      CREATE TABLE notes (id INTEGER PRIMARY KEY, guid TEXT, mid INTEGER, mod INTEGER, usn INTEGER, tags TEXT, flds TEXT, sfld TEXT, csum INTEGER, flags INTEGER DEFAULT 0, data TEXT DEFAULT '');
      CREATE TABLE revlog (id INTEGER PRIMARY KEY, cid INTEGER, usn INTEGER, ease INTEGER, ivl INTEGER, lastIvl INTEGER, factor INTEGER, time INTEGER, type INTEGER);
      CREATE TABLE graves (usn INTEGER, oid INTEGER, type INTEGER, UNIQUE(oid, type));
    ''');
    database.execute('INSERT INTO col VALUES (123)');
    database.execute(
      'INSERT INTO decks (id, name, mtime_secs, usn, common, kind) VALUES (1, ?, 0, 0, ?, ?)',
      [
        'Default',
        Deck.newNormal().common.writeToBuffer(),
        deck_proto.Deck_KindContainer(
          normal: deck_proto.Deck_Normal(configId: Int64.ONE),
        ).writeToBuffer(),
      ],
    );
  });

  tearDown(() async => storage.close());

  test(
    'unburies selected deck children using Core queue restoration',
    () async {
      final parentId = Int64.parseInt('9007199254740995');
      final parent = await _addDeck('Languages', id: parentId);
      final child = await _addDeck('Languages::Spanish');
      final sibling = await _addDeck('History');
      await _addCard(
        Int64(100),
        parent.id,
        CardType.newCard,
        CardQueue.userBuried,
        due: 42,
      );
      await _addCard(
        Int64(101),
        child.id,
        CardType.learn,
        CardQueue.schedBuried,
        due: 1000000001,
      );
      await _addCard(
        Int64(102),
        child.id,
        CardType.relearn,
        CardQueue.userBuried,
        due: 12,
      );
      await _addCard(
        Int64(103),
        child.id,
        CardType.review,
        CardQueue.schedBuried,
        due: 99,
      );
      await _addCard(
        Int64(104),
        child.id,
        CardType.review,
        CardQueue.suspended,
        due: 100,
      );
      await _addCard(
        Int64(105),
        sibling.id,
        CardType.review,
        CardQueue.userBuried,
        due: 101,
      );
      await _addCard(
        Int64(106),
        child.id,
        CardType.review,
        CardQueue.review,
        due: 102,
      );
      final beforeMtime = storage.collectionModifiedAt;
      final beforeGeneration = storage.collectionUndoGeneration;

      final result = await storage.unburyDeck(parentId);

      expect(result.deckName, 'Languages');
      expect(result.cardsUnburied, 4);
      expect(result.collectionUndoGeneration, beforeGeneration + 1);
      expect((await storage.getCard(Int64(100)))!.queue, CardQueue.newCard);
      expect((await storage.getCard(Int64(101)))!.queue, CardQueue.learn);
      expect((await storage.getCard(Int64(102)))!.queue, CardQueue.dayLearn);
      expect((await storage.getCard(Int64(103)))!.queue, CardQueue.review);
      expect((await storage.getCard(Int64(104)))!.queue, CardQueue.suspended);
      expect((await storage.getCard(Int64(105)))!.queue, CardQueue.userBuried);
      expect((await storage.getCard(Int64(106)))!.queue, CardQueue.review);
      expect((await storage.getCard(Int64(101)))!.due, 1000000001);
      expect((await storage.getCard(Int64(100)))!.usn, -1);
      expect(storage.collectionModifiedAt, greaterThan(beforeMtime));

      await storage.undoLastCollectionOperation();
      expect((await storage.getCard(Int64(100)))!.queue, CardQueue.userBuried);
      expect((await storage.getCard(Int64(101)))!.queue, CardQueue.schedBuried);
      expect(storage.collectionModifiedAt, beforeMtime);
      await storage.redoLastCollectionOperation();
      expect((await storage.getCard(Int64(102)))!.queue, CardQueue.dayLearn);
      expect(storage.collectionModifiedAt, greaterThan(beforeMtime));
    },
  );

  test('empty deck unbury is a no-op and creates no undo step', () async {
    final deck = await _addDeck('Empty');
    final generation = storage.collectionUndoGeneration;

    final result = await storage.unburyDeck(deck.id);

    expect(result.cardsUnburied, 0);
    expect(storage.collectionUndoGeneration, generation);
    expect(storage.canUndoCollectionOperation, isFalse);
  });

  test(
    'empties only the exact filtered deck with Core queue restoration',
    () async {
      final homeId = Int64.parseInt('9007199254740995');
      final home = await _addDeck('Home', id: homeId);
      final filtered = await _addDeck('Filtered', filtered: true);
      final otherFiltered = await _addDeck('Other filtered', filtered: true);
      await _addCard(
        Int64(500),
        filtered.id,
        CardType.review,
        CardQueue.review,
        due: -10,
        originalDeckId: homeId,
        originalDue: 42,
      );
      await _addCard(
        Int64(501),
        filtered.id,
        CardType.learn,
        CardQueue.review,
        due: -10,
        originalDeckId: homeId,
        originalDue: 1000000001,
      );
      await _addCard(
        Int64(502),
        filtered.id,
        CardType.review,
        CardQueue.suspended,
        due: -10,
        originalDeckId: homeId,
        originalDue: 77,
      );
      await _addCard(
        Int64(503),
        otherFiltered.id,
        CardType.review,
        CardQueue.review,
        due: -11,
        originalDeckId: Int64.ONE,
        originalDue: 88,
      );
      final beforeMtime = storage.collectionModifiedAt;
      final beforeGeneration = storage.collectionUndoGeneration;

      final result = await storage.emptyFilteredDeck(filtered.id);

      expect(result.cardsReturned, 3);
      expect(result.collectionUndoGeneration, beforeGeneration + 1);
      final restoredReview = (await storage.getCard(Int64(500)))!;
      expect(restoredReview.deckId, home.id);
      expect(restoredReview.queue, CardQueue.review);
      expect(restoredReview.due, 42);
      expect(restoredReview.originalDeckId, Int64.ZERO);
      expect(restoredReview.originalDue, 0);
      expect(restoredReview.usn, -1);
      expect((await storage.getCard(Int64(501)))!.queue, CardQueue.learn);
      expect((await storage.getCard(Int64(501)))!.due, 1000000001);
      final suspended = (await storage.getCard(Int64(502)))!;
      expect(suspended.queue, CardQueue.suspended);
      expect(suspended.due, 77);
      expect((await storage.getCard(Int64(503)))!.deckId, otherFiltered.id);
      expect(storage.collectionModifiedAt, greaterThan(beforeMtime));

      await storage.undoLastCollectionOperation();
      expect((await storage.getCard(Int64(500)))!.deckId, filtered.id);
      expect((await storage.getCard(Int64(500)))!.originalDeckId, home.id);
      await storage.redoLastCollectionOperation();
      expect((await storage.getCard(Int64(500)))!.deckId, home.id);
      await storage.addOrUpdateCard(
        Card(id: Int64(504), deckId: home.id, ctype: CardType.newCard),
      );
      expect(storage.canUndoCollectionOperation, isFalse);
      await expectLater(
        storage.undoLastCollectionOperation(),
        throwsStateError,
      );
    },
  );

  test(
    'filtered deck empty rejects normal decks and empty target is a no-op',
    () async {
      final normal = await _addDeck('Normal');
      await expectLater(
        storage.emptyFilteredDeck(normal.id),
        throwsA(anything),
      );
      final filtered = await _addDeck('Empty filtered', filtered: true);
      final generation = storage.collectionUndoGeneration;
      final result = await storage.emptyFilteredDeck(filtered.id);
      expect(result.cardsReturned, 0);
      expect(storage.collectionUndoGeneration, generation);
      expect(storage.canUndoCollectionOperation, isFalse);
    },
  );

  test(
    'filtered deck build and rebuild preserve exact signed 64-bit IDs',
    () async {
      final cardId = Int64.parseInt('9007199254740995');
      final home = await _addDeck(
        'Search home',
        id: Int64.parseInt('9007199254740997'),
      );
      final filtered = await _addDeck(
        'Filtered exact IDs',
        id: Int64.parseInt('9007199254740999'),
        filtered: true,
      );
      await _addCard(
        cardId,
        home.id,
        CardType.review,
        CardQueue.review,
        due: 42,
      );
      final config = deck_proto.Deck_Filtered(
        reschedule: false,
        searchTerms: [
          deck_proto.Deck_Filtered_SearchTerm(
            search: 'cid:$cardId',
            limit: 10,
            order: deck_proto.Deck_Filtered_SearchTerm_Order.DUE,
          ),
        ],
      );

      final built = await storage.buildFilteredDeck(
        deck_proto.FilteredDeckForUpdate(
          id: filtered.id,
          name: 'Filtered exact IDs',
          config: config,
        ),
      );
      expect(built.cardsMoved, 1);
      expect(built.deckId, filtered.id);
      var moved = (await storage.getCard(cardId))!;
      expect(moved.deckId, built.deckId);
      expect(moved.originalDeckId, home.id);
      expect(moved.originalDue, 42);
      expect(moved.queue, CardQueue.review);

      await storage.undoLastCollectionOperation();
      expect(storage.decks.getDeck(filtered.id), isNotNull);
      expect((await storage.getCard(cardId))!.deckId, home.id);
      await storage.redoLastCollectionOperation();
      expect(storage.decks.getDeck(filtered.id), isNotNull);
      expect((await storage.getCard(cardId))!.deckId, filtered.id);

      final rebuilt = await storage.buildFilteredDeck(
        deck_proto.FilteredDeckForUpdate(
          id: built.deckId,
          name: 'Filtered exact IDs',
          config: config,
          allowEmpty: true,
        ),
      );
      expect(rebuilt.deckId, built.deckId);
      expect(rebuilt.cardsMoved, 1);
      moved = (await storage.getCard(cardId))!;
      expect(moved.deckId, built.deckId);
      expect(moved.originalDeckId, home.id);
    },
  );

  test(
    'filtered build rejects empty and invalid searches without partial writes',
    () async {
      deck_proto.Deck_Filtered config(String search) =>
          deck_proto.Deck_Filtered(
            searchTerms: [
              deck_proto.Deck_Filtered_SearchTerm(
                search: search,
                limit: 10,
                order: deck_proto.Deck_Filtered_SearchTerm_Order.DUE,
              ),
            ],
          );

      await expectLater(
        storage.buildFilteredDeck(
          deck_proto.FilteredDeckForUpdate(
            name: 'No results',
            config: config('cid:123456789'),
          ),
        ),
        throwsStateError,
      );
      expect(storage.decks.getDeckByName('No results'), isNull);

      await expectLater(
        storage.buildFilteredDeck(
          deck_proto.FilteredDeckForUpdate(
            name: 'Invalid search',
            config: config('('),
            allowEmpty: true,
          ),
        ),
        throwsA(anything),
      );
      expect(storage.decks.getDeckByName('Invalid search'), isNull);

      await expectLater(
        storage.buildFilteredDeck(
          deck_proto.FilteredDeckForUpdate(
            name: 'Oversized limit',
            config: deck_proto.Deck_Filtered(
              searchTerms: [
                deck_proto.Deck_Filtered_SearchTerm(
                  search: 'cid:123456789',
                  limit: 0xffffffff,
                  order: deck_proto.Deck_Filtered_SearchTerm_Order.DUE,
                ),
              ],
            ),
            allowEmpty: true,
          ),
        ),
        throwsRangeError,
      );
      expect(storage.decks.getDeckByName('Oversized limit'), isNull);
    },
  );

  test(
    'filtered build applies each term limit and excludes unavailable cards',
    () async {
      final home = await _addDeck('Filter rules home');
      final previous = await _addDeck('Previous filtered', filtered: true);
      for (final (id, due) in [(701, 40), (702, 50), (703, 60)]) {
        await _addCard(
          Int64(id),
          home.id,
          CardType.review,
          CardQueue.review,
          due: due,
        );
      }
      await _addCard(
        Int64(704),
        home.id,
        CardType.review,
        CardQueue.suspended,
        due: 1,
      );
      await _addCard(
        Int64(705),
        home.id,
        CardType.review,
        CardQueue.schedBuried,
        due: 2,
      );
      await _addCard(
        Int64(706),
        previous.id,
        CardType.review,
        CardQueue.review,
        due: 3,
        originalDeckId: home.id,
        originalDue: 3,
      );
      final result = await storage.buildFilteredDeck(
        deck_proto.FilteredDeckForUpdate(
          name: 'Two term deck',
          allowEmpty: false,
          config: deck_proto.Deck_Filtered(
            reschedule: true,
            searchTerms: [
              deck_proto.Deck_Filtered_SearchTerm(
                search: 'cid:701 OR cid:702 OR cid:704 OR cid:705 OR cid:706',
                limit: 1,
                order: deck_proto.Deck_Filtered_SearchTerm_Order.DUE,
              ),
              deck_proto.Deck_Filtered_SearchTerm(
                search: 'cid:703',
                limit: 1,
                order: deck_proto.Deck_Filtered_SearchTerm_Order.DUE,
              ),
            ],
          ),
        ),
      );
      expect(result.cardsMoved, 2);
      expect((await storage.getCard(Int64(701)))!.deckId, result.deckId);
      expect((await storage.getCard(Int64(701)))!.queue, CardQueue.review);
      expect((await storage.getCard(Int64(702)))!.deckId, home.id);
      expect((await storage.getCard(Int64(703)))!.deckId, result.deckId);
      expect((await storage.getCard(Int64(704)))!.deckId, home.id);
      expect((await storage.getCard(Int64(705)))!.deckId, home.id);
      expect((await storage.getCard(Int64(706)))!.deckId, previous.id);
    },
  );

  test(
    'filtered build rejects blank and case-insensitive duplicate names',
    () async {
      await _addDeck('Existing Filter Name');
      final config = deck_proto.Deck_Filtered(
        searchTerms: [
          deck_proto.Deck_Filtered_SearchTerm(
            search: 'cid:999',
            limit: 10,
            order: deck_proto.Deck_Filtered_SearchTerm_Order.DUE,
          ),
        ],
      );
      await expectLater(
        storage.buildFilteredDeck(
          deck_proto.FilteredDeckForUpdate(name: '   ', config: config),
        ),
        throwsArgumentError,
      );
      await expectLater(
        storage.buildFilteredDeck(
          deck_proto.FilteredDeckForUpdate(
            name: 'existing filter name',
            config: config,
            allowEmpty: true,
          ),
        ),
        throwsStateError,
      );
      expect(storage.decks.getDeckByName('existing filter name'), isNull);
    },
  );

  test(
    'filtered deck empty rolls back and reconciles a committed flush failure',
    () async {
      final filtered = await _addDeck('Filtered failure', filtered: true);
      await _addCard(
        Int64(600),
        filtered.id,
        CardType.review,
        CardQueue.review,
        originalDeckId: Int64.ONE,
        originalDue: 12,
      );
      final beforeMtime = storage.collectionModifiedAt;
      database.execute('''
      CREATE TRIGGER fail_empty_filtered BEFORE UPDATE ON cards
      BEGIN SELECT RAISE(ABORT, 'injected update failure'); END
    ''');

      await expectLater(
        storage.emptyFilteredDeck(filtered.id),
        throwsA(anything),
      );
      expect((await storage.getCard(Int64(600)))!.deckId, filtered.id);
      expect((await storage.getCard(Int64(600)))!.originalDeckId, Int64.ONE);
      expect(storage.collectionModifiedAt, beforeMtime);
      expect(storage.canUndoCollectionOperation, isFalse);

      database.execute('DROP TRIGGER fail_empty_filtered');
      failFlushCount = 2;
      final result = await storage.emptyFilteredDeck(filtered.id);
      expect(result.cardsReturned, 1);
      expect(result.persistenceWarning, isTrue);
      expect((await storage.getCard(Int64(600)))!.deckId, Int64.ONE);
      expect(storage.canUndoCollectionOperation, isTrue);
      await storage.undoLastCollectionOperation();
      expect((await storage.getCard(Int64(600)))!.deckId, filtered.id);
    },
  );

  test('unbury rolls back card writes on a pre-commit failure', () async {
    final deck = await _addDeck('Rollback');
    await _addCard(Int64(200), deck.id, CardType.review, CardQueue.userBuried);
    final beforeMtime = storage.collectionModifiedAt;
    database.execute('''
      CREATE TRIGGER fail_unbury BEFORE UPDATE ON cards
      BEGIN SELECT RAISE(ABORT, 'injected update failure'); END
    ''');

    await expectLater(storage.unburyDeck(deck.id), throwsA(anything));

    expect((await storage.getCard(Int64(200)))!.queue, CardQueue.userBuried);
    expect(storage.collectionModifiedAt, beforeMtime);
    expect(storage.canUndoCollectionOperation, isFalse);
  });

  test(
    'post-commit flush failure reports committed result and keeps undo',
    () async {
      final deck = await _addDeck('Flush');
      await _addCard(
        Int64(300),
        deck.id,
        CardType.review,
        CardQueue.schedBuried,
      );
      failFlushCount = 2;

      final result = await storage.unburyDeck(deck.id);

      expect(result.cardsUnburied, 1);
      expect(result.persistenceWarning, isTrue);
      expect((await storage.getCard(Int64(300)))!.queue, CardQueue.review);
      expect(storage.canUndoCollectionOperation, isTrue);
      await storage.undoLastCollectionOperation();
      expect((await storage.getCard(Int64(300)))!.queue, CardQueue.schedBuried);
    },
  );

  test('later collection mutation invalidates stale unbury history', () async {
    final deck = await _addDeck('Stale');
    await _addCard(Int64(400), deck.id, CardType.review, CardQueue.userBuried);
    await storage.unburyDeck(deck.id);
    await _addCard(Int64(401), deck.id, CardType.newCard, CardQueue.newCard);

    expect(storage.canUndoCollectionOperation, isFalse);
    await expectLater(storage.undoLastCollectionOperation(), throwsStateError);
  });
}

late CollectionSqliteStorage _activeStorage;

Future<Deck> _addDeck(String name, {Int64? id, bool filtered = false}) async {
  final initial = Deck(
    kind: filtered
        ? FilteredDeckKind(deck_proto.Deck_Filtered())
        : Deck.newNormal().kind,
    common: Deck.newNormal().common,
    name: name,
  );
  if (id != null) {
    final deck = Deck(
      id: id,
      name: name,
      common: initial.common,
      kind: initial.kind,
    );
    _activeStorage.decks.addOrUpdateDeckWithExistingId(deck);
    return deck;
  }
  return _activeStorage.decks.addDeck(initial);
}

Future<void> _addCard(
  Int64 id,
  Int64 deckId,
  CardType type,
  CardQueue queue, {
  int due = 1,
  Int64 originalDeckId = Int64.ZERO,
  int originalDue = 0,
}) async {
  await _activeStorage.addOrUpdateCard(
    Card(
      id: id,
      deckId: deckId,
      ctype: type,
      queue: queue,
      due: due,
      mtimeSecs: Int64(9),
      usn: 4,
      originalDeckId: originalDeckId,
      originalDue: originalDue,
    ),
  );
}
