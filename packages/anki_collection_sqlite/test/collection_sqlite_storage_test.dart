// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as config_proto;
import 'package:anki_backend_protocol/anki/decks.pb.dart' as proto;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as notetype_proto;
import 'package:anki_collection_schema/anki_collection_schema.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/common.dart';
import 'package:pure_zstd/pure_zstd.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late String path;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('anki-collection-');
    path = '${directory.path}/collection.anki2';
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'exports a readable current and schema-11 APKG without changing live DB',
    () async {
      final database = await _openLatestCollection(path);
      final before = await database.queryInt('select ver from col');
      final sourceConf =
          jsonDecode(await database.queryString('SELECT conf FROM col'))
              as Map<String, dynamic>;
      final sourceCreationOffset = sourceConf['creationOffset'];
      final profileConf = {
        ...sourceConf,
        'activeDecks': [88],
        'curDeck': 99,
        'profileOnly': true,
      };
      await database.executeBatch(
        "UPDATE col SET conf = '${jsonEncode(profileConf).replaceAll("'", "''")}'",
      );

      final bytes = await database.exportApkg(
        options: const ApkgExportOptions(withMedia: false),
      );
      final archive = ZipDecoder().decodeBytes(bytes);
      final current = zstdDecode(
        Uint8List.fromList(
          archive.findFile('collection.anki21b')!.content as List<int>,
        ),
      );
      final compatibility = archive.findFile('collection.anki2')!;
      final currentPath = '${directory.path}/export-current.anki2';
      final compatibilityPath = '${directory.path}/export-legacy.anki2';
      await File(currentPath).writeAsBytes(current);
      await File(
        compatibilityPath,
      ).writeAsBytes(compatibility.content as List<int>);
      final currentDb = sqlite3.open(currentPath);
      final compatibilityDb = sqlite3.open(compatibilityPath);
      expect(currentDb.select('select ver from col').single['ver'], 18);
      expect(compatibilityDb.select('select ver from col').single['ver'], 11);
      final exportedConf =
          jsonDecode(
                currentDb.select('SELECT conf FROM col').single['conf']
                    as String,
              )
              as Map<String, dynamic>;
      expect(exportedConf['activeDecks'], [1]);
      expect(exportedConf['curDeck'], 1);
      expect(exportedConf['profileOnly'], isNull);
      expect(exportedConf['creationOffset'], sourceCreationOffset);
      expect(
        compatibilityDb.select('SELECT conf FROM col').single['conf'],
        isNot(contains('profileOnly')),
      );
      currentDb.close();
      compatibilityDb.close();
      expect(await database.queryInt('select ver from col'), before);
      expect(
        jsonDecode(await database.queryString('SELECT conf FROM col')),
        profileConf,
      );
      await database.close();
    },
  );

  test('deck selection includes descendants and excludes sibling notes', () async {
    final mediaStore = _MemoryMediaStorage({
      ' clip.mp3': [8],
      'a:b': [6],
      'latex-060219fbf3ddb74306abddaf4504276ad793b029.png': [9],
      'photo.png': [1, 2, 3],
      'private.pdf': [7],
      'z%20.png': [4, 5],
    });
    final initial = await _openLatestCollection(path);
    var notetypeRandom = BigInt.one;
    await initial.addInitialStockNoteTypes(
      names: _InitialText().stockNotetypeNames,
      randomU64: () {
        final value = notetypeRandom;
        notetypeRandom += BigInt.one;
        return value;
      },
      now: DateTime.now(),
    );
    final now = DateTime.now().millisecondsSinceEpoch - 60000;
    final noteId = now;
    final siblingNoteId = now + 1;
    final selectedCardId = now + 2;
    final siblingCardId = now + 3;
    final notetypeId = await initial.queryInt(
      "select id from notetypes where name = 'Basic'",
    );
    await initial.close();
    final seed = sqlite3.open(path);
    seed.createCollation(
      name: 'unicase',
      function: (left, right) =>
          (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase()),
    );
    final rootKind = proto.Deck_KindContainer(
      normal: proto.Deck_Normal(configId: Int64.ONE),
    ).writeToBuffer();
    for (final deck in [
      (2, 'Root'),
      (3, 'Root\x1fChild'),
      (4, 'Root\x1fSibling'),
    ]) {
      seed.execute(
        'insert into decks (id, name, mtime_secs, usn, common, kind) '
        'values (?, ?, 0, -1, ?, ?)',
        [deck.$1, deck.$2, proto.Deck_Common().writeToBuffer(), rootKind],
      );
    }
    seed.execute(
      'insert into notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, '
      'flags, data) values (?, ?, ?, 0, -1, ?, ?, 0, 0, 0, ?)',
      [
        noteId,
        'selected',
        notetypeId,
        'marked leech kept',
        '<img src="photo.png"><img src="z%20.png">'
            '<img src="a:b">'
            '<div data="private.pdf"></div>'
            '<img src="../unsafe.png">'
            '<img src="missing.png">'
            '[sound: clip.mp3][\$]<b>hello</b>&nbsp; world[/\$]\x1fback',
        '',
      ],
    );
    seed.execute(
      'insert into notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, '
      'flags, data) values (?, ?, ?, 0, -1, ?, ?, 0, 0, 0, ?)',
      [siblingNoteId, 'sibling', notetypeId, '', 'other\x1fback', ''],
    );
    seed.execute(
      'insert into cards (id, nid, did, ord, mod, usn, type, queue, due, '
      'ivl, factor, reps, lapses, `left`, odue, odid, flags, data) '
      'values (?, ?, 3, 0, 0, -1, 2, 2, 10, 5, 2500, 1, 0, 0, 0, 0, 4, ?)',
      [selectedCardId, noteId, '{}'],
    );
    seed.execute(
      'insert into cards (id, nid, did, ord, mod, usn, type, queue, due, '
      'ivl, factor, reps, lapses, `left`, odue, odid, flags, data) '
      'values (?, ?, 4, 0, 0, -1, 2, 2, 10, 5, 2500, 1, 0, 0, 0, 0, 4, ?)',
      [siblingCardId, siblingNoteId, '{}'],
    );
    seed.execute(
      'insert into revlog (id, cid, usn, ease, ivl, lastIvl, factor, time, type) '
      'values (?, ?, -1, 3, 10, 5, 2500, 1000, 1)',
      [now + 4, selectedCardId],
    );
    seed.execute(
      'insert into revlog (id, cid, usn, ease, ivl, lastIvl, factor, time, type) '
      'values (?, ?, -1, 3, 10, 5, 2500, 1000, 1)',
      [now + 5, siblingCardId],
    );
    for (final tag in ['marked', 'leech', 'kept', 'other', 'stale']) {
      seed.execute('INSERT INTO tags (tag, usn) VALUES (?, -1)', [tag]);
    }
    for (final key in ['curDeck', '_nt_9_lastDeck', 'profileOnly']) {
      seed.execute(
        'INSERT INTO config (key, usn, mtime_secs, val) VALUES (?, -1, 0, ?)',
        [key, utf8.encode('"private"')],
      );
    }

    seed.close();
    final database = await _openLatestCollection(
      path,
      driver: _driverWithMedia(mediaStore),
    );
    final apkg = await database.exportApkg(
      limit: ApkgExportLimit(deckId: Int64(3)),
    );
    final archive = ZipDecoder().decodeBytes(apkg);
    final currentBytes = zstdDecode(
      Uint8List.fromList(
        archive.findFile('collection.anki21b')!.content as List<int>,
      ),
    );
    final currentPath = '${directory.path}/selected-export.db';
    await File(currentPath).writeAsBytes(currentBytes);
    final exported = sqlite3.open(currentPath);
    exported.createCollation(
      name: 'unicase',
      function: (left, right) =>
          (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase()),
    );
    expect(exported.select('select id from notes').map((row) => row['id']), [
      noteId,
    ]);
    expect(exported.select('select id from cards').map((row) => row['id']), [
      selectedCardId,
    ]);
    expect(exported.select('select flags from cards').single['flags'], 0);
    expect(exported.select('select tags from notes').single['tags'], 'kept');
    expect(
      exported.select('SELECT DISTINCT ntid FROM fields').single['ntid'],
      notetypeId,
    );
    expect(exported.select('select count(*) from tags').single[0], 0);
    expect(exported.select('select count(*) from config').single[0], 0);
    expect(exported.select('select count(*) from revlog').single[0], 0);
    expect(exported.select('select count(*) from decks').single[0], 2);
    expect(archive.findFile('0'), isNotNull);
    expect(
      zstdDecode(
        Uint8List.fromList(archive.findFile('0')!.content as List<int>),
      ),
      [8],
    );
    expect(
      zstdDecode(
        Uint8List.fromList(archive.findFile('1')!.content as List<int>),
      ),
      [9],
    );
    expect(
      zstdDecode(
        Uint8List.fromList(archive.findFile('2')!.content as List<int>),
      ),
      [1, 2, 3],
    );
    expect(
      zstdDecode(
        Uint8List.fromList(archive.findFile('3')!.content as List<int>),
      ),
      [4, 5],
    );
    expect(archive.findFile('4'), isNull);
    exported.close();

    final legacyApkg = await database.exportApkg(
      limit: ApkgExportLimit(deckId: Int64(3)),
      options: const ApkgExportOptions(
        withScheduling: true,
        withDeckConfigs: true,
        legacy: true,
      ),
    );
    final legacyArchive = ZipDecoder().decodeBytes(legacyApkg);
    final legacyCurrentPath = '${directory.path}/legacy-current.db';
    final legacyCompatibilityPath = '${directory.path}/legacy-compat.db';
    await File(legacyCurrentPath).writeAsBytes(
      legacyArchive.findFile('collection.anki21')!.content as List<int>,
    );
    await File(legacyCompatibilityPath).writeAsBytes(
      legacyArchive.findFile('collection.anki2')!.content as List<int>,
    );
    final legacyCurrent = sqlite3.open(legacyCurrentPath);
    final legacyCompatibility = sqlite3.open(legacyCompatibilityPath);
    legacyCurrent.createCollation(
      name: 'unicase',
      function: (left, right) =>
          (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase()),
    );
    legacyCompatibility.createCollation(
      name: 'unicase',
      function: (left, right) =>
          (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase()),
    );
    expect(legacyCurrent.select('select ver from col').single['ver'], 18);
    expect(legacyCompatibility.select('select ver from col').single['ver'], 11);
    expect(legacyCurrent.select('select count(*) from revlog').single[0], 1);
    expect(legacyCurrent.select('select flags from cards').single['flags'], 4);
    expect(
      jsonDecode(
        utf8.decode(legacyArchive.findFile('media')!.content as List<int>),
      ),
      {
        '0': ' clip.mp3',
        '1': 'latex-060219fbf3ddb74306abddaf4504276ad793b029.png',
        '2': 'photo.png',
        '3': 'z%20.png',
      },
    );
    expect(legacyArchive.findFile('0')!.content, [8]);
    expect(legacyArchive.findFile('1')!.content, [9]);
    expect(legacyArchive.findFile('2')!.content, [1, 2, 3]);
    expect(legacyArchive.findFile('3')!.content, [4, 5]);
    legacyCurrent.close();
    legacyCompatibility.close();
    await database.close();
  });

  test(
    'large APKG selections exceed the common SQLite bind-variable limit',
    () async {
      final initial = await _openLatestCollection(path);
      var random = BigInt.one;
      await initial.addInitialStockNoteTypes(
        names: _InitialText().stockNotetypeNames,
        randomU64: () {
          final value = random;
          random += BigInt.one;
          return value;
        },
        now: DateTime.now(),
      );
      final notetypeId = await initial.queryInt(
        "SELECT id FROM notetypes WHERE name = 'Basic'",
      );
      await initial.close();

      final seed = sqlite3.open(path);
      const count = 1100;
      final baseId = DateTime.now().millisecondsSinceEpoch - 100000;
      final insertNote = seed.prepare(
        'INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, '
        'flags, data) VALUES (?, ?, ?, 0, -1, ?, ?, 0, 0, 0, ?)',
      );
      final insertCard = seed.prepare(
        'INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, '
        'ivl, factor, reps, lapses, `left`, odue, odid, flags, data) '
        'VALUES (?, ?, 1, 0, 0, -1, 0, 0, ?, 0, 0, 0, 0, 0, 0, 0, 0, ?)',
      );
      try {
        for (var index = 0; index < count; index++) {
          final noteId = baseId + index;
          final cardId = baseId + count + index;
          insertNote.execute([
            noteId,
            'large-$index',
            notetypeId,
            '',
            'front-$index\x1fback',
            '',
          ]);
          insertCard.execute([cardId, noteId, index, '{}']);
        }
      } finally {
        insertNote.close();
        insertCard.close();
        seed.close();
      }

      final database = await _openLatestCollection(path);
      await expectLater(
        database.exportApkg(
          limit: ApkgExportLimit(deckIds: [Int64.ONE, Int64(999999)]),
          options: const ApkgExportOptions(withMedia: false),
        ),
        throwsArgumentError,
      );
      final bytes = await database.exportApkg(
        limit: ApkgExportLimit(
          noteIds: [
            for (var index = 0; index < count; index++) Int64(baseId + index),
          ],
        ),
        options: const ApkgExportOptions(withMedia: false),
      );
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      final current = zstdDecode(
        Uint8List.fromList(
          archive.findFile('collection.anki21b')!.content as List<int>,
        ),
      );
      final exportPath = '${directory.path}/large-selection.db';
      await File(exportPath).writeAsBytes(current);
      final exported = sqlite3.open(exportPath);
      exported.createCollation(
        name: 'unicase',
        function: (left, right) =>
            (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase()),
      );
      expect(exported.select('SELECT count(*) FROM notes').single[0], count);
      expect(exported.select('SELECT count(*) FROM cards').single[0], count);
      expect(
        exported.select('SELECT DISTINCT did FROM cards').single['did'],
        1,
      );
      expect(exported.select('SELECT count(*) FROM decks').single[0], 0);
      exported.close();
      await database.close();
    },
  );

  test('export waiting for snapshot lock rejects a concurrent close', () async {
    final flushStarted = Completer<void>();
    final releaseFlush = Completer<void>();
    var holdFlush = false;
    final driver = CollectionSqliteDriver(
      openDatabase: (location) => sqlite3.open(location),
      flush: () async {
        if (!holdFlush) return;
        if (!flushStarted.isCompleted) flushStarted.complete();
        await releaseFlush.future;
      },
      snapshot: _snapshotDatabase,
      exportFromSnapshot: (source, build) async {
        final copy = sqlite3.openInMemory();
        try {
          await (source as Database).backup(copy).drain<void>();
          return await build(copy);
        } finally {
          copy.close();
        }
      },
    );
    final database = await _openLatestCollection(path, driver: driver);
    holdFlush = true;

    final snapshot = database.createSnapshot();
    await flushStarted.future;
    final pendingExport = database.exportFromSnapshot(
      (_) async => Uint8List(0),
    );
    final close = database.close();
    releaseFlush.complete();

    await snapshot;
    await expectLater(pendingExport, throwsA(isA<StateError>()));
    await close;
  });

  test(
    'scheduling-off export converts filtered deck and retains its card',
    () async {
      final initial = await _openLatestCollection(path);
      var random = BigInt.one;
      await initial.addInitialStockNoteTypes(
        names: _InitialText().stockNotetypeNames,
        randomU64: () {
          final value = random;
          random += BigInt.one;
          return value;
        },
        now: DateTime.now(),
      );
      final notetypeId = await initial.queryInt(
        "SELECT id FROM notetypes WHERE name = 'Basic'",
      );
      await initial.close();

      final noteId = DateTime.now().millisecondsSinceEpoch - 30000;
      final cardId = noteId + 1;
      final seed = sqlite3.open(path);
      seed.createCollation(
        name: 'unicase',
        function: (left, right) =>
            (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase()),
      );
      seed.execute(
        'INSERT INTO decks (id, name, mtime_secs, usn, common, kind) '
        'VALUES (2, ?, 0, -1, ?, ?)',
        [
          'Home',
          proto.Deck_Common().writeToBuffer(),
          proto.Deck_KindContainer(
            normal: proto.Deck_Normal(configId: Int64.ONE),
          ).writeToBuffer(),
        ],
      );
      seed.execute(
        'INSERT INTO decks (id, name, mtime_secs, usn, common, kind) '
        'VALUES (3, ?, 0, -1, ?, ?)',
        [
          'Filtered',
          proto.Deck_Common(newStudied: 5).writeToBuffer(),
          proto.Deck_KindContainer(
            filtered: proto.Deck_Filtered(),
          ).writeToBuffer(),
        ],
      );
      seed.execute(
        'INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, '
        'flags, data) VALUES (?, ?, ?, 0, -1, ?, ?, 0, 0, 0, ?)',
        [
          noteId,
          'filtered-card',
          notetypeId,
          'marked leech kept',
          'front\x1fback',
          '',
        ],
      );
      seed.execute(
        'INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, '
        'ivl, factor, reps, lapses, `left`, odue, odid, flags, data) '
        'VALUES (?, ?, 3, 0, 0, -1, 2, 2, 100, 15, 2500, 2, 1, 0, 44, 2, 4, ?)',
        [cardId, noteId, '{}'],
      );
      seed.close();

      final database = await _openLatestCollection(path);
      final apkg = await database.exportApkg(
        limit: ApkgExportLimit(deckId: Int64(3)),
        options: const ApkgExportOptions(withMedia: false),
      );
      final archive = ZipDecoder().decodeBytes(apkg);
      final current = zstdDecode(
        Uint8List.fromList(
          archive.findFile('collection.anki21b')!.content as List<int>,
        ),
      );
      final exportPath = '${directory.path}/filtered-export.db';
      await File(exportPath).writeAsBytes(current);
      final exported = sqlite3.open(exportPath);
      exported.createCollation(
        name: 'unicase',
        function: (left, right) =>
            (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase()),
      );
      final card = exported
          .select('SELECT did, odid, due, flags, reps FROM cards')
          .single;
      expect(card['did'], 3);
      expect(card['odid'], 0);
      expect(card['due'], 1);
      expect(card['flags'], 0);
      expect(card['reps'], 0);
      expect(exported.select('SELECT id FROM decks').map((row) => row['id']), [
        3,
      ]);
      final deckKind = proto.Deck_KindContainer.fromBuffer(
        exported.select('SELECT kind FROM decks WHERE id = 3').single['kind']
            as List<int>,
      );
      expect(deckKind.hasNormal(), isTrue);
      expect(
        proto.Deck_Common.fromBuffer(
          exported
                  .select('SELECT common FROM decks WHERE id = 3')
                  .single['common']
              as List<int>,
        ).newStudied,
        0,
      );
      expect(exported.select('SELECT tags FROM notes').single['tags'], 'kept');
      exported.close();
      await database.close();
    },
  );

  test(
    'scheduling-on export restores filtered card when home deck is absent',
    () async {
      final initial = await _openLatestCollection(path);
      var random = BigInt.one;
      await initial.addInitialStockNoteTypes(
        names: _InitialText().stockNotetypeNames,
        randomU64: () {
          final value = random;
          random += BigInt.one;
          return value;
        },
        now: DateTime.now(),
      );
      final notetypeId = await initial.queryInt(
        "SELECT id FROM notetypes WHERE name = 'Basic'",
      );
      await initial.close();

      final noteId = DateTime.now().millisecondsSinceEpoch - 30000;
      final cardId = noteId + 1;
      final seed = sqlite3.open(path);
      seed.createCollation(
        name: 'unicase',
        function: (left, right) =>
            (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase()),
      );
      seed.execute(
        'INSERT INTO decks (id, name, mtime_secs, usn, common, kind) '
        'VALUES (2, ?, 0, -1, ?, ?)',
        [
          'Home',
          proto.Deck_Common().writeToBuffer(),
          proto.Deck_KindContainer(
            normal: proto.Deck_Normal(configId: Int64.ONE),
          ).writeToBuffer(),
        ],
      );
      seed.execute(
        'INSERT INTO decks (id, name, mtime_secs, usn, common, kind) '
        'VALUES (3, ?, 0, -1, ?, ?)',
        [
          'Filtered',
          proto.Deck_Common().writeToBuffer(),
          proto.Deck_KindContainer(
            filtered: proto.Deck_Filtered(),
          ).writeToBuffer(),
        ],
      );
      seed.execute(
        'INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, '
        'flags, data) VALUES (?, ?, ?, 0, -1, ?, ?, 0, 0, 0, ?)',
        [
          noteId,
          'missing-home-deck',
          notetypeId,
          'marked',
          'front\x1fback',
          '',
        ],
      );
      seed.execute(
        'INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, '
        'ivl, factor, reps, lapses, `left`, odue, odid, flags, data) '
        'VALUES (?, ?, 3, 0, 0, -1, 2, 2, 100, 15, 2500, 2, 1, 0, 44, 2, 4, ?)',
        [cardId, noteId, '{}'],
      );
      seed.execute(
        'INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, '
        'flags, data) VALUES (?, ?, ?, 0, -1, ?, ?, 0, 0, 0, ?)',
        [
          noteId + 3,
          'missing-home-deck',
          notetypeId,
          'marked',
          'front2\x1fback2',
          '',
        ],
      );
      seed.execute(
        'INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, '
        'ivl, factor, reps, lapses, `left`, odue, odid, flags, data) '
        'VALUES (?, ?, 3, 0, 0, -1, 2, 2, 101, 15, 2500, 2, 1, 0, 55, 99, 2, ?)',
        [cardId + 4, noteId + 3, '{}'],
      );
      seed.execute(
        'INSERT INTO revlog (id, cid, usn, ease, ivl, lastIvl, factor, time, '
        'type) VALUES (?, ?, -1, 3, 15, 10, 2500, 3000, 1)',
        [noteId + 2, cardId],
      );
      seed.close();

      final database = await _openLatestCollection(path);
      final apkg = await database.exportApkg(
        limit: ApkgExportLimit(cardIds: [Int64(cardId), Int64(cardId + 4)]),
        options: const ApkgExportOptions(
          withScheduling: true,
          withMedia: false,
        ),
      );
      final archive = ZipDecoder().decodeBytes(apkg);
      final current = zstdDecode(
        Uint8List.fromList(
          archive.findFile('collection.anki21b')!.content as List<int>,
        ),
      );
      final exportPath = '${directory.path}/filtered-scheduled-export.db';
      await File(exportPath).writeAsBytes(current);
      final exported = sqlite3.open(exportPath);
      exported.createCollation(
        name: 'unicase',
        function: (left, right) =>
            (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase()),
      );

      final cards = exported.select(
        'SELECT id, did, odid, due, queue, flags FROM cards ORDER BY id',
      );
      expect(cards.length, 2);
      expect(cards[0]['did'], 3);
      expect(cards[0]['odid'], 0);
      expect(cards[0]['due'], 44);
      expect(cards[0]['queue'], 2);
      expect(cards[0]['flags'], 4);
      expect(cards[1]['did'], 3);
      expect(cards[1]['odid'], 0);
      expect(cards[1]['due'], 55);
      expect(cards[1]['queue'], 2);
      expect(cards[1]['flags'], 2);
      expect(
        exported.select('SELECT id FROM decks').map((row) => row['id']).toSet(),
        {2, 3},
      );
      expect(exported.select('SELECT id FROM revlog').length, 1);
      final kind = proto.Deck_KindContainer.fromBuffer(
        exported.select('SELECT kind FROM decks WHERE id = 3').single['kind']
            as List<int>,
      );
      expect(kind.hasNormal(), isTrue);
      exported.close();
      await database.close();
    },
  );

  test('creates schema 11 and current-schema reopen is a no-op', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    final result = await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );

    expect(result, const CollectionOpenResult(created: true, upgraded: true));
    expect(await database.queryInt('select ver from col'), 18);
    expect(await database.queryInt('pragma page_size'), 4096);
    expect(await database.queryInt('pragma busy_timeout'), 0);
    expect(await database.queryString('pragma locking_mode'), 'exclusive');
    expect(await database.queryInt('pragma cache_size'), -40960);
    expect(await database.queryString('pragma journal_mode'), 'wal');
    await database.close();

    final reopened = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    expect(
      await openOrCreateCollection(
        reopened,
        _Callbacks(reopened),
        serverMode: true,
      ),
      const CollectionOpenResult(created: false, upgraded: false),
    );
    expect(await reopened.queryInt('select count(*) from col'), 1);
    await reopened.close();
  });

  test(
    'reads current and remembered deck IDs without JS number narrowing',
    () async {
      final database = await _openLatestCollection(path);
      const wideId = '9007199254740995';
      await database.executeBatch(
        "INSERT OR REPLACE INTO config (key, usn, mtime_secs, val) "
        "VALUES ('curDeck', -1, 0, CAST('$wideId' AS BLOB))",
      );
      await database.executeBatch(
        "INSERT OR REPLACE INTO config (key, usn, mtime_secs, val) "
        "VALUES ('_nt_9_lastDeck', -1, 0, CAST('$wideId' AS BLOB))",
      );

      expect(database.currentDeckId, Int64.parseInt(wideId));
      expect(
        database.readCollectionConfigInt64('_nt_9_lastDeck'),
        Int64.parseInt(wideId),
      );
      await database.close();
    },
  );

  test('source callbacks create localized defaults and reopen unchanged', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    var random = BigInt.zero;
    final migrations = _Callbacks(database);
    final callbacks = CollectionSqliteInitializationCallbacks(
      storage: database,
      text: _InitialText(),
      migrations: migrations,
      localMinutesWest: (_) => -480,
      randomU64: () {
        final value = random;
        random += BigInt.one;
        return value;
      },
      clock: () => DateTime.utc(2026, 5, 9, 12),
    );

    final result = await openOrCreateCollection(
      database,
      callbacks,
      serverMode: false,
    );

    expect(result.created, isTrue);
    expect(await database.queryInt('select ver from col'), 18);
    expect(
      await database.queryInt('select crt from col'),
      DateTime.utc(2026, 5, 8, 20).millisecondsSinceEpoch ~/ 1000,
    );
    expect(
      await database.queryInt('select scm from col'),
      DateTime.utc(2026, 5, 9, 12).millisecondsSinceEpoch,
    );
    final config = jsonDecode(
      await database.queryString('select conf from col'),
    );
    expect(config['activeDecks'], [1]);
    expect(config['creationOffset'], -480);
    expect(await database.queryString('select name from decks'), 'Default');
    expect(await database.queryInt('select id from deck_config'), 1);
    expect(
      await database.queryString('select name from deck_config'),
      'Default',
    );
    expect(
      await database.queryString('select hex(config) from deck_config'),
      DeckConfig.defaults().inner
          .writeToBuffer()
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase(),
    );
    expect(await database.queryInt('select count(*) from notetypes'), 6);
    expect(
      await database.queryString(
        "select group_concat(name, '|') from (select name from notetypes order by id)",
      ),
      'Basic|Basic (and reversed card)|Basic (optional reversed card)|Basic (type answer)|Cloze|Image Occlusion',
    );
    final basicConfig = notetype_proto.Notetype_Config.fromBuffer(
      _decodeHex(
        await database.queryString(
          "select hex(config) from notetypes where name = 'Basic'",
        ),
      ),
    );
    expect(
      basicConfig.reqs.single.kind,
      notetype_proto.Notetype_Config_CardRequirement_Kind.KIND_ANY,
    );
    expect(basicConfig.reqs.single.fieldOrds, [0]);
    final optionalConfig = notetype_proto.Notetype_Config.fromBuffer(
      _decodeHex(
        await database.queryString(
          "select hex(config) from notetypes where name = 'Basic (optional reversed card)'",
        ),
      ),
    );
    expect(optionalConfig.reqs.map((req) => req.kind), [
      notetype_proto.Notetype_Config_CardRequirement_Kind.KIND_ANY,
      notetype_proto.Notetype_Config_CardRequirement_Kind.KIND_ALL,
    ]);
    expect(optionalConfig.reqs[1].fieldOrds, [1, 2]);
    final stockRequirements = <String, List<String>>{
      'Basic': ['1:0'],
      'Basic (and reversed card)': ['1:0', '1:1'],
      'Basic (optional reversed card)': ['1:0', '2:1,2'],
      'Basic (type answer)': ['1:0,1'],
      'Cloze': ['1:0'],
      'Image Occlusion': ['1:0,1,2'],
    };
    for (final entry in stockRequirements.entries) {
      final stockConfig = notetype_proto.Notetype_Config.fromBuffer(
        _decodeHex(
          await database.queryString(
            "select hex(config) from notetypes where name = '${entry.key}'",
          ),
        ),
      );
      expect(
        stockConfig.reqs
            .map((req) => '${req.kind.value}:${req.fieldOrds.join(',')}')
            .toList(),
        entry.value,
        reason: entry.key,
      );
    }
    expect(
      await database.queryInt('select count(*) from fields'),
      greaterThan(6),
    );
    expect(
      await database.queryInt('select count(*) from templates'),
      greaterThan(6),
    );
    expect(await database.queryString('select key from config'), 'curModel');
    expect(
      await database.queryInt(
        'select cast(val as text) = cast((select id from notetypes order by id limit 1) as text) from config',
      ),
      1,
    );

    await database.close();
    final reopened = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    final reopenedResult = await openOrCreateCollection(
      reopened,
      callbacks,
      serverMode: false,
    );
    expect(reopenedResult.created, isFalse);
    expect(await reopened.queryInt('select count(*) from notetypes'), 6);
    await reopened.close();
  });

  test(
    'server creation omits the timezone offset and callback failure rolls back',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
        options: _schemaOptions,
      );
      final callbacks = CollectionSqliteInitializationCallbacks(
        storage: database,
        text: _InitialText(),
        migrations: _Callbacks(database),
        localMinutesWest: (_) => 300,
        randomU64: () => BigInt.one,
        clock: () => DateTime.utc(2026, 5, 9, 12),
      );
      await openOrCreateCollection(database, callbacks, serverMode: true);
      final config = jsonDecode(
        await database.queryString('select conf from col'),
      );
      expect(config['creationOffset'], isNull);
      await database.close();

      final failingPath = '$path.failure';
      final failingDatabase = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: failingPath,
        options: _schemaOptions,
      );
      final failingCallbacks = CollectionSqliteInitializationCallbacks(
        storage: failingDatabase,
        text: _InitialText(),
        migrations: _Callbacks(failingDatabase),
        localMinutesWest: (_) => 300,
        randomU64: () => throw StateError('random source failed'),
        clock: () => DateTime.utc(2026, 5, 9, 12),
      );
      await expectLater(
        openOrCreateCollection(
          failingDatabase,
          failingCallbacks,
          serverMode: true,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        await failingDatabase.queryInt(
          "select count(*) from sqlite_master where type = 'table' and name = 'col'",
        ),
        0,
      );
      await failingDatabase.close();
    },
  );

  test('exposes revlog row storage through an opened collection', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );
    final entry = RevlogEntry(
      id: RevlogId(Int64.parseInt('9007199254740993')),
      cardId: Int64.parseInt('9007199254740995'),
      usn: -1,
      buttonChosen: 3,
      interval: -60,
      lastInterval: 30,
      easeFactor: 2500,
      takenMillis: 1200,
      reviewKind: RevlogReviewKind.review,
    );

    expect(database.revlog.addRevlogEntry(entry), entry.id);
    final loaded = database.revlog.getRevlogEntry(entry.id)!;
    expect(loaded.id, entry.id);
    expect(loaded.cardId, entry.cardId);
    expect(loaded.interval, -60);
    expect(loaded.reviewKind, RevlogReviewKind.review);
    database.revlog.removeRevlogEntry(entry.id);
    expect(database.revlog.getRevlogEntry(entry.id), isNull);
    await database.close();
  });

  test(
    'registers Core field_at_index semantics on each collection connection',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );

      expect(
        await database.queryString(
          "SELECT field_at_index('first' || char(31) || '' || char(31) || 'third', 0)",
        ),
        'first',
      );
      expect(
        await database.queryString(
          "SELECT field_at_index('first' || char(31) || '' || char(31) || 'third', 1)",
        ),
        '',
      );
      expect(
        await database.queryString(
          "SELECT field_at_index('first' || char(31) || '' || char(31) || 'third', 2)",
        ),
        'third',
      );
      expect(
        await database.queryString(
          "SELECT process_text('Über {{c1::café::hint}}', 3)",
        ),
        'Uber cafe',
      );
      expect(
        await database.queryInt(
          "SELECT extract_original_position('{\"pos\":42}')",
        ),
        42,
      );
      expect(
        await database.queryString(
          "SELECT extract_custom_data('{\"cd\":\"{\\\"x\\\":true}\"}', 'x')",
        ),
        'true',
      );
      expect(
        await database.queryInt(
          "SELECT extract_fsrs_variable('{\"s\":1.25}', 's') = 1.25",
        ),
        1,
      );
      expect(
        await database.queryInt("SELECT regexp('needle', 'hay needle')"),
        1,
      );
      expect(
        await database.queryInt(
          r"SELECT regexp_fields('^c$', 'a' || char(31) || 'b' || char(31) || 'c', 2)",
        ),
        1,
      );
      expect(await database.queryInt(r"SELECT regexp_tags('^b$', 'a  b')"), 1);
      expect(
        await database.queryInt('SELECT fnvhash(1, 2)'),
        8581494755304202342,
      );
      expect(
        await database.queryString("SELECT field_at_index('only', 65535)"),
        '',
      );
      expect(
        await database.queryString("SELECT field_at_index('only', 1)"),
        '',
      );
      await expectLater(
        database.queryString("SELECT field_at_index('only', 65536)"),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        database.queryString('SELECT field_at_index(NULL, 0)'),
        throwsA(isA<SqliteException>()),
      );
      await database.close();

      final reopened = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );
      expect(
        await reopened.queryString(
          "SELECT field_at_index('first' || char(31) || 'second', 1)",
        ),
        'second',
      );
      expect(
        await reopened.queryString(
          "SELECT process_text('Über {{c1::café::hint}}', 3)",
        ),
        'Uber cafe',
      );
      expect(
        await reopened.queryInt(
          "SELECT extract_original_position('{\"pos\":42}')",
        ),
        42,
      );
      expect(
        await reopened.queryString(
          "SELECT extract_custom_data('{\"cd\":\"{\\\"x\\\":true}\"}', 'x')",
        ),
        'true',
      );
      expect(
        await reopened.queryInt(
          "SELECT extract_fsrs_variable('{\"s\":1.25}', 's') = 1.25",
        ),
        1,
      );
      expect(
        await reopened.queryInt("SELECT regexp('needle', 'hay needle')"),
        1,
      );
      expect(
        await reopened.queryInt('SELECT fnvhash(1, 2)'),
        8581494755304202342,
      );
      await reopened.close();
    },
  );

  test('deck storage persists rows through the collection connection', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );

    final added = database.decks.addDeck(
      Deck(
        name: 'Parent :: Child',
        mtimeSecs: Int64(123),
        usn: 4,
        common: proto.Deck_Common(studyCollapsed: true),
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(7))),
      ),
    );

    expect(added.id, isNot(Int64.ZERO));
    expect(database.decks.getDeck(added.id)!.name, 'Parent::Child');
    expect(database.decks.getDeckByName('parent\x1fchild')!.id, added.id);
    expect(database.decks.getDeckId('parent\x1fchild'), added.id);
    expect(
      database.decks.getDeck(added.id)!.toProto().normal.configId,
      Int64(7),
    );
    expect(
      database.decks.getAllDeckNames(),
      contains((added.id, 'Parent::Child')),
    );
    database.decks.db.execute(
      "UPDATE decks SET name = '  Parent' || char(31) || 'Child  ' WHERE id = ?",
      [added.id.toInt()],
    );
    expect(database.decks.getDeck(added.id)!.name, '  Parent::Child  ');
    database.decks.removeDeck(added.id);
    expect(database.decks.getDeck(added.id), isNull);

    final largeId = Int64.parseInt('9007199254740993');
    database.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: largeId,
        name: 'Large ID',
        mtimeSecs: Int64(456),
        usn: 5,
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(7))),
      ),
    );
    expect(database.decks.getDeck(largeId)!.id, largeId);
    await database.close();
  });

  test(
    'deck description update preserves exact ID, Markdown, and undo',
    () async {
      final database = await _openLatestCollection(path);
      final id = Int64.parseInt('9007199254740995');
      database.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: id,
          name: 'Description test',
          kind: NormalDeckKind(
            proto.Deck_Normal(configId: Int64(17), description: 'before'),
          ),
        ),
      );

      await database.updateDeckDescription(
        id,
        description: 'after\nsecond line',
        markdownDescription: true,
      );
      var updated = database.decks.getDeck(id)!;
      expect(updated.id, id);
      expect(updated.kind, isA<NormalDeckKind>());
      var normal = (updated.kind as NormalDeckKind).value;
      expect(normal.description, 'after\nsecond line');
      expect(normal.markdownDescription, isTrue);
      expect(normal.configId, Int64(17));
      expect(database.canUndoCollectionOperation, isTrue);

      await database.undoLastCollectionOperation();
      updated = database.decks.getDeck(id)!;
      normal = (updated.kind as NormalDeckKind).value;
      expect(normal.description, 'before');
      expect(normal.markdownDescription, isFalse);

      await database.redoLastCollectionOperation();
      updated = database.decks.getDeck(id)!;
      normal = (updated.kind as NormalDeckKind).value;
      expect(normal.description, 'after\nsecond line');
      expect(normal.markdownDescription, isTrue);
      await database.close();
    },
  );

  test(
    'deck description rejects missing decks and rolls back storage errors',
    () async {
      final database = await _openLatestCollection(path);
      final id = Int64.parseInt('9007199254740995');
      database.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: id,
          name: 'Description failure test',
          kind: NormalDeckKind(
            proto.Deck_Normal(configId: Int64(17), description: 'before'),
          ),
        ),
      );
      final filteredId = Int64(41);
      database.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: filteredId,
          name: 'Filtered description test',
          kind: FilteredDeckKind(proto.Deck_Filtered()),
        ),
      );

      await expectLater(
        database.updateDeckDescription(
          Int64(987654),
          description: 'missing',
          markdownDescription: true,
        ),
        throwsStateError,
      );
      await expectLater(
        database.updateDeckDescription(
          filteredId,
          description: 'filtered',
          markdownDescription: true,
        ),
        throwsStateError,
      );
      database.decks.db.execute('''
CREATE TRIGGER reject_description_update BEFORE UPDATE ON decks
BEGIN
  SELECT RAISE(ABORT, 'storage failure');
END
''');
      await expectLater(
        database.updateDeckDescription(
          id,
          description: 'after',
          markdownDescription: true,
        ),
        throwsA(isA<SqliteException>()),
      );
      final normal = (database.decks.getDeck(id)!.kind as NormalDeckKind).value;
      expect(normal.description, 'before');
      expect(normal.markdownDescription, isFalse);
      expect(database.canUndoCollectionOperation, isFalse);
      await database.close();
    },
  );

  test('deckTree queries scheduler queues and projects Core limits', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );
    final config = database.deckConfigs.addDeckConfig(
      DeckConfig(name: 'Default', inner: DeckConfig.defaults().inner),
    );
    final deck = database.decks.addDeck(
      Deck(
        name: 'Default',
        kind: NormalDeckKind(proto.Deck_Normal(configId: config.id)),
      ),
    );
    await database.addCard(
      Card.newCard(noteId: Int64(101), templateIdx: 0, deckId: deck.id, due: 0),
    );
    await database.addCard(
      Card(
        noteId: Int64(102),
        deckId: deck.id,
        queue: CardQueue.review,
        ctype: CardType.review,
        due: 1,
      ),
    );
    await database.addCard(
      Card(
        noteId: Int64(103),
        deckId: deck.id,
        queue: CardQueue.learn,
        ctype: CardType.learn,
        due: 1999,
      ),
    );
    await database.addCard(
      Card(
        noteId: Int64(104),
        deckId: deck.id,
        queue: CardQueue.dayLearn,
        ctype: CardType.relearn,
        due: 1,
      ),
    );

    final tree = await database.deckTree(daysElapsed: 1, learnCutoff: 2000);
    final defaultDeck = tree.children.single;
    expect(defaultDeck.deckId, deck.id);
    expect(defaultDeck.newCount, 1);
    expect(defaultDeck.reviewCount, 1);
    expect(defaultDeck.learnCount, 2);
    expect(defaultDeck.intradayLearning, 1);
    expect(defaultDeck.interdayLearningUncapped, 1);
    expect(defaultDeck.totalInDeck, 4);
    expect(defaultDeck.totalIncludingChildren, 4);
    await database.close();
  });

  test(
    'deckTreeForNow restores buried cards after the due day rolls over',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
        options: _schemaOptions,
      );
      await openOrCreateCollection(
        database,
        _Callbacks(database),
        serverMode: true,
      );
      database.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        DeckConfig(
          id: Int64.ONE,
          name: 'Default',
          inner: DeckConfig.defaults().inner,
        ),
      );
      final deck = database.decks.addDeck(
        Deck(
          name: 'Default',
          kind: NormalDeckKind(proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      final cardId = await database.addCard(
        Card(
          noteId: Int64(201),
          deckId: deck.id,
          queue: CardQueue.schedBuried,
          due: 0,
        ),
      );
      final unrelatedCardId = await database.addCard(
        Card(
          noteId: Int64(202),
          deckId: deck.id,
          queue: CardQueue.newCard,
          due: 1,
        ),
      );
      final creationSecs = await database.queryInt('SELECT crt FROM col');
      final now = DateTime.fromMillisecondsSinceEpoch(
        (creationSecs + 10 * Duration.secondsPerDay) * 1000,
        isUtc: true,
      );

      final beforeBulkSuspend = (await database.getCard(unrelatedCardId))!;
      final suspended = Card.fromProto(
        beforeBulkSuspend.toProto()..queue = CardQueue.suspended.value,
      );
      await database.runUndoableCollectionOperation(
        apply: () async => database.updateCard(suspended),
        undo: () async => database.updateCard(beforeBulkSuspend),
        redo: () async => database.updateCard(suspended),
      );
      expect(database.canUndoCollectionOperation, isTrue);

      final tree = await database.deckTreeForNow(now: now);

      expect(database.canUndoCollectionOperation, isFalse);
      expect((await database.getCard(cardId))!.queue, CardQueue.newCard);
      expect(tree.children.single.newCount, 1);
      expect(
        int.parse(
          await database.queryString(
            "SELECT CAST(val AS TEXT) FROM config WHERE key = 'lastUnburied'",
          ),
        ),
        greaterThan(0),
      );
      expect(
        await database.queryInt(
          "SELECT usn FROM config WHERE key = 'lastUnburied'",
        ),
        -1,
      );
      await database.close();
    },
  );

  test(
    'deck picker storage creates, selects, collapses, and checks descendants',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
        options: _schemaOptions,
      );
      await openOrCreateCollection(
        database,
        _Callbacks(database),
        serverMode: true,
      );
      database.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        DeckConfig(
          id: Int64.ONE,
          name: 'Default',
          inner: DeckConfig.defaults().inner,
        ),
      );
      database.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: Int64.ONE,
          name: 'Default',
          kind: NormalDeckKind(proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );

      final deck = await database.getOrCreateNormalDeck('Languages::Spanish');
      expect(database.decks.getDeckId('Languages'), isNotNull);
      expect(deck.name, 'Languages::Spanish');
      expect(
        (await database.getOrCreateNormalDeck('Languages::Spanish')).id,
        deck.id,
      );
      await database.selectDeck(deck.id);
      expect(database.currentDeckId, deck.id);
      expect(
        await database.queryInt("SELECT usn FROM config WHERE key = 'curDeck'"),
        -1,
      );
      await database.setDeckCollapsed(deck.id, collapsed: true);
      expect(database.decks.getDeck(deck.id)!.common.studyCollapsed, isTrue);
      expect(database.decks.getDeck(deck.id)!.usn, -1);
      await database.addCard(
        Card(
          noteId: Int64(301),
          deckId: deck.id,
          queue: CardQueue.userBuried,
          ctype: CardType.newCard,
        ),
      );
      final parent = database.decks.getDeckByName('Languages')!;
      expect(database.deckHasBuriedCards(parent.id), isTrue);
      expect(database.deckHasBuriedCards(deck.id), isTrue);
      await database.close();
    },
  );

  test(
    'subdeck creation preserves parent IDs and validates the full path',
    () async {
      final database = await _openLatestCollection(path);
      final parentId = Int64.parseInt('9007199254740995');
      database.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: parentId,
          name: 'Languages',
          kind: NormalDeckKind(proto.Deck_Normal(configId: Int64.ONE)),
        ),
      );

      final filteredId = Int64.parseInt('9007199254740996');
      database.decks.addOrUpdateDeckWithExistingId(
        Deck(
          id: filteredId,
          name: 'Filtered',
          kind: FilteredDeckKind(proto.Deck_Filtered()),
        ),
      );
      await database.getOrCreateNormalDeck('Languages::travel');

      final child = await database.createSubdeck(parentId, ' Spanish ');
      expect(child.name, 'Languages::Spanish');
      expect(database.decks.getDeck(child.id)?.id, child.id);
      expect(database.decks.getDeckId('Languages\x1fSpanish'), child.id);
      expect(database.currentDeckId, child.id);
      expect(database.canUndoCollectionOperation, isTrue);
      await expectLater(
        database.createSubdeck(parentId, 'Spanish'),
        throwsStateError,
      );
      await expectLater(
        database.createSubdeck(Int64(999999), 'Missing'),
        throwsStateError,
      );
      await expectLater(
        database.createSubdeck(parentId, '""'),
        throwsArgumentError,
      );

      await expectLater(
        database.createSubdeck(filteredId, 'Child'),
        throwsStateError,
      );
      expect(database.decks.getDeckByName('Filtered\x1fChild'), isNull);

      final nested = await database.createSubdeck(parentId, 'TRAVEL::Asia');
      expect(nested.name, 'Languages::travel::Asia');
      expect(database.decks.getDeckByName('Languages\x1ftravel'), isNotNull);
      await expectLater(
        database.createSubdeck(parentId, 'travel::ASIA'),
        throwsStateError,
      );

      final generatedParent = await database.createSubdeck(
        parentId,
        'Places::Europe',
      );
      expect(generatedParent.name, 'Languages::Places::Europe');
      expect(database.decks.getDeckByName('Languages\x1fPlaces'), isNotNull);
      await database.undoLastCollectionOperation();
      expect(database.currentDeckId, nested.id);
      expect(database.decks.getDeck(generatedParent.id), isNull);
      expect(database.decks.getDeckByName('Languages\x1fPlaces'), isNull);
      await database.redoLastCollectionOperation();
      expect(database.currentDeckId, generatedParent.id);
      expect(
        database.decks.getDeck(generatedParent.id)?.name,
        'Languages::Places::Europe',
      );
      await database.undoLastCollectionOperation();
      expect(database.currentDeckId, nested.id);
      await database.undoLastCollectionOperation();
      expect(database.currentDeckId, child.id);
      expect(database.decks.getDeck(nested.id), isNull);
      expect(database.decks.getDeckByName('Languages\x1ftravel'), isNotNull);
      await database.redoLastCollectionOperation();
      expect(database.currentDeckId, nested.id);
      expect(
        database.decks.getDeck(nested.id)?.name,
        'Languages::travel::Asia',
      );
      await database.undoLastCollectionOperation();
      expect(database.currentDeckId, child.id);
      await database.undoLastCollectionOperation();
      expect(database.currentDeckId, Int64.ONE);
      expect(database.decks.getDeck(child.id), isNull);
      await database.redoLastCollectionOperation();

      expect(database.currentDeckId, child.id);
      expect(database.decks.getDeck(child.id)?.name, 'Languages::Spanish');

      await database.close();
    },
  );

  test('deck hierarchy reads use the schema unicase name collation', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );

    final parent = database.decks.addDeck(
      Deck(
        name: 'Parent',
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(1))),
      ),
    );
    final childId = Int64.parseInt('9007199254740993');
    database.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: childId,
        name: 'parent::Child',
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(1))),
      ),
    );
    database.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: Int64.parseInt('9007199254740994'),
        name: 'PARENT::Child::Grandchild',
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(1))),
      ),
    );
    database.decks.addOrUpdateDeckWithExistingId(
      Deck(
        id: Int64.parseInt('9007199254740995'),
        name: 'Parentish::Outside',
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(1))),
      ),
    );

    expect(database.decks.childDecks(parent).map((deck) => deck.name), [
      'parent::Child',
      'PARENT::Child::Grandchild',
    ]);
    expect(database.decks.deckIdWithChildren(parent).toSet(), {
      parent.id,
      childId,
      Int64.parseInt('9007199254740994'),
    });
    expect(
      database.decks
          .deckWithChildren(parent.id)
          .map((deck) => deck.name)
          .toSet(),
      {'Parent', 'parent::Child', 'PARENT::Child::Grandchild'},
    );

    database.decks.db.execute(
      "UPDATE decks SET name = 'Parent  ' WHERE id = ?",
      [BigInt.parse(parent.id.toString())],
    );
    database.decks.db.execute(
      "UPDATE decks SET name = 'Parent  ' || char(31) || 'Child' WHERE id = ?",
      [BigInt.parse(childId.toString())],
    );
    final storedParent = database.decks.getDeck(parent.id)!;
    expect(
      database.decks.childDecks(storedParent).single.name,
      'Parent  ::Child',
    );
    expect(
      database.decks
          .deckWithChildren(parent.id)
          .map((deck) => deck.name)
          .toSet(),
      {'Parent  ', 'Parent  ::Child'},
    );
    await database.close();
  });

  test('deck config storage uses the collection connection', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );
    final id = Int64.parseInt('9007199254740993');
    final config = DeckConfig(
      id: id,
      name: 'Custom',
      mtimeSecs: Int64(123),
      usn: -2,
      inner: config_proto.DeckConfig_Config(newPerDay: 45, initialEase: 2.4),
    );

    database.deckConfigs.addOrUpdateDeckConfigWithExistingId(config);

    final loaded = database.deckConfigs.getDeckConfig(id)!;
    expect(loaded.name, 'Custom');
    expect(loaded.mtimeSecs, Int64(123));
    expect(loaded.usn, -2);
    expect(loaded.inner.newPerDay, 45);
    expect(loaded.inner.initialEase, closeTo(2.4, 0.000001));
    expect(database.deckConfigs.getDeckConfigIdByName('Custom'), id);
    expect(database.deckConfigs.getDeckConfigIdByName('custom'), id);
    expect(database.deckConfigs.getDeckConfigMap().keys, contains(id));
    await database.close();
  });

  test('tag storage uses schema unicase matching and sync state', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await openOrCreateCollection(
      database,
      _Callbacks(database),
      serverMode: true,
    );
    await database.executeBatch('''
DROP TABLE tags;
CREATE TABLE tags (
  tag text NOT NULL PRIMARY KEY COLLATE unicase,
  usn integer NOT NULL,
  collapsed boolean NOT NULL,
  config blob NULL
) without rowid;''');
    database.tags.registerTag(Tag(name: 'TagName', usn: -1, expanded: true));

    expect(
      database.tags.getTag('TAGNAME'),
      Tag(name: 'TagName', usn: -1, expanded: true),
    );
    expect(database.tags.preferredTagCase('tagname'), 'TagName');
    expect(database.tags.expandedTags(), ['TagName']);
    expect(database.tags.tagsPendingSync(-1), ['TagName']);
    await database.close();
  });

  test('upgrades supported schema 14 fixture using the real database', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    await database.executeBatch(collectionSchema11Sql);
    await database.executeBatch(
      collectionSchemaSqlByPath['rslib/src/storage/upgrades/schema14_upgrade.sql']!,
    );
    await database.close();

    final reopened = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    final result = await openOrCreateCollection(
      reopened,
      _Callbacks(reopened),
      serverMode: true,
    );
    expect(result, const CollectionOpenResult(created: false, upgraded: true));
    expect(await reopened.queryInt('select ver from col'), 18);
    await reopened.close();
  });

  test(
    'integrity check reads SQLite result and propagates corruption result',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
        options: _schemaOptions,
      );
      final callbacks = _Callbacks(database);
      await openOrCreateCollection(database, callbacks, serverMode: true);
      expect(
        await openOrCreateCollection(
          database,
          callbacks,
          serverMode: true,
          checkIntegrity: true,
        ),
        const CollectionOpenResult(created: false, upgraded: false),
      );
      await database.executeBatch('''
      create table checked (value integer check (value > 0));
      pragma ignore_check_constraints = on;
      insert into checked values (-1);
      pragma ignore_check_constraints = off;
    ''');
      await expectLater(
        openOrCreateCollection(
          database,
          callbacks,
          serverMode: true,
          checkIntegrity: true,
        ),
        throwsA(isA<CollectionIntegrityException>()),
      );
      await database.close();
    },
  );

  test(
    'callback failure rolls back schema creation and preserves exception',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
        options: _schemaOptions,
      );
      final failure = StateError('metadata failed');
      await expectLater(
        openOrCreateCollection(
          database,
          _Callbacks(database, failure: failure),
          serverMode: true,
        ),
        throwsA(same(failure)),
      );
      expect(
        await database.queryExists(
          "select null from sqlite_master where type='table' and name='col'",
        ),
        isFalse,
      );
      await database.close();
    },
  );

  test('close is idempotent and does not remove the collection file', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
    );
    await database.executeBatch('create table retained (id integer);');
    await database.close();
    await database.close();

    expect(await File(path).exists(), isTrue);
    final reopened = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
    );
    expect(await reopened.queryInt('select count(*) from retained'), 0);
    await reopened.close();
  });

  test('driver persistence is awaited after a committed write', () async {
    var flushes = 0;
    final driver = CollectionSqliteDriver(
      openDatabase: (location) => sqlite3.open(location),
      flush: () => flushes++,
    );
    final database = await CollectionSqliteStorage.open(
      driver: driver,
      location: path,
    );
    expect(flushes, 1, reason: 'connection pragmas are persisted');
    await database.commit();
    await database.rollback();
    expect(flushes, 1, reason: 'idle transaction controls are no-ops');

    await database.beginExclusive();
    await database.executeBatch('create table persisted (id integer);');
    expect(flushes, 1, reason: 'transaction writes wait for commit');
    await database.commit();
    expect(flushes, 2, reason: 'commit flushes platform storage');
    await database.beginExclusive();
    await database.executeBatch("insert into persisted values (1);");
    await database.commit();
    expect(
      flushes,
      3,
      reason: 'cached begin and commit statements are reusable',
    );
    await database.close();
    expect(flushes, 4, reason: 'close flushes platform storage');
  });

  test('Android temporary storage option selects memory', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: const CollectionSqliteOptions(androidTempStore: true),
    );
    expect(await database.queryInt('pragma temp_store'), 2);
    await database.close();
  });

  test('quick check reports healthy databases as not corrupt', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
    );

    expect(await database.quickCheckCorrupt(), isFalse);

    await database.close();
  });

  test('quick check reports SQLite integrity findings as corruption', () async {
    final database = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
    );
    await database.executeBatch('''
      create table checked (value integer check (value > 0));
      pragma ignore_check_constraints = on;
      insert into checked values (-1);
      pragma ignore_check_constraints = off;
    ''');

    expect(await database.quickCheckCorrupt(), isTrue);

    await database.close();
  });

  test('checkpoint truncates WAL and flushes driver persistence', () async {
    var flushes = 0;
    final database = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (location) => sqlite3.open(location),
        flush: () => flushes++,
      ),
      location: path,
    );
    await database.executeBatch('create table checkpointed (id integer);');

    await database.checkpoint();

    expect(flushes, 3, reason: 'checkpoint awaits driver persistence');
    expect(await database.queryString('pragma journal_mode'), 'wal');
    await database.close();
  });

  test(
    'checkpoint rejects active transactions without committing them',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );
      await database.beginExclusive();
      await database.executeBatch(
        'create table still_transactional (id integer);',
      );

      await expectLater(database.checkpoint(), throwsStateError);

      await database.rollback();
      await database.close();
      final reopened = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );
      expect(
        await reopened.queryExists(
          "select null from sqlite_master where name = 'still_transactional'",
        ),
        isFalse,
      );
      await reopened.close();
    },
  );

  test(
    'optimize analyzes and leaves the file-backed database usable',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );
      await database.executeBatch('''
      create table optimized (id integer primary key, value text);
      create index optimized_value on optimized(value);
      insert into optimized(value) values ('first'), ('second'), ('third');
    ''');

      await database.optimize();

      expect(
        await database.queryInt('select count(*) from sqlite_stat1'),
        greaterThan(0),
      );
      expect(
        await database.queryString("select value from optimized where id = 2"),
        'second',
      );
      await database.close();
    },
  );

  test('close to schema 18 is a no-op', () async {
    final database = await _openLatestCollection(path);
    final callbacks = _Callbacks(database, calls: []);

    await database.close(desiredVersion: 18, callbacks: callbacks);

    final reopened = await CollectionSqliteStorage.open(
      driver: _nativeDriver,
      location: path,
      options: _schemaOptions,
    );
    expect(await reopened.queryInt('select ver from col'), 18);
    expect(await reopened.queryString('pragma journal_mode'), 'wal');
    expect(callbacks.calls, isEmpty);
    await reopened.close();
  });

  test(
    'close to schema 11 applies catalog downgrade and journal mode',
    () async {
      final database = await _openLatestCollection(path);
      final callbackCalls = <String>[];
      final callbacks = _Callbacks(database, calls: callbackCalls);

      await database.close(desiredVersion: 11, callbacks: callbacks);

      expect(callbackCalls, [
        'downgradeDeckConfFrom16',
        'downgradeDecksFrom15',
        'downgradeNotetypesFrom15',
        'downgradeConfigFrom14',
        'downgradeTagsFrom14',
      ]);
      final reopened = sqlite3.open(path);
      expect(reopened.select('select ver from col').first['ver'], 11);
      expect(
        reopened.select('pragma journal_mode').first.columnAt(0),
        'delete',
      );
      reopened.close();
    },
  );

  test(
    'invalid close target closes resources but preserves the collection',
    () async {
      final database = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );
      await database.executeBatch('create table retained (id integer);');

      await expectLater(
        database.close(desiredVersion: 14),
        throwsArgumentError,
      );

      expect(await File(path).exists(), isTrue);
      final reopened = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
      );
      expect(await reopened.queryInt('select count(*) from retained'), 0);
      await reopened.close();
    },
  );

  test(
    'downgrade callback failure rolls back and still closes database',
    () async {
      final database = await _openLatestCollection(path);
      final failure = StateError('downgrade callback failed');
      final callbacks = _Callbacks(
        database,
        failure: failure,
        failureName: 'downgradeNotetypesFrom15',
      );

      await expectLater(
        database.close(desiredVersion: 11, callbacks: callbacks),
        throwsA(same(failure)),
      );

      expect(await File(path).exists(), isTrue);
      final reopened = await CollectionSqliteStorage.open(
        driver: _nativeDriver,
        location: path,
        options: _schemaOptions,
      );
      expect(await reopened.queryInt('select ver from col'), 18);
      expect(await reopened.queryString('pragma journal_mode'), 'wal');
      await reopened.close();
    },
  );
}

