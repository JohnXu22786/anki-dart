/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:io' as io;

import 'package:anki_app/app_collection_callbacks.dart';
import 'package:anki_app/collection_card_browser_controller.dart';
import 'package:anki_app/collection_runtime.dart';
import 'package:anki_app/card_browser_screen.dart';
import 'package:anki_app/l10n/app_localizations_en.dart';
import 'package:anki_backend_models/anki_backend_models.dart' as models;
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_dart/anki_dart.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late io.Directory directory;
  late CollectionRuntime runtime;
  late CollectionSqliteStorage storage;
  late SharedPreferencesAsync preferences;
  late List<Int64> noteIds;
  late List<Int64> cardIds;
  late sqlite.Database database;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
    directory = await io.Directory.systemTemp.createTemp(
      'anki-browser-preview-',
    );
    runtime = CollectionRuntime(
      locationForProfile: (_) async => '${directory.path}/collection.anki2',
      createDriver: () async => CollectionSqliteDriver(
        openDatabase: (location) => database = sqlite.sqlite3.open(location),
      ),
    );
    storage = await runtime
        .openOrCreate(
          ProfileId.defaultId,
          callbacks: (storage) =>
              appCollectionOpenCallbacks(storage, AppLocalizationsEn()),
        )
        .then((_) => runtime.storage!);
    final notetypeIds = await storage.getAllNotetypeIds();
    final notetypes = await storage.getNotetypesByIds(notetypeIds);
    final basic = notetypes.firstWhere((value) => value.name == 'Basic');
    noteIds = [];
    cardIds = [];
    for (var noteIndex = 0; noteIndex < 2; noteIndex++) {
      final note = models.Note.newNote(
        basic,
        randomU64: () => BigInt.from(noteIndex + 1),
      );
      note.setField(0, 'Question ${noteIndex + 1}');
      note.setField(1, 'Answer ${noteIndex + 1}');
      note.prepareForUpdate(basic, normalizeText: false);
      await storage.addNote(note);
      noteIds.add(note.id);
      final cardsForNote = noteIndex == 0 ? 2 : 1;
      for (var cardIndex = 0; cardIndex < cardsForNote; cardIndex++) {
        cardIds.add(
          await storage.addCard(
            models.Card.newCard(
              noteId: note.id,
              templateIdx: 0,
              deckId: Int64.ONE,
              due: cardIndex,
            ),
          ),
        );
      }
    }
  });

  tearDown(() async {
    await runtime.close();
    SharedPreferencesAsyncPlatform.instance = null;
    await directory.delete(recursive: true);
  });

  test('Cards mode loads rendered HTML in selected-card order', () async {
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    final snapshot = await controller.load();
    expect(snapshot.rows, hasLength(3));
    final selected = [snapshot.rows[2].id, snapshot.rows[0].id];
    final preview = await controller.loadPreview(selectedRows: selected);

    expect(preview.cards.map((card) => card.id), [
      selected[0].bigValue,
      selected[1].bigValue,
    ]);
    expect(preview.currentIndex, 0);
    expect(preview.cards.first.questionHtml, contains('Question 2'));
    expect(preview.cards.first.answerHtml, contains('Answer 2'));
  });

  test(
    'Cards mode previews all result rows when nothing is selected',
    () async {
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      final snapshot = await controller.load();
      final preview = await controller.loadPreview(selectedRows: const []);

      expect(preview.cards.map((card) => card.id), [
        for (final row in snapshot.rows) row.id.bigValue,
      ]);
      expect(preview.currentIndex, 0);
    },
  );

  test('Notes mode expands multiple selections and uses one card per row otherwise', () async {
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    await controller.load();
    final notesSnapshot = await controller.updateMode(BrowserColumnMode.notes);
    expect(notesSnapshot.rows, hasLength(2));

    final oneSelected = [notesSnapshot.rows.last.id];
    final singlePreview = await controller.loadPreview(
      selectedRows: oneSelected,
    );
    expect(singlePreview.cards, hasLength(2));
    expect(singlePreview.currentIndex, 1);
    expect(singlePreview.cards.map((card) => card.id), [
      BigInt.parse(
        (await storage.allCardsOfNote(noteIds.first)).first.id.toString(),
      ),
      BigInt.parse(
        (await storage.allCardsOfNote(noteIds.last)).first.id.toString(),
      ),
    ]);

    final selected = [notesSnapshot.rows.last.id, notesSnapshot.rows.first.id];
    final multiPreview = await controller.loadPreview(selectedRows: selected);
    final expected = [
      for (final noteRow in selected)
        for (final card in await storage.allCardsOfNote(
          Int64.parseInt(noteRow.bigValue.toString()),
        ))
          BigInt.parse(card.id.toString()),
    ];
    expect(multiPreview.cards.map((card) => card.id), expected);
    expect(multiPreview.currentIndex, 0);
  });

  test('stale selected row is surfaced without clamping its index', () async {
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    final snapshot = await controller.load();
    await expectLater(
      controller.loadPreview(selectedRows: const [BrowserRowId(999)]),
      throwsStateError,
    );
    expect(snapshot.rows, isNotEmpty);
  });

  test(
    'suspend and bury toggle mixed and all-selected states with exact IDs',
    () async {
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      await controller.load();
      database.execute('UPDATE col SET mod = 1');
      final largeCardId = Int64.parseInt('9007199254740997');
      final originalLargeCard = (await storage.getCard(cardIds.first))!;
      await storage.addOrUpdateCard(
        models.Card.fromProto(originalLargeCard.toProto()..id = largeCardId),
      );
      final selected = [
        BrowserRowId.bigInt(BigInt.parse(cardIds[1].toString())),
        BrowserRowId.bigInt(BigInt.parse(largeCardId.toString())),
      ];

      await storage.updateCard(
        models.Card.fromProto(
          (await storage.getCard(cardIds[1]))!.toProto()
            ..queue = models.CardQueue.suspended.value,
        ),
      );
      await controller.performBulkAction(
        CardBrowserBulkAction.suspend,
        selected,
      );
      expect(
        (await storage.getCard(cardIds[1]))!.queue,
        models.CardQueue.suspended,
      );
      expect(
        (await storage.getCard(largeCardId))!.queue,
        models.CardQueue.suspended,
      );
      expect(
        database.select('SELECT mod FROM col').single['mod'],
        greaterThan(1),
      );
      await controller.performBulkAction(
        CardBrowserBulkAction.suspend,
        selected,
      );
      expect(
        (await storage.getCard(cardIds[1]))!.queue,
        models.CardQueue.newCard,
      );
      expect(
        (await storage.getCard(largeCardId))!.queue,
        models.CardQueue.newCard,
      );

      await storage.updateCard(
        models.Card.fromProto(
          (await storage.getCard(cardIds[1]))!.toProto()
            ..queue = models.CardQueue.userBuried.value,
        ),
      );
      await controller.performBulkAction(CardBrowserBulkAction.bury, selected);
      expect(
        (await storage.getCard(cardIds[1]))!.queue,
        models.CardQueue.userBuried,
      );
      expect(
        (await storage.getCard(largeCardId))!.queue,
        models.CardQueue.userBuried,
      );
      await storage.updateCard(
        models.Card.fromProto(
          (await storage.getCard(largeCardId))!.toProto()
            ..queue = models.CardQueue.schedBuried.value,
        ),
      );
      await controller.performBulkAction(CardBrowserBulkAction.bury, selected);
      expect(
        (await storage.getCard(cardIds[1]))!.queue,
        models.CardQueue.newCard,
      );
      expect(
        (await storage.getCard(largeCardId))!.queue,
        models.CardQueue.newCard,
      );
    },
  );

  test('Notes mode actions expand selected notes to every card', () async {
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    await controller.load();
    final notes = await controller.updateMode(BrowserColumnMode.notes);
    final selectedNote = notes.rows.first.id;
    final cardsForNote = await storage.allCardsOfNote(noteIds.first);
    expect(cardsForNote, hasLength(2));
    final largeNoteId = Int64.parseInt('9007199254740999');
    final largeCardId = Int64.parseInt('9007199254741001');
    final sourceNote = (await storage.getNote(noteIds.last))!;
    final largeNote = models.Note.fromProto(
      sourceNote.toProto()..id = largeNoteId,
    );
    final notetype = (await storage.getNotetypesByIds([
      models.NotetypeId(largeNote.notetypeId),
    ])).single;
    largeNote.prepareForUpdate(notetype, normalizeText: false);
    await storage.addOrUpdateNote(largeNote);
    final sourceCard = (await storage.getCard(cardIds.last))!;
    await storage.addOrUpdateCard(
      models.Card.fromProto(
        sourceCard.toProto()
          ..id = largeCardId
          ..noteId = largeNoteId,
      ),
    );
    final currentDeck = storage.currentDeckId;

    await controller.performBulkAction(CardBrowserBulkAction.bury, [
      selectedNote,
    ]);
    for (final card in cardsForNote) {
      expect(
        (await storage.getCard(card.id))!.queue,
        models.CardQueue.userBuried,
      );
    }
    await controller.performBulkAction(CardBrowserBulkAction.suspend, [
      selectedNote,
    ]);
    for (final card in cardsForNote) {
      expect(
        (await storage.getCard(card.id))!.queue,
        models.CardQueue.suspended,
      );
    }
    await controller.performBulkAction(CardBrowserBulkAction.suspend, [
      BrowserRowId.bigInt(BigInt.parse(largeNoteId.toString())),
    ]);
    expect(
      (await storage.getCard(largeCardId))!.queue,
      models.CardQueue.suspended,
    );
    expect(storage.currentDeckId, currentDeck);
  });

  test('failed multi-card suspend rolls back and succeeds on retry', () async {
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    final snapshot = await controller.load();
    final selected = [snapshot.rows[0].id, snapshot.rows[1].id];
    database.execute('''
      CREATE TRIGGER fail_bulk_action BEFORE UPDATE ON cards
      WHEN OLD.id = ${cardIds[1]}
      BEGIN SELECT RAISE(ABORT, 'injected bulk update failure'); END
    ''');

    await expectLater(
      controller.performBulkAction(CardBrowserBulkAction.suspend, selected),
      throwsA(isA<Object>()),
    );
    for (final id in cardIds.take(2)) {
      expect((await storage.getCard(id))!.queue, models.CardQueue.newCard);
    }

    database.execute('DROP TRIGGER fail_bulk_action');
    await controller.performBulkAction(CardBrowserBulkAction.suspend, selected);
    for (final id in cardIds.take(2)) {
      expect((await storage.getCard(id))!.queue, models.CardQueue.suspended);
    }
  });

  test(
    'bulk suspend undo restores exact queues and leaves current deck alone',
    () async {
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      final snapshot = await controller.load();
      final selected = [snapshot.rows[0].id, snapshot.rows[1].id];
      final before = [
        for (final id in cardIds.take(2)) (await storage.getCard(id))!,
      ];
      final currentDeck = storage.currentDeckId;

      await controller.performBulkAction(
        CardBrowserBulkAction.suspend,
        selected,
      );
      expect(controller.canUndoCollectionOperation, isTrue);
      for (final id in cardIds.take(2)) {
        expect((await storage.getCard(id))!.queue, models.CardQueue.suspended);
      }

      await controller.undoLastCollectionOperation();
      for (var index = 0; index < before.length; index++) {
        expect(
          (await storage.getCard(before[index].id))!.queue,
          before[index].queue,
        );
      }
      expect(controller.canUndoCollectionOperation, isFalse);
      expect(storage.currentDeckId, currentDeck);
    },
  );

  test('later collection mutation invalidates the bulk undo step', () async {
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    final snapshot = await controller.load();
    await controller.performBulkAction(CardBrowserBulkAction.suspend, [
      snapshot.rows.first.id,
    ]);
    expect(controller.canUndoCollectionOperation, isTrue);

    await storage.updateCard((await storage.getCard(cardIds.last))!);

    expect(controller.canUndoCollectionOperation, isFalse);
  });

  test(
    'bury undo preserves a suspended card within a mixed selection',
    () async {
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      final snapshot = await controller.load();
      final selected = [snapshot.rows[0].id, snapshot.rows[1].id];
      final suspended = models.Card.fromProto(
        (await storage.getCard(cardIds.first))!.toProto()
          ..queue = models.CardQueue.suspended.value,
      );
      await storage.updateCard(suspended);
      final before = [
        (await storage.getCard(cardIds.first))!,
        (await storage.getCard(cardIds[1]))!,
      ];

      await controller.performBulkAction(CardBrowserBulkAction.bury, selected);
      expect(
        (await storage.getCard(cardIds.first))!.queue,
        models.CardQueue.suspended,
      );
      expect(
        (await storage.getCard(cardIds[1]))!.queue,
        models.CardQueue.userBuried,
      );

      await controller.undoLastCollectionOperation();
      for (final card in before) {
        expect((await storage.getCard(card.id))!.queue, card.queue);
      }
    },
  );

  test(
    'deleting a selected card deletes its note and refreshes the active search',
    () async {
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      final snapshot = await controller.search('Question 1');
      expect(snapshot.rows, hasLength(2));
      final currentDeck = storage.currentDeckId;
      database.execute('UPDATE col SET mod = 1');

      await controller.performBulkAction(CardBrowserBulkAction.delete, [
        snapshot.rows.first.id,
      ]);
      final refreshed = await controller.refresh();

      expect(await storage.getNote(noteIds.first), isNull);
      expect(await storage.allCardsOfNote(noteIds.first), isEmpty);
      expect(refreshed.rows, isEmpty);
      expect(
        database.select('SELECT mod FROM col').single['mod'],
        greaterThan(1),
      );
      expect(storage.currentDeckId, currentDeck);
    },
  );

  test(
    'delete undo restores notes, sibling cards, and review history losslessly',
    () async {
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      final snapshot = await controller.search('Question 1');
      final note = (await storage.getNote(noteIds.first))!;
      final cards = await storage.allCardsOfNote(noteIds.first);
      final revlog = models.RevlogEntry(
        id: models.RevlogId(Int64.parseInt('9007199254741123')),
        cardId: cards.first.id,
        usn: -1,
        buttonChosen: 3,
        interval: 17,
        lastInterval: 8,
        easeFactor: 2500,
        takenMillis: 1234,
        reviewKind: models.RevlogReviewKind.review,
      );
      storage.revlog.addRevlogEntry(revlog);
      final currentDeck = storage.currentDeckId;

      await controller.performBulkAction(CardBrowserBulkAction.delete, [
        snapshot.rows.first.id,
      ]);
      expect(await storage.getNote(note.id), isNull);
      expect(storage.revlog.getRevlogEntry(revlog.id), isNull);

      await controller.undoLastCollectionOperation();
      expect(
        (await storage.getNote(note.id))!.toProto().writeToBuffer(),
        note.toProto().writeToBuffer(),
      );
      expect(await storage.allCardsOfNote(note.id), hasLength(cards.length));
      final restoredReview = storage.revlog.getRevlogEntry(revlog.id)!;
      expect(
        restoredReview.toProto().writeToBuffer(),
        revlog.toProto().writeToBuffer(),
      );
      expect(storage.currentDeckId, currentDeck);
    },
  );

  test(
    'Notes mode delete follows AnkiDroid card-ID mapping for cardless notes',
    () async {
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      await controller.load();
      await controller.updateMode(BrowserColumnMode.notes);
      final notetypes = await storage.getNotetypesByIds(
        await storage.getAllNotetypeIds(),
      );
      final basic = notetypes.firstWhere((value) => value.name == 'Basic');
      final orphan = models.Note.newNote(
        basic,
        randomU64: () => BigInt.from(99),
      );
      orphan.setField(0, 'Orphaned question');
      orphan.setField(1, 'Orphaned answer');
      orphan.prepareForUpdate(basic, normalizeText: false);
      await storage.addNote(orphan);

      await controller.performBulkAction(CardBrowserBulkAction.delete, [
        BrowserRowId.bigInt(BigInt.parse(orphan.id.toString())),
      ]);
      expect((await storage.getNote(orphan.id))!.fields, [
        'Orphaned question',
        'Orphaned answer',
      ]);
      expect(await storage.allCardsOfNote(orphan.id), isEmpty);
    },
  );

  test('empty bulk selection leaves collection data unchanged', () async {
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    await controller.load();
    for (final action in CardBrowserBulkAction.values) {
      await controller.performBulkAction(action, const []);
    }
    for (final id in cardIds) {
      expect((await storage.getCard(id))!.queue, models.CardQueue.newCard);
    }
    for (final id in noteIds) {
      expect(await storage.getNote(id), isNotNull);
    }
  });

  test(
    'Notes mode loads retained selections outside current results',
    () async {
      final currentNote = BrowserRowId.bigInt(
        BigInt.parse(noteIds.last.toString()),
      );
      final retainedNote = BrowserRowId.bigInt(
        BigInt.parse(noteIds.first.toString()),
      );
      final preview = await CollectionCardBrowserPreviewLoader(runtime).load(
        mode: BrowserColumnMode.notes,
        rowIds: [currentNote],
        selectedRows: [retainedNote, currentNote],
      );
      final expected = [
        for (final noteId in [noteIds.first, noteIds.last])
          for (final card in await storage.allCardsOfNote(noteId))
            BigInt.parse(card.id.toString()),
      ];

      expect(preview.cards.map((card) => card.id), expected);
      expect(preview.currentIndex, 0);
    },
  );
}
