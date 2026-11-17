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
    'saved searches persist in active collection config and reload',
    () async {
      final first = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );

      expect(await first.loadSavedSearches(), isEmpty);
      final (added, saved) = await first.addSavedSearch(
        const BrowserSavedSearch(name: 'A', query: '  tag:one \t'),
      );
      expect(added, isTrue);
      expect(saved, [const BrowserSavedSearch(name: 'A', query: 'tag:one')]);
      expect(runtime.storage!.readCollectionConfig('savedFilters'), {
        'A': 'tag:one',
      });

      final reopened = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      expect(await reopened.loadSavedSearches(), [
        const BrowserSavedSearch(name: 'A', query: 'tag:one'),
      ]);
    },
  );

  test(
    'saved search names are case-sensitive and duplicate add is a no-op',
    () async {
      await runtime.storage!.writeCollectionConfig('savedFilters', {
        'a': 'lower',
        'Z': 'last',
        'A': 'upper',
      });
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );

      expect(
        (await controller.loadSavedSearches()).map((search) => search.name),
        ['A', 'Z', 'a'],
      );
      final (changed, values) = await controller.addSavedSearch(
        const BrowserSavedSearch(name: 'A', query: 'replacement'),
      );
      expect(changed, isFalse);
      expect(values.first.query, 'upper');
      expect(runtime.storage!.readCollectionConfig('savedFilters'), {
        'a': 'lower',
        'Z': 'last',
        'A': 'upper',
      });
      final (lowerAdded, _) = await controller.addSavedSearch(
        const BrowserSavedSearch(name: 'aA', query: 'q'),
      );
      expect(lowerAdded, isTrue);
    },
  );

  test('malformed saved-search config loads empty and missing delete does not write', () async {
    await runtime.storage!.writeCollectionConfig('savedFilters', ['bad']);
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );

    expect(await controller.loadSavedSearches(), isEmpty);
    final (deleted, values) = await controller.deleteSavedSearch('missing');
    expect(deleted, isFalse);
    expect(values, isEmpty);
    expect(runtime.storage!.readCollectionConfig('savedFilters'), ['bad']);
  });

  test('saved search deletion removes only an exact matching name', () async {
    await runtime.storage!.writeCollectionConfig('savedFilters', {
      'A': 'upper',
      'a': 'lower',
    });
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );

    final (deleted, values) = await controller.deleteSavedSearch('A');
    expect(deleted, isTrue);
    expect(values, [const BrowserSavedSearch(name: 'a', query: 'lower')]);
    expect(runtime.storage!.readCollectionConfig('savedFilters'), {
      'a': 'lower',
    });
  });

  test('saved search config write failures propagate unchanged', () async {
    await runtime.close();
    final triggerDatabase = sqlite.sqlite3.open(
      '${directory.path}/collection.anki2',
    );
    triggerDatabase.execute('''
      CREATE TRIGGER reject_saved_filters
      BEFORE INSERT ON config
      WHEN NEW.key = 'savedFilters'
      BEGIN SELECT RAISE(ABORT, 'saved filters rejected'); END
    ''');
    triggerDatabase.close();
    await runtime.openOrCreate(
      ProfileId.defaultId,
      callbacks: (storage) =>
          appCollectionOpenCallbacks(storage, AppLocalizationsEn()),
    );
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );

    await expectLater(
      controller.addSavedSearch(
        const BrowserSavedSearch(name: 'A', query: 'tag:one'),
      ),
      throwsA(isA<sqlite.SqliteException>()),
    );
    expect(runtime.storage!.readCollectionConfig('savedFilters'), isNull);
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