Future<CollectionSqliteStorage> _openLatestCollection(
  String path, {
  CollectionSqliteDriver? driver,
}) async {
  final database = await CollectionSqliteStorage.open(
    driver: driver ?? _nativeDriver,
    location: path,
    options: _schemaOptions,
  );
  await openOrCreateCollection(
    database,
    _Callbacks(database),
    serverMode: true,
  );
  return database;
}

CollectionSqliteDriver _driverWithMedia(CollectionMediaStorage mediaStorage) =>
    CollectionSqliteDriver(
      openDatabase: (location) => sqlite3.open(location),
      snapshot: _snapshotDatabase,
      mediaStorage: mediaStorage,
      exportFromSnapshot: (source, build) async {
        final copy = sqlite3.openInMemory();
        try {
          await (source as Database).backup(copy).drain<void>();
          return await build(copy);
        } finally {
          copy.close();
        }
      },
    );

final class _MemoryMediaStorage implements CollectionMediaStorage {
  const _MemoryMediaStorage(this.files);

  final Map<String, List<int>> files;

  @override
  Future<void> close() async {}

  @override
  Future<Iterable<String>> list() async => files.keys;

  @override
  Future<Stream<List<int>>?> read(String filename) async {
    final bytes = files[filename];
    return bytes == null ? null : Stream.value(bytes);
  }
}

