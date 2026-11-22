// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

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
            throw StateError('flush failed once');
          }
        },
      ),
      location: ':memory:',
    );
    _activeStorage = storage;
    _activeDatabase = database;
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
      '''
      INSERT INTO decks (id, name, mtime_secs, usn, common, kind)
      VALUES (1, 'Default', 0, 0, ?, ?)
    ''',
      [
        Deck.newNormal().common.writeToBuffer(),
        deck_proto.Deck_KindContainer(
          normal: deck_proto.Deck_Normal(configId: Int64.ONE),
        ).writeToBuffer(),
      ],
    );
  });

  tearDown(() async => storage.close());

  test(
    'removes normal parent and nested decks, cards, orphan notes and metadata',
    () async {
      final parent = await _addDeck('Project');
      final child = await _addDeck('Project::Child');
      final sibling = await _addDeck('Keep');
      await _addNote(Int64(10));
      await _addNote(Int64(11));
      await _addCard(Int64(100), Int64(10), parent.id);
      await _addCard(Int64(101), Int64(11), child.id);
      await _addCard(Int64(102), Int64(10), sibling.id);
      database.execute(
        "INSERT INTO config VALUES ('_deck_${parent.id}_lastNotetype', 0, 1, ?)",
        [utf8.encode('10')],
      );
      database.execute(
        "INSERT INTO revlog VALUES (900, 100, 0, 3, 2, 1, 2500, 100, 1)",
      );

      final result = await storage.removeDeckAndChildren(parent.id);

      expect(result.deckName, 'Project');
      expect(result.cardsDeleted, 2);
      expect(storage.decks.getDeck(parent.id), isNull);
      expect(storage.decks.getDeck(child.id), isNull);
      expect(storage.decks.getDeck(sibling.id), isNotNull);
      expect(await storage.getCard(Int64(100)), isNull);
      expect(await storage.getCard(Int64(101)), isNull);
      expect(await storage.getCard(Int64(102)), isNotNull);
      expect(
        await storage.getNote(Int64(10)),
        isNotNull,
        reason: 'note 10 retains its card in Keep',
      );
      expect(await storage.getNote(Int64(11)), isNull);
      expect(storage.hasDeckDeletionGrave(parent.id), isTrue);
      expect(storage.hasDeckDeletionGrave(child.id), isTrue);
      expect(storage.hasDeletionGrave(Int64(100), note: false), isTrue);
      expect(storage.hasDeletionGrave(Int64(11), note: true), isTrue);
      expect(storage.hasDeletionGrave(Int64(10), note: true), isFalse);
      expect(
        database
            .select('SELECT count(*) FROM config WHERE key = ?', [
              '_deck_${parent.id}_lastNotetype',
            ])
            .single
            .columnAt(0),
        0,
      );
      expect(
        await storage.queryInt('SELECT count(*) FROM revlog WHERE cid = 100'),
        0,
      );
    },
  );

  test(
    'filtered deck removal returns cards to original deck and queue',
    () async {
      final filtered = await _addDeck('Filtered', filtered: true);
      await _addNote(Int64(20));
      await _addCard(
        Int64(200),
        Int64(20),
        filtered.id,
        queue: CardQueue.review,
        due: 55,
        odid: Int64.ONE,
        odue: 41,
      );

      final result = await storage.removeDeckAndChildren(filtered.id);
      final card = await storage.getCard(Int64(200));

      expect(result.cardsDeleted, 0);
      expect(storage.decks.getDeck(filtered.id), isNull);
      expect(card!.deckId, Int64.ONE);
      expect(card.queue, CardQueue.newCard);
      expect(card.due, 41);
      expect(card.originalDeckId, Int64.ZERO);
      expect(card.originalDue, 0);
      expect(await storage.getNote(Int64(20)), isNotNull);
      await storage.undoLastCollectionOperation();
      final undone = await storage.getCard(Int64(200));
      expect(undone!.deckId, filtered.id);
      expect(undone.queue, CardQueue.review);
      expect(undone.originalDeckId, Int64.ONE);
      await storage.redoLastCollectionOperation();
      expect((await storage.getCard(Int64(200)))!.deckId, Int64.ONE);
    },
  );

  test(
    'deleting Default empties and resets it while retaining its id',
    () async {
      final currentDefault = storage.decks.getDeck(Int64.ONE)!;
      storage.decks.updateDeck(
        Deck(
          id: Int64.ONE,
          name: 'Renamed Default',
          mtimeSecs: currentDefault.mtimeSecs,
          usn: currentDefault.usn,
          common: currentDefault.common,
          kind: currentDefault.kind,
        ),
      );
      await _addNote(Int64(30));
      await _addCard(Int64(300), Int64(30), Int64.ONE);

      final result = await storage.removeDeckAndChildren(
        Int64.ONE,
        defaultDeckName: 'Principal',
      );

      expect(result.deckName, 'Renamed Default');
      expect(result.cardsDeleted, 1);
      expect(storage.decks.getDeck(Int64.ONE)!.name, 'Principal');
      expect(await storage.getCard(Int64(300)), isNull);
      expect(await storage.getNote(Int64(30)), isNull);
      expect(storage.hasDeckDeletionGrave(Int64.ONE), isFalse);
      await storage.undoLastCollectionOperation();
      expect(storage.decks.getDeck(Int64.ONE)!.name, 'Renamed Default');
      expect(await storage.getCard(Int64(300)), isNotNull);
      expect(await storage.getNote(Int64(30)), isNotNull);
    },
  );

  test(
    'preserves exact large deck IDs and supports collection undo and redo',
    () async {
      final id = Int64.parseInt('9007199254740995');
      final deck = await _addDeck('Large', id: id);
      await _addNote(Int64.parseInt('9007199254740997'));
      await _addCard(
        Int64.parseInt('9007199254740999'),
        Int64.parseInt('9007199254740997'),
        deck.id,
      );
      await storage.selectDeck(id);

      await storage.removeDeckAndChildren(id);
      expect(storage.decks.getDeck(id), isNull);
      expect(storage.currentDeckId, Int64.ONE);
      expect(storage.collectionUndoLabel, 'deleteDeck');
      expect(
        storage.collectionUndoChanges.where(
          (change) =>
              change.table == 'graves' &&
              change.kind == CollectionUndoChangeKind.deck &&
              change.variant == CollectionUndoChangeVariant.graveAdded,
        ),
        hasLength(1),
      );
      expect(
        storage.collectionUndoChanges.map((change) => change.kind),
        containsAll({
          CollectionUndoChangeKind.card,
          CollectionUndoChangeKind.note,
          CollectionUndoChangeKind.deck,
        }),
      );
      await storage.undoLastCollectionOperation();
      expect(storage.decks.getDeck(id)!.id, id);
      expect(
        await storage.getCard(Int64.parseInt('9007199254740999')),
        isNotNull,
      );
      expect(
        await storage.getNote(Int64.parseInt('9007199254740997')),
        isNotNull,
      );
      expect(storage.hasDeckDeletionGrave(id), isFalse);
      expect(storage.currentDeckId, id);
      expect(
        storage.collectionRedoChanges
            .where((change) => change.table == 'graves')
            .map((change) => change.variant),
        contains(CollectionUndoChangeVariant.graveRemoved),
      );
      await storage.redoLastCollectionOperation();
      expect(storage.decks.getDeck(id), isNull);
      expect(await storage.getCard(Int64.parseInt('9007199254740999')), isNull);
      expect(storage.hasDeckDeletionGrave(id), isTrue);
      expect(storage.currentDeckId, Int64.ONE);
    },
  );

  test(
    'undoable normal-deck creation restores ancestors with stable IDs',
    () async {
      final created = await storage.getOrCreateNormalDeckUndoable(
        'Created::Nested',
      );
      final ancestorId = storage.decks.getDeckId('Created');
      expect(created.name, 'Created::Nested');
      expect(ancestorId, isNotNull);
      expect(storage.collectionUndoLabel, 'createDeck');

      await storage.undoLastCollectionOperation();
      expect(storage.decks.getDeckId('Created'), isNull);
      expect(storage.decks.getDeckId('Created\x1fNested'), isNull);

      await storage.redoLastCollectionOperation();
      expect(storage.decks.getDeckId('Created'), ancestorId);
      expect(storage.decks.getDeckId('Created\x1fNested'), created.id);
    },
  );

  test(
    'concurrent creation of one deck returns the serialized result',
    () async {
      final results = await Future.wait([
        storage.getOrCreateNormalDeckUndoable('Concurrent::Nested'),
        storage.getOrCreateNormalDeckUndoable('Concurrent::Nested'),
      ]);

      expect(results[0].id, results[1].id);
      expect(storage.decks.getDeckId('Concurrent'), isNotNull);
      expect(storage.decks.getDeckId('Concurrent\x1fNested'), results[0].id);
      expect(storage.collectionUndoLabel, 'createDeck');
      await storage.undoLastCollectionOperation();
      expect(storage.decks.getDeckId('Concurrent'), isNull);
      expect(storage.canUndoCollectionOperation, isFalse);
    },
  );

  test(
    'deck rename journals the renamed tree and newly created ancestors',
    () async {
      final source = await storage.getOrCreateNormalDeck('Source::Child');
      final originalParentId = storage.decks.getDeckId('Source');
      expect(
        await storage.renameDeck(source.id, 'Renamed::Parent::Child'),
        isTrue,
      );
      final renamedParentId = storage.decks.getDeckId('Renamed');
      final renamedNestedParentId = storage.decks.getDeckId(
        'Renamed\x1fParent',
      );
      expect(storage.collectionUndoLabel, 'renameDeck');
      expect(storage.decks.getDeck(source.id)!.name, 'Renamed::Parent::Child');

      await storage.undoLastCollectionOperation();
      expect(storage.decks.getDeck(source.id)!.name, 'Source::Child');
      expect(storage.decks.getDeckId('Source'), originalParentId);
      expect(storage.decks.getDeckId('Renamed'), isNull);
      expect(storage.decks.getDeckId('Renamed\x1fParent'), isNull);

      await storage.redoLastCollectionOperation();
      expect(storage.decks.getDeck(source.id)!.name, 'Renamed::Parent::Child');
      expect(storage.decks.getDeckId('Renamed'), renamedParentId);
      expect(
        storage.decks.getDeckId('Renamed\x1fParent'),
        renamedNestedParentId,
      );
    },
  );

  test(
    'later collection mutation invalidates stale deck removal history',
    () async {
      final deck = await _addDeck('Stale');
      await storage.removeDeckAndChildren(deck.id);
      expect(storage.canUndoCollectionOperation, isTrue);

      await storage.selectDeck(Int64.ONE);

      expect(storage.canUndoCollectionOperation, isFalse);
      await expectLater(
        storage.undoLastCollectionOperation(),
        throwsStateError,
      );
    },
  );

  test(
    'redo preserves the selected deck when it was outside the deletion',
    () async {
      final current = await _addDeck('Current');
      final target = await _addDeck('Remove');
      await storage.selectDeck(current.id);

      await storage.removeDeckAndChildren(target.id);
      expect(storage.currentDeckId, current.id);
      await storage.undoLastCollectionOperation();
      expect(storage.currentDeckId, current.id);
      await storage.redoLastCollectionOperation();
      expect(storage.currentDeckId, current.id);
    },
  );

  test(
    'pre-commit failure rolls back rows and does not create undo history',
    () async {
      final deck = await _addDeck('Rollback');
      await _addNote(Int64(40));
      await _addCard(Int64(400), Int64(40), deck.id);
      database.execute('''
      CREATE TRIGGER reject_delete BEFORE DELETE ON cards
      BEGIN SELECT RAISE(ABORT, 'reject delete'); END
    ''');

      await expectLater(
        storage.removeDeckAndChildren(deck.id),
        throwsA(anything),
      );

      expect(storage.decks.getDeck(deck.id), isNotNull);
      expect(await storage.getCard(Int64(400)), isNotNull);
      expect(await storage.getNote(Int64(40)), isNotNull);
      expect(storage.canUndoCollectionOperation, isFalse);
    },
  );

  test(
    'post-commit flush failure retries persistence and reports the committed result',
    () async {
      final deck = await _addDeck('Flush');
      failFlushCount = 1;

      final result = await storage.removeDeckAndChildren(deck.id);

      expect(result.cardsDeleted, 0);
      expect(storage.decks.getDeck(deck.id), isNull);
      expect(storage.canUndoCollectionOperation, isTrue);
    },
  );

  test(
    'double post-commit flush failure keeps the committed result and undo',
    () async {
      final deck = await _addDeck('Flush warning');
      failFlushCount = 2;

      final result = await storage.removeDeckAndChildren(deck.id);

      expect(result.persistenceWarning, isTrue);
      expect(storage.decks.getDeck(deck.id), isNull);
      expect(storage.canUndoCollectionOperation, isTrue);
    },
  );

  test(
    'undo and redo remain committed when their flush retries fail',
    () async {
      final deck = await _addDeck('Undo redo flush warning');
      final undoGeneration = storage.collectionUndoGeneration;
      final result = await storage.removeDeckAndChildren(deck.id);

      failFlushCount = 2;
      await storage.undoLastCollectionOperation();
      expect(storage.decks.getDeck(deck.id), isNotNull);
      expect(storage.canRedoCollectionOperation, isTrue);

      failFlushCount = 2;
      await storage.redoLastCollectionOperation();
      expect(storage.decks.getDeck(deck.id), isNull);
      expect(storage.canUndoCollectionOperation, isTrue);
      expect(result.collectionUndoGeneration, undoGeneration + 1);
    },
  );
}

Future<Deck> _addDeck(String name, {Int64? id, bool filtered = false}) async {
  final initial = filtered
      ? Deck(kind: FilteredDeckKind(deck_proto.Deck_Filtered()), name: name)
      : Deck(
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

late CollectionSqliteStorage _activeStorage;

Future<void> _addNote(Int64 id) async {
  _activeDatabase.execute(
    '''
    INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum)
    VALUES (?, ?, 1, 1, 0, '', 'front', 'front', 1)
  ''',
    [BigInt.parse(id.toString()), 'note-$id'],
  );
}

Future<void> _addCard(
  Int64 id,
  Int64 noteId,
  Int64 deckId, {
  CardQueue queue = CardQueue.newCard,
  int due = 1,
  Int64 odid = Int64.ZERO,
  int odue = 0,
}) async {
  await _activeStorage.addOrUpdateCard(
    Card(
      id: id,
      noteId: noteId,
      deckId: deckId,
      ctype: CardType.newCard,
      queue: queue,
      due: due,
      originalDeckId: odid,
      originalDue: odue,
    ),
  );
}

late Database _activeDatabase;
