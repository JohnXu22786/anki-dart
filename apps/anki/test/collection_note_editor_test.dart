/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:io' as io;

import 'package:anki_app/app_collection_callbacks.dart';
import 'package:anki_app/collection_card_browser_controller.dart';
import 'package:anki_app/deck_picker_repository.dart';
import 'package:anki_app/collection_runtime.dart';
import 'package:anki_app/deck_picker_screen.dart';
import 'package:anki_app/l10n/app_localizations_en.dart';
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:anki_dart/anki_dart.dart';
import 'package:fixnum/fixnum.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy deck mid parses exact numeric Int64 JSON tokens', () {
    expect(
      legacyDeckNotetypeIdFromJsonBytes(
        utf8.encode('{"nested":{"mid":7},"mid":9007199254740993}'),
      ),
      Int64.parseInt('9007199254740993'),
    );
    expect(
      legacyDeckNotetypeIdFromJsonBytes(
        utf8.encode('{"mid":"9007199254740993"}'),
      ),
      Int64.parseInt('9007199254740993'),
    );
    expect(
      legacyDeckNotetypeIdFromJsonBytes(utf8.encode('{"nested":{"mid":7}}')),
      isNull,
    );
    expect(
      legacyDeckNotetypeIdFromJsonBytes(utf8.encode('{"mid"::7}')),
      isNull,
    );
  });

  late io.Directory directory;
  late CollectionRuntime runtime;
  late SharedPreferencesAsync preferences;
  var flushFails = false;
  var flushCalls = 0;

  setUp(() async {
    flushFails = false;
    flushCalls = 0;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
    directory = await io.Directory.systemTemp.createTemp('anki-note-editor-');
    runtime = CollectionRuntime(
      locationForProfile: (_) async => '${directory.path}/collection.anki2',
      createDriver: () async => CollectionSqliteDriver(
        openDatabase: sqlite.sqlite3.open,
        flush: () {
          flushCalls++;
          if (flushFails) throw StateError('test flush failed');
        },
      ),
    );
    await runtime.openOrCreate(
      ProfileId.defaultId,
      callbacks: (storage) =>
          appCollectionOpenCallbacks(storage, AppLocalizationsEn()),
    );
  });

  tearDown(() async {
    await runtime.close();
    SharedPreferencesAsyncPlatform.instance = null;
    await directory.delete(recursive: true);
  });

  test(
    'Deck Picker Add Card carries the exact selected 64-bit deck ID',
    () async {
      final storage = runtime.storage!;
      final wideDeckId = Int64(9007199254740995);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: wideDeckId,
          name: 'Deck Picker wide ID',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      final repository = CollectionDeckPickerRepository(runtime);
      final port = await repository.selectDeckAndCreateNewNotePort(
        DeckPickerDeck(
          id: 42,
          exactId: wideDeckId,
          name: 'Deck Picker wide ID',
        ),
      );

      expect(storage.currentDeckId, wideDeckId);
      expect((await port.loadNewNote()).deckId, wideDeckId);
    },
  );

  test(
    'Deck Picker shortcut keeps the collection current deck ID exact',
    () async {
      final storage = runtime.storage!;
      final wideDeckId = Int64(9007199254740995);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: wideDeckId,
          name: 'Shortcut current deck',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      await storage.selectDeck(wideDeckId);

      final repository = CollectionDeckPickerRepository(runtime);
      final port = await repository.createNewNotePortForCurrentDeck();

      expect(storage.currentDeckId, wideDeckId);
      expect((await port.loadNewNote()).deckId, wideDeckId);
    },
  );

  test(
    'Deck Picker Browse Cards preserves exact ID without selecting it',
    () async {
      final storage = runtime.storage!;
      final wideDeckId = Int64(9007199254740995);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: wideDeckId,
          name: 'Browser wide ID',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );

      final repository = CollectionDeckPickerRepository(runtime);
      final currentDeckId = storage.currentDeckId;
      await repository.selectDeckForBrowse(
        DeckPickerDeck(id: 8, exactId: wideDeckId, name: 'Browser wide ID'),
      );

      expect(storage.currentDeckId, currentDeckId);
    },
  );

  test('Deck Picker empty filtered action preserves exact deck ID', () async {
    final storage = runtime.storage!;
    final filteredId = Int64.parseInt('9007199254740995');
    storage.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: filteredId,
        name: 'Filtered wide ID',
        kind: FilteredDeckKind(deck_proto.Deck_Filtered()),
      ),
    );
    await storage.addOrUpdateCard(
      Card(
        id: Int64(777),
        deckId: filteredId,
        ctype: CardType.review,
        queue: CardQueue.review,
        due: -10,
        originalDeckId: Int64.ONE,
        originalDue: 25,
      ),
    );

    final repository = CollectionDeckPickerRepository(runtime);
    await repository.emptyFilteredDeck(
      DeckPickerDeck(id: 42, exactId: filteredId, name: 'Filtered wide ID'),
    );

    final restored = (await storage.getCard(Int64(777)))!;
    expect(restored.deckId, Int64.ONE);
    expect(restored.due, 25);
    expect(restored.originalDeckId, Int64.ZERO);
  });

  test(
    'deck rename moves descendants and preserves selection and IDs',
    () async {
      final storage = runtime.storage!;
      final parentId = Int64(9007199254740995);
      final childId = Int64(61);
      final grandchildId = Int64(62);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: parentId,
          name: 'Old root',
          common: deck_proto.Deck_Common(studyCollapsed: false),
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: childId,
          name: 'Old root::Child',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: grandchildId,
          name: 'Old root::Child::Leaf',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      await storage.selectDeck(childId);

      final repository = CollectionDeckPickerRepository(runtime);
      await repository.renameDeck(
        DeckPickerDeck(id: 60, exactId: parentId, name: 'Old root'),
        'New parent::New root',
      );

      expect(storage.decks.getDeck(parentId)!.name, 'New parent::New root');
      expect(
        storage.decks.getDeck(childId)!.name,
        'New parent::New root::Child',
      );
      expect(
        storage.decks.getDeck(grandchildId)!.name,
        'New parent::New root::Child::Leaf',
      );
      expect(storage.decks.getDeck(parentId)!.common.studyCollapsed, isFalse);
      expect(storage.decks.getDeckId('Old root'), isNull);
      expect(storage.decks.getDeckId('New parent'), isNotNull);
      expect(storage.currentDeckId, childId);

      await repository.loadDecks();
      expect(
        storage.decks.getDeck(childId)!.name,
        'New parent::New root::Child',
      );
    },
  );

  test(
    'deck rename normalizes names and rejects duplicates and filtered paths',
    () async {
      final storage = runtime.storage!;
      final sourceId = Int64(70);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: sourceId,
          name: 'Source',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      final targetId = Int64(71);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: targetId,
          name: 'Target',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      final filteredId = Int64(72);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: filteredId,
          name: 'Filtered parent',
          kind: FilteredDeckKind(deck_proto.Deck_Filtered()),
        ),
      );
      final repository = CollectionDeckPickerRepository(runtime);
      final pickerDeck = DeckPickerDeck(
        id: sourceId.toInt(),
        exactId: sourceId,
        name: 'Source',
      );

      expect(repository.isDeckNameAvailable(pickerDeck, ' target '), isFalse);
      await expectLater(
        storage.renameDeck(sourceId, ' target '),
        throwsStateError,
      );
      expect(await storage.renameDeck(sourceId, ' Source '), isFalse);
      await expectLater(
        storage.renameDeck(sourceId, 'Filtered parent::Moved'),
        throwsStateError,
      );
      await expectLater(
        storage.renameDeck(sourceId, 'source::Moved'),
        throwsStateError,
      );
      expect(storage.decks.getDeck(sourceId)!.name, 'Source');
      expect(storage.decks.getDeck(targetId)!.name, 'Target');
    },
  );

  test(
    'deck rename handles missing IDs and retries after flush failure',
    () async {
      final storage = runtime.storage!;
      await expectLater(
        storage.renameDeck(Int64(9999), 'Missing'),
        throwsStateError,
      );
      await expectLater(
        storage.renameDeck(Int64.ONE, '  '),
        throwsArgumentError,
      );

      final sourceId = Int64(80);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: sourceId,
          name: 'Retry source',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      flushFails = true;
      await expectLater(
        storage.renameDeck(sourceId, 'Retry target'),
        throwsStateError,
      );
      expect(storage.decks.getDeck(sourceId)!.name, 'Retry target');

      flushFails = false;
      expect(await storage.renameDeck(sourceId, 'Retry target'), isFalse);
      expect(flushCalls, greaterThanOrEqualTo(2));
      expect(storage.decks.getDeck(sourceId)!.name, 'Retry target');
    },
  );

  test(
    'resolves a wide card ID and saves normalized fields to its note',
    () async {
      final storage = runtime.storage!;
      final notetype = (await storage.getNotetypesByIds(
        await storage.getAllNotetypeIds(),
      )).firstWhere((type) => type.name == 'Basic');
      final noteId = Int64.parseInt('9007199254740995');
      final cardId = Int64.parseInt('9007199254740997');
      final note = Note(
        id: noteId,
        guid: 'editor-wide-id',
        notetypeId: notetype.id.value,
        fields: ['original', 'back'],
      )..prepareForUpdate(notetype, normalizeText: false);
      note.tags.add('kept');
      await storage.addOrUpdateNote(note);
      expect(
        await storage.addCardIfUnique(
          Card(id: cardId, noteId: noteId, deckId: Int64.ONE),
        ),
        isTrue,
      );

      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      await controller.load();
      expect(
        await controller.resolveNoteIdForRow(
          BrowserRowId.bigInt(BigInt.parse('$cardId')),
        ),
        noteId,
      );
      await controller.saveFields(noteId, ['e\u0301dit', 'updated back']);

      final saved = await storage.getNote(noteId);
      expect(saved!.fields, ['édit', 'updated back']);
      expect(saved.tags, ['kept']);
      expect(saved.checksum, isNotNull);
      await expectLater(
        controller.saveFields(noteId, ['wrong field count']),
        throwsStateError,
      );

      await controller.updateMode(BrowserColumnMode.notes);
      expect(
        await controller.resolveNoteIdForRow(
          BrowserRowId.bigInt(BigInt.parse('$noteId')),
        ),
        noteId,
      );
    },
  );

  test('does not substitute a missing notetype when saving', () async {
    final storage = runtime.storage!;
    final note =
        Note(
          id: Int64.parseInt('9007199254741001'),
          guid: 'missing-notetype',
          notetypeId: Int64(987654321),
          fields: ['field'],
        )..prepareForUpdate(
          Notetype(
            id: NotetypeId(Int64(987654321)),
            config: Notetype.defaultConfig(),
          ),
          normalizeText: false,
        );
    await storage.addOrUpdateNote(note);

    await expectLater(
      CollectionCardBrowserController(runtime).saveFields(note.id, ['edited']),
      throwsStateError,
    );
  });

  test('loads collection tags and saves tag-only edits with undo', () async {
    final storage = runtime.storage!;
    final notetype = (await storage.getNotetypesByIds(
      await storage.getAllNotetypeIds(),
    )).firstWhere((type) => type.name == 'Basic');
    final note = Note(
      id: Int64(52),
      guid: 'tag-only-editor-update',
      notetypeId: notetype.id.value,
      fields: ['front', 'back'],
    )..prepareForUpdate(notetype, normalizeText: false);
    note.tags.addAll(['Existing']);
    await storage.addOrUpdateNote(note);
    storage.tags.registerTag(Tag(name: 'Known', usn: -1, expanded: true));
    final controller = CollectionCardBrowserController(runtime);

    final content = await controller.loadNote(note.id);
    expect(content.tags, ['Existing']);
    expect(content.availableTags, contains('Known'));
    await controller.saveNote(note.id, note.fields, [
      'Existing',
      'New::Child',
      'new::child',
    ]);

    final editedTags = (await storage.getNote(note.id))!.tags;
    expect(editedTags, contains('Existing'));
    expect(
      editedTags.where((tag) => tag.toLowerCase() == 'new::child'),
      hasLength(1),
    );
    expect(controller.canUndoNoteUpdate, isTrue);
    await controller.undoLastNoteUpdate();
    expect((await storage.getNote(note.id))!.tags, ['Existing']);
  });

  test('unchanged tags do not write and failed saves can be retried', () async {
    final storage = runtime.storage!;
    final notetype = (await storage.getNotetypesByIds(
      await storage.getAllNotetypeIds(),
    )).firstWhere((type) => type.name == 'Basic');
    final note = Note(
      id: Int64(53),
      guid: 'unchanged-editor-tags',
      notetypeId: notetype.id.value,
      fields: ['front', 'back'],
    )..prepareForUpdate(notetype, normalizeText: false);
    note.tags.addAll(['a::z', 'a-b']);
    await storage.addOrUpdateNote(note);
    final controller = CollectionCardBrowserController(runtime);

    await controller.saveNote(note.id, note.fields, ['a::z', 'a-b']);
    expect(controller.canUndoNoteUpdate, isFalse);
    await controller.saveFields(note.id, ['edited', 'back']);
    expect(
      (await storage.getNote(note.id))!.tags,
      unorderedEquals(['a::z', 'a-b']),
    );
  });

  test('repeated editor saves coalesce to one note-update undo', () async {
    final storage = runtime.storage!;
    final notetype = (await storage.getNotetypesByIds(
      await storage.getAllNotetypeIds(),
    )).firstWhere((type) => type.name == 'Basic');
    final note = Note(
      id: Int64(42),
      guid: 'coalesced-editor-edits',
      notetypeId: notetype.id.value,
      fields: ['original', 'back'],
    )..prepareForUpdate(notetype, normalizeText: false);
    await storage.addOrUpdateNote(note);
    await storage.addCardIfUnique(
      Card(id: Int64(142), noteId: note.id, deckId: Int64.ONE),
    );
    final controller = CollectionCardBrowserController(runtime);

    await controller.saveFields(note.id, ['first edit', 'back']);
    await controller.saveFields(note.id, ['second edit', 'back']);
    expect(controller.canUndoNoteUpdate, isTrue);

    await controller.undoLastNoteUpdate();

    expect((await storage.getNote(note.id))!.fields, ['original', 'back']);
    expect(controller.canUndoNoteUpdate, isFalse);
  });

  test(
    'new-note defaults use current deck mid and safe deck fallbacks',
    () async {
      final storage = runtime.storage!;
      final allTypes = await storage.getNotetypesByIds(
        await storage.getAllNotetypeIds(),
      );
      final basic = allTypes.singleWhere((type) => type.name == 'Basic');
      final cloze = allTypes.singleWhere((type) => type.name == 'Cloze');
      await storage.writeCollectionConfig('curModel', basic.id.value.toInt());

      final currentDeck = storage.decks.addDeck(
        Deck(
          name: 'Current',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
          common: deck_proto.Deck_Common(
            other: utf8.encode(jsonEncode({'mid': cloze.id.value.toInt()})),
          ),
        ),
      );
      final rememberedDeck = storage.decks.addDeck(
        Deck(
          name: 'Remembered',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      final filteredDeck = storage.decks.addDeck(
        Deck(
          name: 'Filtered',
          kind: FilteredDeckKind(deck_proto.Deck_Filtered()),
        ),
      );
      await storage.selectDeck(currentDeck.id);

      final currentDeckController = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
        selectedNewNoteDeckId: () => filteredDeck.id,
      );
      final sourceDefaults = await currentDeckController.loadNewNote();
      expect(sourceDefaults.notetypeId, cloze.id.value);
      expect(sourceDefaults.deckId, currentDeck.id);
      expect(sourceDefaults.content.labels, ['Text', 'Back Extra']);
      expect(sourceDefaults.content.values, ['', '']);

      await storage.writeCollectionConfig('addToCur', false);
      await storage.writeCollectionConfig(
        '_nt_${cloze.id.value}_lastDeck',
        rememberedDeck.id.toInt(),
      );
      final rememberedDefaults = await CollectionCardBrowserController(
        runtime,
        preferences: preferences,
        selectedNewNoteDeckId: () => Int64(987654321),
      ).loadNewNote();
      expect(rememberedDefaults.notetypeId, cloze.id.value);
      expect(rememberedDefaults.deckId, rememberedDeck.id);
      final noBrowserOverride = await CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      ).loadNewNote();
      expect(noBrowserOverride.deckId, rememberedDeck.id);

      final wideDeckId = Int64(9007199254740995);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: wideDeckId,
          name: 'Wide remembered deck',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      await storage.selectDeck(wideDeckId);
      expect(storage.currentDeckId, wideDeckId);
      await storage.writeCollectionConfig('addToCur', true);
      final wideCurrentDefault = await CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      ).loadNewNote();
      expect(wideCurrentDefault.deckId, wideDeckId);

      await storage.addNoteToDeck(
        Note(notetypeId: cloze.id.value, fields: ['{{c1::wide}}', 'back']),
        wideDeckId,
      );
      await storage.selectDeck(currentDeck.id);
      await storage.writeCollectionConfig('addToCur', false);
      final wideRememberedDefault = await CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      ).loadNewNote();
      expect(wideRememberedDefault.notetypeId, cloze.id.value);
      expect(wideRememberedDefault.deckId, wideDeckId);

      await storage.writeCollectionConfig('curModel', cloze.id.value.toInt());
      final staleMidDeck = storage.decks.addDeck(
        Deck(
          name: 'Stale note type',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
          common: deck_proto.Deck_Common(
            other: utf8.encode(jsonEncode({'mid': 987654321})),
          ),
        ),
      );
      await storage.selectDeck(staleMidDeck.id);
      final staleMidDefaults = await CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      ).loadNewNote();
      expect(staleMidDefaults.notetypeId, cloze.id.value);
    },
  );

  test(
    'Card Browser Add Note uses its remembered deck without selecting it',
    () async {
      final storage = runtime.storage!;
      final currentDeckId = storage.currentDeckId;
      final rememberedDeckId = Int64.parseInt('9007199254740995');
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: rememberedDeckId,
          name: 'Remembered browser deck',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      final browser = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      await browser.load();
      await browser.selectBrowserDeck(rememberedDeckId);

      final draft = await browser.loadNewNote();

      expect(draft.deckId, rememberedDeckId);
      expect(storage.currentDeckId, currentDeckId);
      expect(
        await preferences.getString('anki.browser.lastDeckId'),
        '9007199254740995',
      );
    },
  );

  test('Card Browser Add Note falls back for All Decks and unusable remembered IDs', () async {
    final storage = runtime.storage!;
    final currentDeckId = storage.currentDeckId;
    final filteredDeck = storage.decks.addDeck(
      Deck(
        name: 'Filtered browser deck',
        kind: FilteredDeckKind(deck_proto.Deck_Filtered()),
      ),
    );
    final missingDeckId = Int64(987654321);
    final browser = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    await browser.load();
    final cases = <String>[
      '-1',
      'not-an-int64',
      missingDeckId.toString(),
      filteredDeck.id.toString(),
    ];

    for (final rememberedId in cases) {
      await preferences.setString('anki.browser.lastDeckId', rememberedId);
      final draft = await browser.loadNewNote();
      expect(draft.deckId, currentDeckId, reason: 'rememberedId=$rememberedId');
    }

    storage.decks.removeDeck(filteredDeck.id);
    await preferences.setString(
      'anki.browser.lastDeckId',
      filteredDeck.id.toString(),
    );
    final deletedDeckDraft = await browser.loadNewNote();
    expect(deletedDeckDraft.deckId, currentDeckId);
    expect(storage.currentDeckId, currentDeckId);
  });

  test(
    'explicit Deck Picker deck takes precedence over remembered browser deck',
    () async {
      final storage = runtime.storage!;
      final currentDeckId = storage.currentDeckId;
      final browserDeckId = storage.decks
          .addDeck(
            Deck(
              name: 'Browser remembered deck',
              kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
            ),
          )
          .id;
      final explicitDeckId = storage.decks
          .addDeck(
            Deck(
              name: 'Explicit Deck Picker deck',
              kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
            ),
          )
          .id;
      await preferences.setString(
        'anki.browser.lastDeckId',
        browserDeckId.toString(),
      );
      final currentDeckPort = await CollectionDeckPickerRepository(runtime)
          .createNewNotePortForCurrentDeck();
      expect((await currentDeckPort.loadNewNote()).deckId, currentDeckId);

      final draft = await CollectionCardBrowserController(
        runtime,
        preferences: preferences,
        selectedNewNoteDeckId: () => explicitDeckId,
      ).loadNewNote();

      expect(draft.deckId, explicitDeckId);
      expect(storage.currentDeckId, currentDeckId);
    },
  );

  test(
    'new-note retry flushes committed writes without adding a duplicate',
    () async {
      final storage = runtime.storage!;
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      final selectedDeckId = Int64(9007199254740997);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: selectedDeckId,
          name: 'Flush retry destination',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      final draft = (await controller.loadNewNote()).copyWith(
        deckId: selectedDeckId,
        deckName: 'Flush retry destination',
      );
      const initialFields = ['flush retry unique front', 'back'];
      const editedFields = ['edited after flush failure', 'back'];
      const initialTags = ['FlushRetry'];
      const editedTags = ['FlushRetryEdited'];
      flushFails = true;
      final initialFlushCalls = flushCalls;

      await expectLater(
        controller.saveNewNote(
          draft: draft,
          fields: initialFields,
          tags: initialTags,
        ),
        throwsStateError,
      );

      final committedId = draft.note!.id;
      expect(committedId, isNot(Int64.ZERO));
      final cardsBeforeRetry = await storage.allCardIdsOfNoteInTemplateOrder(
        committedId,
      );
      expect(cardsBeforeRetry, isNotEmpty);
      final noteCountBeforeRetry = await storage.queryInt(
        'SELECT count(*) FROM notes',
      );
      expect(noteCountBeforeRetry, 1);

      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: selectedDeckId,
          name: 'Flush retry destination',
          kind: FilteredDeckKind(deck_proto.Deck_Filtered()),
        ),
      );
      flushFails = false;
      final retryFlushCalls = flushCalls;
      final count = await controller.saveNewNote(
        draft: draft,
        fields: editedFields,
        tags: editedTags,
      );

      expect(count, cardsBeforeRetry.length);
      expect(flushCalls, greaterThan(retryFlushCalls));
      expect(flushCalls, greaterThan(initialFlushCalls));
      expect(await storage.queryInt('SELECT count(*) FROM notes'), 1);
      expect(
        await storage.allCardIdsOfNoteInTemplateOrder(committedId),
        cardsBeforeRetry,
      );
      final saved = await storage.getNote(committedId);
      expect(saved!.fields, editedFields);
      expect(saved.tags, editedTags);
    },
  );

  test(
    'new-note controller validates and adds atomically through Unit38',
    () async {
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      final draft = await controller.loadNewNote();
      final empty = await controller.validateNewNote(
        draft.notetypeId,
        draft.content.values,
      );
      expect(empty, isA<NoteFieldsCheckFailure>());
      expect(
        (empty as NoteFieldsCheckFailure).localizedMessage,
        'The first field is empty.',
      );

      final fields = ['new unique front', 'back'];
      expect(
        await controller.validateNewNote(draft.notetypeId, fields),
        isA<NoteFieldsCheckSuccess>(),
      );
      final count = await controller.saveNewNote(
        draft: draft,
        fields: fields,
        tags: ['Unit39'],
      );
      expect(count, greaterThan(0));
      expect(draft.note!.id, isNot(Int64.ZERO));
      final saved = await runtime.storage!.getNote(draft.note!.id);
      expect(saved!.fields, fields);
      expect(saved.tags, ['Unit39']);
      expect(
        await controller.validateNewNote(draft.notetypeId, fields),
        isA<NoteFieldsCheckSuccess>(),
        reason:
            'duplicate field input remains nonfatal at save validation time',
      );
    },
  );

  test(
    'new-note deck catalog excludes filtered decks and saves exact choice',
    () async {
      final storage = runtime.storage!;
      final originalCurrentDeck = storage.currentDeckId;
      final wideDeckId = Int64(9007199254740995);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: wideDeckId,
          name: 'Course::Wide deck',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      final filteredDeck = storage.decks.addDeck(
        Deck(
          name: 'Filtered destination',
          kind: FilteredDeckKind(deck_proto.Deck_Filtered()),
        ),
      );
      final controller = CollectionCardBrowserController(runtime);

      final choices = await controller.loadSelectableDecks();
      expect(choices.map((deck) => deck.id), contains(wideDeckId));
      expect(choices.map((deck) => deck.name), contains('Course::Wide deck'));
      expect(choices.map((deck) => deck.id), isNot(contains(filteredDeck.id)));

      final initial = await controller.loadNewNote();
      final selected = initial.copyWith(
        deckId: wideDeckId,
        deckName: 'Course::Wide deck',
      );
      expect(storage.currentDeckId, originalCurrentDeck);
      await controller.saveNewNote(
        draft: selected,
        fields: ['deck choice regression test', 'back'],
        tags: ['DeckChoice'],
      );
      final cards = await storage.allCardIdsOfNoteInTemplateOrder(
        selected.note!.id,
      );
      expect(cards, isNotEmpty);
      expect((await storage.getCard(cards.first))!.deckId, wideDeckId);
      expect(storage.currentDeckId, originalCurrentDeck);
    },
  );

  test('new-note type switching sorts names, refreshes fields, preserves tags and applies deck defaults', () async {
    final storage = runtime.storage!;
    var types = await storage.getNotetypesByIds(
      await storage.getAllNotetypeIds(),
    );
    final originalClozeId = types
        .singleWhere((type) => type.name == 'Cloze')
        .id
        .value;
    final wideClozeId = Int64.parseInt('9007199254740993');
    await storage.executeBatch('''
UPDATE notetypes SET id = $wideClozeId WHERE id = $originalClozeId;
UPDATE fields SET ntid = $wideClozeId WHERE ntid = $originalClozeId;
UPDATE templates SET ntid = $wideClozeId WHERE ntid = $originalClozeId;
''');
    types = await storage.getNotetypesByIds(await storage.getAllNotetypeIds());
    final basic = types.singleWhere((type) => type.name == 'Basic');
    final cloze = types.singleWhere((type) => type.name == 'Cloze');
    expect(cloze.id.value, wideClozeId);
    await storage.executeBatch('''
DELETE FROM fields WHERE ntid = ${cloze.id.value} AND ord = 1;
UPDATE fields SET name = 'Text' WHERE ntid = ${cloze.id.value} AND ord = 0;
''');

    final rememberedDeck = storage.decks.addDeck(
      Deck(
        name: 'Remembered cloze deck',
        kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
      ),
    );
    final selectedDeck = storage.decks.addDeck(
      Deck(
        name: 'Explicit editor deck',
        kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
      ),
    );
    await storage.writeCollectionConfig('addToCur', false);
    await storage.writeCollectionConfigInt64(
      '_nt_${cloze.id.value}_lastDeck',
      rememberedDeck.id,
    );
    await storage.writeCollectionConfigInt64('curModel', basic.id.value);
    final originalCurrentDeck = storage.currentDeckId;
    final currentDeckBefore = storage.decks.getDeck(originalCurrentDeck)!;
    final currentDeckCommon =
        deck_proto.Deck_Common.fromBuffer(
            currentDeckBefore.common.writeToBuffer(),
          )
          ..other = utf8.encode(
            '{"large":9007199254740995,"nested":{"large":9007199254740997}}',
          );
    storage.decks.updateDeck(
      Deck(
        id: currentDeckBefore.id,
        name: currentDeckBefore.name,
        mtimeSecs: currentDeckBefore.mtimeSecs,
        usn: currentDeckBefore.usn,
        common: currentDeckCommon,
        kind: currentDeckBefore.kind,
      ),
    );
    final controller = CollectionCardBrowserController(
      runtime,
      selectedNewNoteDeckId: () => selectedDeck.id,
    );
    final initial = await controller.loadNewNote();

    final expectedNames = types.map((type) => type.name).toList()
      ..sort(
        (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
      );
    expect(initial.noteTypes.map((type) => type.name), expectedNames);
    expect(initial.notetypeId, basic.id.value);
    expect(initial.deckId, selectedDeck.id);

    final switched = await controller.changeNewNoteType(
      draft: initial,
      notetypeId: cloze.id.value,
      fields: ['{{c1::front}}', 'back'],
      tags: ['Study::Tagged'],
    );
    expect(switched.notetypeId, cloze.id.value);
    expect(switched.content.labels, ['Text']);
    expect(switched.content.values, ['{{c1::front}}; back']);
    expect(switched.content.tags, ['Study::Tagged']);
    expect(switched.deckId, rememberedDeck.id);
    expect(storage.currentDeckId, originalCurrentDeck);
    expect(storage.readCollectionConfigInt64('curModel'), cloze.id.value);
    final currentDeck = storage.decks.getDeck(originalCurrentDeck)!;
    final currentDeckOther = utf8.decode(currentDeck.common.other);
    expect(currentDeckOther, contains('"mid":${cloze.id.value}'));
    expect(currentDeckOther, contains('"large":9007199254740995'));
    expect(currentDeckOther, contains('"large":9007199254740997'));
    expect(jsonDecode(currentDeckOther)['mid'], cloze.id.value.toInt());
    expect((await controller.loadNewNote()).notetypeId, wideClozeId);
    expect(
      await controller.validateNewNote(
        switched.notetypeId,
        switched.content.values,
      ),
      isA<NoteFieldsCheckSuccess>(),
    );
    expect(
      await controller.validateNewNote(switched.notetypeId, ['']),
      isA<NoteFieldsCheckFailure>(),
    );
    await storage.addNoteToDeck(
      Note(notetypeId: switched.notetypeId, fields: switched.content.values),
      rememberedDeck.id,
    );
    expect(
      await controller.validateNewNote(
        switched.notetypeId,
        switched.content.values,
      ),
      isA<NoteFieldsCheckSuccess>(),
      reason: 'duplicates remain nonfatal after changing note type',
    );
    final cardsCreated = await controller.saveNewNote(
      draft: switched,
      fields: switched.content.values,
      tags: switched.content.tags,
    );
    expect(cardsCreated, greaterThan(0));
    final saved = await storage.getNote(switched.note!.id);
    expect(saved!.notetypeId, cloze.id.value);
    expect(saved.fields, ['{{c1::front}}; back']);
    expect(saved.tags, ['Study::Tagged']);

    await storage.writeCollectionConfigInt64(
      '_nt_${cloze.id.value}_lastDeck',
      Int64(987654321),
    );
    final fallback = await controller.changeNewNoteType(
      draft: initial.copyWith(
        deckId: selectedDeck.id,
        deckName: selectedDeck.name,
      ),
      notetypeId: cloze.id.value,
      fields: ['kept field', 'kept extra'],
      tags: const [],
    );
    expect(fallback.deckId, selectedDeck.id);

    final filteredDeck = storage.decks.addDeck(
      Deck(
        name: 'Filtered remembered destination',
        kind: FilteredDeckKind(deck_proto.Deck_Filtered()),
      ),
    );
    await storage.writeCollectionConfigInt64(
      '_nt_${cloze.id.value}_lastDeck',
      filteredDeck.id,
    );
    final filteredFallback = await controller.changeNewNoteType(
      draft: initial.copyWith(
        deckId: selectedDeck.id,
        deckName: selectedDeck.name,
      ),
      notetypeId: cloze.id.value,
      fields: ['kept field', 'kept extra'],
      tags: const [],
    );
    expect(filteredFallback.deckId, selectedDeck.id);
  });

  test(
    'new-note save rejects a destination deck that became filtered',
    () async {
      final storage = runtime.storage!;
      final selectedId = Int64(9007199254740997);
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: selectedId,
          name: 'Deck that changes kind',
          kind: NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      final controller = CollectionCardBrowserController(runtime);
      final loaded = await controller.loadNewNote();
      final selected = loaded.copyWith(
        deckId: selectedId,
        deckName: 'Deck that changes kind',
      );
      storage.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: selectedId,
          name: 'Deck that changes kind',
          kind: FilteredDeckKind(deck_proto.Deck_Filtered()),
        ),
      );

      await expectLater(
        controller.saveNewNote(
          draft: selected,
          fields: ['stale deck test', 'back'],
          tags: const [],
        ),
        throwsStateError,
      );
      expect(await storage.queryInt('SELECT count(*) FROM notes'), 0);
    },
  );

  test(
    'external collection mutation invalidates browser undo status',
    () async {
      final storage = runtime.storage!;
      final notetype = (await storage.getNotetypesByIds(
        await storage.getAllNotetypeIds(),
      )).firstWhere((type) => type.name == 'Basic');
      final note = Note(
        id: Int64(43),
        guid: 'invalidated-editor-edit',
        notetypeId: notetype.id.value,
        fields: ['original', 'back'],
      )..prepareForUpdate(notetype, normalizeText: false);
      await storage.addOrUpdateNote(note);
      await storage.addCardIfUnique(
        Card(id: Int64(143), noteId: note.id, deckId: Int64.ONE),
      );
      final controller = CollectionCardBrowserController(runtime);
      await controller.saveFields(note.id, ['edited', 'back']);
      expect(controller.canUndoNoteUpdate, isTrue);

      await storage.executeBatch(
        "UPDATE notes SET sfld = 'external edit' WHERE id = 43",
      );

      expect(controller.canUndoNoteUpdate, isFalse);
    },
  );

  test(
    'new-note controller maps Cloze validation states in source order',
    () async {
      final storage = runtime.storage!;
      final types = await storage.getNotetypesByIds(
        await storage.getAllNotetypeIds(),
      );
      final basic = types.singleWhere((type) => type.name == 'Basic');
      final cloze = types.singleWhere((type) => type.name == 'Cloze');
      final controller = CollectionCardBrowserController(runtime);

      final outsideCloze = await controller.validateNewNote(basic.id.value, [
        '{{c1::text}}',
        '',
      ]);
      expect(
        (outsideCloze as NoteFieldsCheckFailure).localizedMessage,
        'Cloze deletions require a Cloze note type.',
      );
      final missingCloze = await controller.validateNewNote(cloze.id.value, [
        'text',
        '',
      ]);
      expect(
        (missingCloze as NoteFieldsCheckFailure).localizedMessage,
        'A cloze deletion is required.',
      );
      final wrongClozeField = await controller.validateNewNote(cloze.id.value, [
        '',
        '{{c1::text}}',
      ]);
      expect(
        (wrongClozeField as NoteFieldsCheckFailure).localizedMessage,
        'Cloze deletions must be in a Cloze field.',
      );
    },
  );
}
