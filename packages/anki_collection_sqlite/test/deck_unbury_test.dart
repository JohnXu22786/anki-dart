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

Future<Deck> _addDeck(String name, {Int64? id}) async {
  final initial = Deck(
    kind: Deck.newNormal().kind,
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
    ),
  );
}