final CollectionSqliteDriver _nativeDriver = CollectionSqliteDriver(
  openDatabase: (location) => sqlite3.open(location),
  snapshot: _snapshotDatabase,
  exportFromSnapshot: (source, build) async {
    final copy = sqlite3.openInMemory();
    try {
      await (source as Database).backup(copy).drain<void>();
      return await build(copy);
    } finally {
      copy.close();
    }
  },
);

Future<Uint8List> _snapshotDatabase(CommonDatabase source) async {
  final directory = await Directory.systemTemp.createTemp(
    'anki-test-snapshot-',
  );
  final path = '${directory.path}/snapshot.db';
  Database? copy;
  try {
    copy = sqlite3.open(path);
    await (source as Database).backup(copy).drain<void>();
    copy.close();
    copy = null;
    return await File(path).readAsBytes();
  } finally {
    copy?.close();
    await directory.delete(recursive: true);
  }
}

final CollectionSqliteOptions _schemaOptions = CollectionSqliteOptions(
  configureConnection: (database) => database.createCollation(
    name: 'unicase',
    function: (left, right) =>
        (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase()),
  ),
);

final class _Callbacks implements CollectionOpenCallbacks {
  _Callbacks(this.database, {this.failure, this.failureName, this.calls});

  final CollectionSqliteStorage database;
  final Object? failure;
  final String? failureName;
  final List<String>? calls;

