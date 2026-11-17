/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:io' as io;

import 'package:anki_app/app.dart';
import 'package:anki_app/app_collection_callbacks.dart';
import 'package:anki_app/collection_card_browser_controller.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_dart/anki_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:anki_app/l10n/app_localizations_en.dart';

void main() {
  late io.Directory directory;
  late CollectionRuntime runtime;
  late SharedPreferencesAsync preferences;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
    directory = await io.Directory.systemTemp.createTemp('anki-browser-prefs-');
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

  test('active column order persists when a new controller loads', () async {
    final first = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    await first.saveColumns([BrowserColumn.tags, BrowserColumn.deck]);
    expect((await first.load()).columns.map((column) => column.type), [
      BrowserColumn.tags,
      BrowserColumn.deck,
    ]);

    final reopened = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    expect((await reopened.load()).columns.map((column) => column.type), [
      BrowserColumn.tags,
      BrowserColumn.deck,
    ]);
  });

  test('empty stored sort key resolves to no ordering', () async {
    await runtime.storage!.writeCollectionConfig('sortType', '');
    await preferences.setBool('anki.browser.noSorting', false);
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    expect((await controller.load()).sortType, isA<BrowserSortNoOrdering>());
  });

  test(
    'sort config reloads and is saved before unsupported search fails',
    () async {
      final first = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      await first.updateSort(
        const BrowserSortCollectionOrdering(key: 'deck', reverse: true),
      );
      final reopened = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      expect(
        (await reopened.load()).sortType,
        const BrowserSortCollectionOrdering(key: 'deck', reverse: true),
      );

      await expectLater(
        reopened.updateSort(
          const BrowserSortCollectionOrdering(key: 'garbage', reverse: true),
        ),
        throwsUnsupportedError,
      );
      expect(runtime.storage!.readCollectionConfig('sortType'), 'garbage');
      expect(runtime.storage!.readCollectionConfig('sortBackwards'), isTrue);
      expect(await preferences.getBool('anki.browser.noSorting'), isFalse);
    },
  );
}
