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
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:flutter_test/flutter_test.dart';
import 'package:fixnum/fixnum.dart';
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

  test(
    'mode defaults to cards and loads the active collection setting',
    () async {
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      final defaults = await controller.load();

      expect(defaults.mode, BrowserColumnMode.cards);
      expect(defaults.columns.map((column) => column.type), [
        BrowserColumn.sortField,
        BrowserColumn.cardType,
        BrowserColumn.due,
        BrowserColumn.deck,
      ]);

      await runtime.storage!.writeCollectionConfig(
        'browserTableShowNotesMode',
        true,
      );
      final notes = await CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      ).load();
      expect(notes.mode, BrowserColumnMode.notes);
      expect(notes.columns.map((column) => column.type), [
        BrowserColumn.sortField,
        BrowserColumn.noteType,
        BrowserColumn.cardType,
        BrowserColumn.tags,
      ]);
    },
  );

  test(
    'switching mode persists first and a same-value switch is a no-op',
    () async {
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      await controller.load();
      await runtime.storage!.executeBatch('''
      CREATE TRIGGER reject_same_browser_mode
      BEFORE INSERT ON config
      WHEN NEW.key = 'browserTableShowNotesMode'
      BEGIN SELECT RAISE(ABORT, 'unexpected mode write'); END;
    ''');

      expect(
        (await controller.updateMode(BrowserColumnMode.cards)).mode,
        BrowserColumnMode.cards,
      );
      await expectLater(
        controller.updateMode(BrowserColumnMode.notes),
        throwsA(isA<Object>()),
      );
      expect(
        runtime.storage!.readCollectionConfig('browserTableShowNotesMode'),
        isNull,
      );
      expect((await controller.search('')).mode, BrowserColumnMode.cards);
    },
  );

  test('mode-specific columns and sort keys reload independently', () async {
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    await controller.load();
    await controller.saveColumns([BrowserColumn.tags, BrowserColumn.deck]);
    await controller.updateSort(
      const BrowserSortCollectionOrdering(key: 'deck', reverse: true),
    );
    await controller.updateMode(BrowserColumnMode.notes);
    await controller.saveColumns([
      BrowserColumn.noteType,
      BrowserColumn.sortField,
    ]);
    await controller.updateSort(
      const BrowserSortCollectionOrdering(key: 'noteTags', reverse: true),
    );

    expect(runtime.storage!.readCollectionConfig('sortType'), 'deck');
    expect(runtime.storage!.readCollectionConfig('sortBackwards'), isTrue);
    expect(runtime.storage!.readCollectionConfig('noteSortType'), 'noteTags');
    expect(
      runtime.storage!.readCollectionConfig('browserNoteSortBackwards'),
      isTrue,
    );

    final reopened = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    final notes = await reopened.load();
    expect(notes.mode, BrowserColumnMode.notes);
    expect(notes.columns.map((column) => column.type), [
      BrowserColumn.noteType,
      BrowserColumn.sortField,
    ]);
    expect(
      notes.sortType,
      const BrowserSortCollectionOrdering(key: 'noteTags', reverse: true),
    );

    final cards = await reopened.updateMode(BrowserColumnMode.cards);
    expect(cards.columns.map((column) => column.type), [
      BrowserColumn.tags,
      BrowserColumn.deck,
    ]);
    expect(
      cards.sortType,
      const BrowserSortCollectionOrdering(key: 'deck', reverse: true),
    );
  });

  test(
    'notes search preserves sorted Note IDs, deck scoping and wide IDs',
    () async {
      final noteIds = [
        BigInt.parse('9007199254740995'),
        BigInt.parse('9007199254740994'),
      ];
      await runtime.storage!.executeBatch('''
      INSERT INTO notetypes (id, name, mtime_secs, usn, config)
      VALUES (1, 'Fixture Basic', 0, 0, X'1001');
      INSERT INTO fields (ntid, ord, name, config) VALUES
        (1, 0, 'Front', X''), (1, 1, 'Back', X'');
      INSERT INTO templates (ntid, ord, name, mtime_secs, usn, config) VALUES
        (1, 0, 'Card 1', 0, 0, X''), (1, 1, 'Card 2', 0, 0, X'');
    ''');
      for (var i = 0; i < noteIds.length; i++) {
        final id = noteIds[i];
        await runtime.storage!.executeBatch('''
        INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, flags, data)
        VALUES ($id, 'guid$i', 1, 0, -1, ' shared ', 'field$i', '${i == 0 ? 'zeta' : 'alpha'}', 0, 0, '');
        INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses, left, odue, odid, flags, data)
        VALUES (${100 + i}, $id, 1, ${i == 0 ? 1 : 0}, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');
      ''');
      }
      await runtime.storage!.executeBatch('''
      UPDATE notes SET flds = 'front' || char(31) || '<b>back</b> &amp; <img src="sort.png">'
        WHERE id = ${noteIds[0]};
      UPDATE notes SET flds = 'front' || char(31) || 'second'
        WHERE id = ${noteIds[1]};
    ''');
      await runtime.storage!.executeBatch('''
      INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses, left, odue, odid, flags, data)
      VALUES (200, ${noteIds[0]}, 2, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');
      UPDATE notes SET tags = ' marked shared ' WHERE id = ${noteIds[0]};
    ''');
      await runtime.storage!.executeBatch('''
      INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, flags, data)
      VALUES (700, 'other-deck', 1, 0, -1, ' shared ', 'outside', 'outside', 0, 0, '');
      INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses, left, odue, odid, flags, data)
      VALUES (700, 700, 2, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');
    ''');
      await runtime.storage!.writeCollectionConfig(
        'browserTableShowNotesMode',
        true,
      );
      final controller = CollectionCardBrowserController(
        runtime,
        preferences: preferences,
      );
      await controller.load();
      await controller.saveColumns([
        BrowserColumn.sortField,
        BrowserColumn.noteType,
        BrowserColumn.cardType,
        BrowserColumn.deck,
        BrowserColumn.tags,
      ]);
      final result = await controller.search('tag:shared');

      expect(result.mode, BrowserColumnMode.notes);
      expect(result.rows.map((row) => row.id.bigValue), [
        noteIds[1],
        noteIds[0],
      ]);
      expect(result.rows.first.cells['noteFld'], 'second');
      expect(result.rows.first.cells['template'], '1');
      expect(result.rows.first.cells['note'], 'Fixture Basic');
      expect(result.rows.last.cells['noteFld'], 'back &  sort.png');
      expect(result.rows.first.cells['deck'], isNotEmpty);
      expect(result.rows.first.cells['noteTags'], 'shared');
      expect(result.rows.last.cells['noteTags'], 'marked shared');
      expect(result.rows.last.cells['note'], 'Fixture Basic');
      expect(result.rows.last.cells['template'], '2');
      expect(result.rows.last.cells['deck'], '(2)');
      expect(result.rows.last.color, CardBrowserRowColor.marked);
      expect(result.rows.last.fontName, '');
      expect(result.rows.last.fontSize, 0);
      expect(result.rows.last.rtlCells['noteFld'], isFalse);
      expect(result.rows.last.elideModes['deck'], CardBrowserElideMode.middle);
      expect(
        result.rows.last.elideModes['noteFld'],
        CardBrowserElideMode.right,
      );
      expect(
        result.rows.every((row) => row.id.bigValue != BigInt.from(700)),
        isTrue,
      );
      await runtime.storage!.executeBatch('''
      UPDATE cards SET flags = 2 WHERE id = 101;
      UPDATE cards SET queue = -1 WHERE id = 100;
      UPDATE notes SET tags = ' shared ' WHERE id = ${noteIds[0]};
    ''');
      final cards = await controller.updateMode(BrowserColumnMode.cards);
      expect(cards.rows.map((row) => row.id.bigValue), [
        BigInt.from(101),
        BigInt.from(100),
      ]);
      expect(cards.rows.first.color, CardBrowserRowColor.flagOrange);
      expect(cards.rows.last.color, CardBrowserRowColor.suspended);
      expect(cards.rows.first.elideModes['deck'], CardBrowserElideMode.middle);
      await controller.saveColumns([
        BrowserColumn.noteType,
        BrowserColumn.cardType,
      ]);
      final standardCards = await controller.search('tag:shared');
      expect(standardCards.rows.map((row) => row.cells['template']).toSet(), {
        'Card 1',
        'Card 2',
      });
      expect(standardCards.rows.first.cells['note'], 'Fixture Basic');
      expect(standardCards.columns.map((column) => column.label), [
        'Note type',
        'Card type',
      ]);
      await runtime.storage!.executeBatch('''
      INSERT INTO notetypes (id, name, mtime_secs, usn, config)
      VALUES (2, 'Fixture Cloze', 0, 0, X'0801');
      INSERT INTO fields (ntid, ord, name, config) VALUES (2, 0, 'Text', X'');
      INSERT INTO templates (ntid, ord, name, mtime_secs, usn, config) VALUES
        (2, 0, 'Cloze', 0, 0, X'');
      INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, flags, data)
      VALUES (901, 'cloze', 2, 0, 0, '', 'cloze text', 'cloze text', 0, 0, '');
      INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses, left, odue, odid, flags, data)
      VALUES (901, 901, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');
    ''');
      await controller.saveColumns([
        BrowserColumn.noteType,
        BrowserColumn.cardType,
      ]);
      final withCloze = await controller.search('');
      final clozeRow = withCloze.rows.singleWhere(
        (row) => row.id.bigValue == BigInt.from(901),
      );
      expect(clozeRow.cells['note'], 'Fixture Cloze');
      expect(clozeRow.cells['template'], 'Cloze 2');
      expect(withCloze.columns.map((column) => column.label), [
        'Note type',
        'Card type',
      ]);

      await runtime.storage!.executeBatch('''
      INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, flags, data)
      VALUES (902, 'missing-notetype', 404, 0, 0, '', 'field', 'field', 0, 0, '');
      INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses, left, odue, odid, flags, data)
      VALUES (902, 902, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');
    ''');
      await expectLater(controller.search(''), throwsA(isA<StateError>()));
      await runtime.storage!.executeBatch('''
      DELETE FROM cards WHERE id = 902;
      DELETE FROM notes WHERE id = 902;
      UPDATE notetypes SET config = X'08011001' WHERE id = 2;
    ''');
      await controller.saveColumns([BrowserColumn.sortField]);
      await expectLater(controller.search(''), throwsA(isA<RangeError>()));
    },
  );

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

  test('question and answer columns render selected cards and mark invalid templates unavailable', () async {
    final normalConfig = proto.Notetype_Config(
      kind: proto.Notetype_Config_Kind.KIND_NORMAL,
    );
    final templates = [
      proto.Notetype_Template_Config(
        qFormat: '{{#c1}}one {{Front}}{{/c1}}',
        aFormat: '{{FrontSide}}<hr id=answer>{{Back}}',
        qFormatBrowser: '{{#c1}}one {{Front}}{{/c1}}',
        aFormatBrowser: '{{FrontSide}}<hr id=answer>{{Back}}',
      ),
      proto.Notetype_Template_Config(
        qFormat: '{{#c2}}two {{Front}}{{/c2}}',
        aFormat: '{{FrontSide}}<hr id=answer>{{Back}}',
        qFormatBrowser: '{{#c2}}two {{Front}}{{/c2}}',
        aFormatBrowser: '{{FrontSide}}<hr id=answer>{{Back}}',
      ),
    ];
    final invalidTemplate = proto.Notetype_Template_Config(
      qFormatBrowser: '{{Missing}}',
      aFormatBrowser: '{{FrontSide}}',
    );
    await runtime.storage!.executeBatch('''
      INSERT INTO notetypes (id, name, mtime_secs, usn, config)
      VALUES (900, 'Renderer fixture', 0, 0, ${_sqlBlob(normalConfig.writeToBuffer())});
      INSERT INTO fields (ntid, ord, name, config) VALUES
        (900, 0, 'Front', X''), (900, 1, 'Back', X'');
      INSERT INTO templates (ntid, ord, name, mtime_secs, usn, config) VALUES
        (900, 0, 'Card 1', 0, 0, ${_sqlBlob(templates[0].writeToBuffer())}),
        (900, 1, 'Card 2', 0, 0, ${_sqlBlob(templates[1].writeToBuffer())});
      INSERT INTO notetypes (id, name, mtime_secs, usn, config)
      VALUES (901, 'Invalid renderer fixture', 0, 0, ${_sqlBlob(normalConfig.writeToBuffer())});
      INSERT INTO fields (ntid, ord, name, config) VALUES
        (901, 0, 'Front', X''), (901, 1, 'Back', X'');
      INSERT INTO templates (ntid, ord, name, mtime_secs, usn, config)
      VALUES (901, 0, 'Card 1', 0, 0, ${_sqlBlob(invalidTemplate.writeToBuffer())});
      INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, flags, data)
      VALUES (920, 'renderer-guid', 900, 0, -1, ' unit22 ', 'front' || char(31) || 'back', 'front', 0, 0, '');
      INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses, left, odue, odid, flags, data)
      VALUES (930, 920, 1, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');
      INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses, left, odue, odid, flags, data)
      VALUES (931, 920, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');
      INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, flags, data)
      VALUES (921, 'invalid-renderer-guid', 901, 0, -1, ' broken ', 'front' || char(31) || 'back', 'front', 0, 0, '');
      INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses, left, odue, odid, flags, data)
      VALUES (940, 921, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');
    ''');

    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    await controller.load();
    await controller.saveColumns([
      BrowserColumn.question,
      BrowserColumn.answer,
    ]);
    final cardRows = await controller.search('nid:920');
    expect(cardRows.columns.map((column) => column.label), [
      'Question',
      'Answer',
    ]);
    expect(cardRows.rows.map((row) => row.cells['question']), [
      'one front',
      'two front',
    ]);
    expect(cardRows.rows.map((row) => row.cells['answer']), ['back', 'back']);

    await controller.updateMode(BrowserColumnMode.notes);
    await controller.saveColumns([
      BrowserColumn.question,
      BrowserColumn.answer,
    ]);
    final noteRow = (await controller.search('tag:unit22')).rows.single;
    expect(noteRow.cells['question'], 'two front');
    expect(noteRow.cells['answer'], 'back');
    final invalidRow = (await controller.search('tag:broken')).rows.single;
    expect(invalidRow.cells['question'], 'Unavailable');
    expect(invalidRow.cells['answer'], 'Unavailable');
  });

  test('notes search preserves Core database-check error for notes without cards', () async {
    // Core RowContext::new() rejects Notes-mode rows whose all_cards_of_note()
    // result is empty with DatabaseCheckRequired. Notes-only SQL searches can
    // select a persisted note without joining the cards table.
    await runtime.storage!.executeBatch('''
      INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, flags, data)
      VALUES (950, 'orphan-note-guid', (SELECT id FROM notetypes LIMIT 1), 0, -1, ' orphan ', 'front', 'front', 0, 0, '');
    ''');
    final controller = CollectionCardBrowserController(
      runtime,
      preferences: preferences,
    );
    await runtime.storage!.selectDeck(Int64.ZERO);
    await controller.updateMode(BrowserColumnMode.notes);
    await controller.saveColumns([BrowserColumn.sortField, BrowserColumn.tags]);

    final row = (await controller.search('tag:orphan')).rows.single;

    expect(row.id.bigValue, BigInt.from(950));
    expect(row.error, BrowserRowError.databaseCheckRequired);
    expect(row.color, CardBrowserRowColor.unknown);
    expect(
      row.cells.values,
      everyElement('Please use the Check Database action, then try again.'),
    );
  });
}

String _sqlBlob(List<int> bytes) =>
    "X'${bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join()}'";