  @override
  void initializeCollectionMetadata({required bool serverMode}) {
    if (failure != null) throw failure!;
    database.executeBatch('update col set crt=1, scm=1, ver=11, conf=\'{}\'');
  }

  @override
  void addDefaultDeckConfig() {}

  @override
  void addDefaultDeck() {}

  @override
  void addStockNoteTypes() {}

  @override
  void run(String name, {bool? serverMode}) {
    calls?.add(name);
    if (name == failureName) throw failure!;
  }
}

final class _InitialText implements CollectionInitialTextProvider {
  @override
  String get defaultDeckName => 'Default';

  @override
  StockNotetypeNames get stockNotetypeNames => const StockNotetypeNames(
    basic: 'Basic',
    basicTyping: 'Basic (type answer)',
    basicReversed: 'Basic (and reversed card)',
    basicOptionalReversed: 'Basic (optional reversed card)',
    cloze: 'Cloze',
    frontField: 'Front',
    backField: 'Back',
    addReverseField: 'Add Reverse',
    textField: 'Text',
    backExtraField: 'Back Extra',
    commentsField: 'Comments',
    cardOne: 'Card 1',
    cardTwo: 'Card 2',
    imageOcclusion: 'Image Occlusion',
    occlusionsField: 'Occlusions',
    imageField: 'Image',
    headerField: 'Header',
    toggleMasks: 'Toggle Masks',
    errorLoadingImageOcclusion: 'Error loading Image Occlusion',
  );
}

List<int> _decodeHex(String value) => [
  for (var index = 0; index < value.length; index += 2)
    int.parse(value.substring(index, index + 2), radix: 16),
];
