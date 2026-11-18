/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:io' as io;

import 'package:anki_app/app_collection_callbacks.dart';
import 'package:anki_app/collection_card_browser_controller.dart';
import 'package:anki_app/collection_runtime.dart';
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

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
    directory = await io.Directory.systemTemp.createTemp(
      'anki-browser-preview-',
    );
    runtime = CollectionRuntime(
      locationForProfile: (_) async => '${directory.path}/collection.anki2',
      createDriver: () async =>
          CollectionSqliteDriver(openDatabase: sqlite.sqlite3.open),
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
