/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:io' as io;

import 'package:anki_app/app_collection_callbacks.dart';
import 'package:anki_app/collection_card_browser_controller.dart';
import 'package:anki_app/collection_runtime.dart';
import 'package:anki_app/l10n/app_localizations_en.dart';
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
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

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
    directory = await io.Directory.systemTemp.createTemp('anki-note-editor-');
    runtime = CollectionRuntime(
      locationForProfile: (_) async => '${directory.path}/collection.anki2',
      createDriver: () async =>
          CollectionSqliteDriver(openDatabase: sqlite.sqlite3.open),
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
}
