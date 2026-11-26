// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CollectionSqliteStorage storage;
  late Database database;

  setUp(() async {
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => database = sqlite3.openInMemory(),
      ),
      location: ':memory:',
    );
    await storage.executeBatch('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY, nid INTEGER NOT NULL, did INTEGER NOT NULL,
        ord INTEGER NOT NULL, mod INTEGER NOT NULL, usn INTEGER NOT NULL,
        type INTEGER NOT NULL, queue INTEGER NOT NULL, due INTEGER NOT NULL,
        ivl INTEGER NOT NULL, factor INTEGER NOT NULL, reps INTEGER NOT NULL,
        lapses INTEGER NOT NULL, left INTEGER NOT NULL, odue INTEGER NOT NULL,
        odid INTEGER NOT NULL, flags INTEGER NOT NULL, data TEXT NOT NULL
      );
      CREATE TABLE revlog (
        id INTEGER PRIMARY KEY, cid INTEGER NOT NULL, usn INTEGER NOT NULL,
        ease INTEGER NOT NULL, ivl INTEGER NOT NULL, lastIvl INTEGER NOT NULL,
        factor INTEGER NOT NULL, time INTEGER NOT NULL, type INTEGER NOT NULL
      );
      INSERT INTO cards VALUES (41, 12, 13, 0, 1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, '{}');
    ''');
  });

  tearDown(() async => storage.close());

  test(
    'persists one answer and undo/redo restores both supplied rows',
    () async {
      final before = await storage.getCard(Int64(41));
      final suppliedCard = _card(id: 41, due: 27);
      final entry = _revlog(id: 1712345678000, cardId: 41);

      await storage.recordCardAnswerResult(card: suppliedCard, revlog: entry);

      expect((await storage.getCard(Int64(41)))!.due, 27);
      expect(storage.revlog.getRevlogEntry(entry.id)!.cardId, Int64(41));
      expect(storage.collectionUndoLabel, 'answerCard');
      expect(
        storage.collectionUndoChanges.map((change) => change.kind),
        containsAll([
          CollectionUndoChangeKind.card,
          CollectionUndoChangeKind.revlog,
        ]),
      );

      await storage.undoLastCollectionOperation();
      expect((await storage.getCard(Int64(41)))!.due, before!.due);
      expect(storage.revlog.getRevlogEntry(entry.id), isNull);

      await storage.redoLastCollectionOperation();
      expect((await storage.getCard(Int64(41)))!.due, 27);
      expect(storage.revlog.getRevlogEntry(entry.id)!.cardId, Int64(41));
    },
  );

  test(
    'adds a persisted review result to the supplied home-config cache',
    () async {
      final preset = Int64(77);
      final context = _loadBalancerContext(preset);
      final answeredCard = _card(
        id: 41,
        due: 27,
        queue: CardQueue.review,
        interval: 7,
      );

      await storage.recordCardAnswerResult(
        card: answeredCard,
        revlog: _revlog(id: 1712345678010, cardId: 41),
        loadBalancerContext: context,
        homeDeckConfigId: preset,
      );

      final day = context.cache.daysByPreset[preset]![7];
      expect(day.cardCount, 1);
      expect(day.hasSibling(Int64(12)), isTrue);
      expect(context.cache.daysByPreset[preset]![27].cardCount, 0);
      expect((await storage.getCard(Int64(41)))!.interval, 7);
      context.cache.removeCard(Int64(99));
      expect(day.cardCount, 1);
      context.cache.removeCard(Int64(41));
      expect(day.cardCount, 0);
    },
  );

  test('ignores non-review results and missing home-config IDs', () async {
    final preset = Int64(77);
    final context = _loadBalancerContext(preset);

    await storage.recordCardAnswerResult(
      card: _card(id: 41, due: 27, queue: CardQueue.learn, interval: 7),
      revlog: _revlog(id: 1712345678011, cardId: 41),
      loadBalancerContext: context,
      homeDeckConfigId: preset,
    );
    await storage.recordCardAnswerResult(
      card: _card(id: 41, due: 27, queue: CardQueue.review, interval: 8),
      revlog: _revlog(id: 1712345678012, cardId: 41),
      loadBalancerContext: context,
      homeDeckConfigId: null,
    );

    expect(context.cache.daysByPreset[preset]![7].cardCount, 0);
    expect(context.cache.daysByPreset[preset]![8].cardCount, 0);
  });

  test('card update failure preserves the prior review cache', () async {
    final preset = Int64(77);
    final context = _loadBalancerContext(preset);
    context.addAnsweredReviewCard(
      _card(id: 55, due: 0, queue: CardQueue.review, interval: 3),
      preset,
    );
    await storage.executeBatch('''
      CREATE TRIGGER reject_answer_card BEFORE UPDATE ON cards
      BEGIN SELECT RAISE(ABORT, 'blocked'); END;
    ''');

    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27, queue: CardQueue.review, interval: 7),
        revlog: _revlog(id: 1712345678013, cardId: 41),
        loadBalancerContext: context,
        homeDeckConfigId: preset,
      ),
      throwsA(isA<SqliteException>()),
    );

    expect(context.cache.daysByPreset[preset]![3].cardCount, 1);
    expect(context.cache.daysByPreset[preset]![7].cardCount, 0);
    expect(
      context.cache.daysByPreset[preset]![3].hasSibling(Int64(12)),
      isTrue,
    );
    expect(
      context.cache.daysByPreset[preset]![7].hasSibling(Int64(12)),
      isFalse,
    );
  });

  test('revlog collision preserves the prior review cache', () async {
    final preset = Int64(77);
    final context = _loadBalancerContext(preset);
    final existing = _revlog(id: 1712345678014, cardId: 41);
    storage.revlog.addRevlogEntry(existing);
    context.addAnsweredReviewCard(
      _card(id: 55, due: 0, queue: CardQueue.review, interval: 3),
      preset,
    );

    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27, queue: CardQueue.review, interval: 7),
        revlog: existing,
        loadBalancerContext: context,
        homeDeckConfigId: preset,
      ),
      throwsA(isA<StateError>()),
    );

    expect(context.cache.daysByPreset[preset]![3].cardCount, 1);
    expect(context.cache.daysByPreset[preset]![7].cardCount, 0);
    expect(
      context.cache.daysByPreset[preset]![3].hasSibling(Int64(12)),
      isTrue,
    );
    expect(
      context.cache.daysByPreset[preset]![7].hasSibling(Int64(12)),
      isFalse,
    );
  });

  test(
    'unchanged card values still persist a distinct answer revlog',
    () async {
      final before = await storage.getCard(Int64(41));
      final entry = _revlog(id: 1712345678001, cardId: 41);

      await storage.recordCardAnswerResult(card: before!, revlog: entry);

      expect((await storage.getCard(Int64(41)))!.due, before.due);
      expect(storage.revlog.getRevlogEntry(entry.id)!.cardId, Int64(41));
      expect(storage.collectionUndoLabel, 'answerCard');
      await storage.undoLastCollectionOperation();
      expect(storage.revlog.getRevlogEntry(entry.id), isNull);
      expect((await storage.getCard(Int64(41)))!.due, before.due);
    },
  );

  test('mismatched and missing card IDs fail without mutation', () async {
    final generation = storage.collectionUndoGeneration;
    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27),
        revlog: _revlog(id: 1712345678002, cardId: 42),
      ),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 99, due: 27),
        revlog: _revlog(id: 1712345678003, cardId: 99),
      ),
      throwsA(isA<StateError>()),
    );

    expect((await storage.getCard(Int64(41)))!.due, 4);
    expect(await storage.getCard(Int64(99)), isNull);
    expect(database.select('SELECT id FROM revlog'), isEmpty);
    expect(storage.collectionUndoGeneration, generation);
  });

  test('revlog collision rolls back the supplied card update', () async {
    final existing = _revlog(id: 1712345678004, cardId: 41);
    storage.revlog.addRevlogEntry(existing);
    final generation = storage.collectionUndoGeneration;

    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27),
        revlog: existing,
      ),
      throwsA(isA<StateError>()),
    );

    expect((await storage.getCard(Int64(41)))!.due, 4);
    expect(storage.revlog.getRevlogEntry(existing.id)!.cardId, Int64(41));
    expect(database.select('SELECT id FROM revlog'), hasLength(1));
    expect(storage.collectionUndoGeneration, generation);
  });

  test('card update failure rolls back before inserting the revlog', () async {
    await storage.executeBatch('''
      CREATE TRIGGER reject_answer_card BEFORE UPDATE ON cards
      BEGIN SELECT RAISE(ABORT, 'blocked'); END;
    ''');
    final entry = _revlog(id: 1712345678005, cardId: 41);
    final generation = storage.collectionUndoGeneration;

    await expectLater(
      storage.recordCardAnswerResult(
        card: _card(id: 41, due: 27),
        revlog: entry,
      ),
      throwsA(isA<SqliteException>()),
    );

    expect((await storage.getCard(Int64(41)))!.due, 4);
    expect(storage.revlog.getRevlogEntry(entry.id), isNull);
    expect(storage.collectionUndoGeneration, generation);
  });

  test(
    'a suppressed card update rolls back instead of writing only revlog',
    () async {
      await storage.executeBatch('''
      CREATE TRIGGER ignore_answer_card BEFORE UPDATE ON cards
      BEGIN SELECT RAISE(IGNORE); END;
    ''');
      final entry = _revlog(id: 1712345678006, cardId: 41);
      final generation = storage.collectionUndoGeneration;

      await expectLater(
        storage.recordCardAnswerResult(
          card: _card(id: 41, due: 27),
          revlog: entry,
        ),
        throwsA(isA<StateError>()),
      );

      expect((await storage.getCard(Int64(41)))!.due, 4);
      expect(storage.revlog.getRevlogEntry(entry.id), isNull);
      expect(storage.collectionUndoGeneration, generation);
    },
  );
}

Card _card({
  required int id,
  required int due,
  CardQueue queue = CardQueue.newCard,
  int interval = 0,
}) => Card(
  id: Int64(id),
  noteId: Int64(12),
  deckId: Int64(13),
  mtimeSecs: Int64(1),
  due: due,
  queue: queue,
  interval: interval,
);

RevlogEntry _revlog({required int id, required int cardId}) => RevlogEntry(
  id: RevlogId(Int64(id)),
  cardId: Int64(cardId),
  usn: -1,
  buttonChosen: 3,
  interval: 8,
  lastInterval: 4,
  easeFactor: 2500,
  takenMillis: 1200,
  reviewKind: RevlogReviewKind.review,
);

CollectionLoadBalancerContext _loadBalancerContext(DeckConfigId preset) {
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
