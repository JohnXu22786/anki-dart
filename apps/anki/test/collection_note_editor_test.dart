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
    'new-note retry flushes committed writes without adding a duplicate',
    () async {
      final storage = runtime.storage!;
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      final draft = await controller.loadNewNote();
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
