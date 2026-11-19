// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:async';
import 'dart:convert';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as config_proto;
import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CollectionSqliteStorage storage;
  late Database database;
  late int nowMillis;
  late int nowMillisReads;
  late bool advanceClockAtCommit;
  late Future<void> Function()? flushHook;
  void Function()? onNowMillis;

  setUp(() async {
    nowMillis = 9007199254740993;
    nowMillisReads = 0;
    advanceClockAtCommit = false;
    flushHook = null;
    onNowMillis = null;
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => database = sqlite3.openInMemory(),
        flush: () async => flushHook?.call(),
      ),
      location: ':memory:',
      nowMillis: () {
        onNowMillis?.call();
        nowMillisReads++;
        if (advanceClockAtCommit && nowMillisReads == 2) nowMillis += 1_000;
        return nowMillis;
      },
    );
    _activeDatabase = database;
    await storage.executeBatch('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY, guid TEXT, mid INTEGER, mod INTEGER,
        usn INTEGER, tags TEXT, flds TEXT, sfld TEXT, csum INTEGER,
        flags INTEGER DEFAULT 0, data TEXT DEFAULT ''
      );
      CREATE TABLE col (mod INTEGER NOT NULL);
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER,
        mod INTEGER, usn INTEGER, type INTEGER, queue INTEGER, due INTEGER,
        ivl REAL, factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER,
        odue INTEGER, odid INTEGER, flags INTEGER, data TEXT
      );
      CREATE TABLE notetypes (
        id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER,
        config BLOB
      );
      CREATE TABLE fields (
        ntid INTEGER, ord INTEGER, name TEXT, config BLOB,
        PRIMARY KEY (ntid, ord)
      );
      CREATE TABLE templates (
        ntid INTEGER, ord INTEGER, name TEXT, mtime_secs INTEGER, usn INTEGER,
        config BLOB, PRIMARY KEY (ntid, ord)
      );
      CREATE TABLE config (
        KEY TEXT PRIMARY KEY, usn INTEGER, mtime_secs INTEGER, val BLOB
      );
      CREATE TABLE tags (
        tag TEXT PRIMARY KEY COLLATE unicase, usn INTEGER, collapsed INTEGER
      );
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER,
        common BLOB, kind BLOB
      );
      CREATE TABLE deck_config (
        id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER,
        config BLOB
      );
    ''');
    await storage.executeBatch('INSERT INTO col VALUES (500)');
    await _saveNotetype(storage, _normalNotetype());
    database.execute('INSERT INTO config VALUES (?, 0, 1, ?)', [
      'normalize_note_text',
      utf8.encode('true'),
    ]);
    database.execute('INSERT INTO config VALUES (?, 0, 1, ?)', [
      'nextPos',
      utf8.encode('1'),
    ]);
    await _saveDefaultDeck();
    await _insertStoredNote(_note(fields: ['front', 'back'], tags: ['old']));
  });

  tearDown(() async {
    await storage.close();
  });

  test(
    'unchanged semantic note ignores stale mtime and derived fields',
    () async {
      final edited = _note(fields: ['front', 'back'], tags: ['old'])
        ..mtimeSecs = Int64(4)
        ..prepareForUpdate(_normalNotetype(), normalizeText: true);
      final result = await storage.updateExistingNote(edited);

      expect(result.changed, isFalse);
      expect(result.undoRecord, isNull);
      expect(
        await storage.queryInt('SELECT mod FROM notes WHERE id = 42'),
        100,
      );
    },
  );

  test(
    'changed note marks mtime/usn and records the complete old note',
    () async {
      final edited = _note(fields: ['new front', 'back'], tags: [' topic ']);
      final result = await storage.updateExistingNote(edited);
      final stored = await storage.getNote(Int64(42));

      expect(result.changed, isTrue);
      expect(stored!.mtimeSecs, Int64(9007199254740));
      expect(stored.usn, -1);
      expect(result.undoRecord!.oldNote.fields, ['front', 'back']);
      expect(result.undoRecord!.oldNote.tags, ['old']);
      expect(result.undoRecord!.oldNote.mtimeSecs, Int64(100));
      expect(result.undoRecord!.collectionMtimeMillis, Int64(500));
      expect(result.undoRecord!.addedTags, ['topic']);
      expect(await storage.queryInt('SELECT mod FROM col'), 9007199254740993);
    },
  );

  test(
    'existing note update can be undone and redone with cards and tags',
    () async {
      final result = await storage.updateExistingNote(
        _note(fields: ['new front', 'back'], tags: ['old', 'new-tag']),
      );
      final generatedCard = result.addedCards.single;

      expect(storage.existingNoteUpdateUndoStatus.canUndo, isTrue);
      expect(storage.existingNoteUpdateUndoStatus.canRedo, isFalse);
      expect(storage.existingNoteUpdateUndoStatus.lastStep, 1);
      await storage.undoLastExistingNoteUpdate();

      final undone = await storage.getNote(Int64(42));
      expect(undone!.fields, ['front', 'back']);
      expect(undone.tags, ['old']);
      expect(undone.mtimeSecs, Int64(100));
      expect(await storage.getCard(generatedCard.id), isNull);
      expect(storage.tags.getTag('new-tag'), isNull);
      expect(await storage.queryInt('SELECT mod FROM col'), 500);
      expect(storage.existingNoteUpdateUndoStatus.canUndo, isFalse);
      expect(storage.existingNoteUpdateUndoStatus.canRedo, isTrue);
      expect(storage.existingNoteUpdateUndoStatus.lastStep, 2);

      await storage.redoLastExistingNoteUpdate();
      final redone = await storage.getNote(Int64(42));
      expect(redone!.fields, ['new front', 'back']);
      expect(redone.tags, ['new-tag', 'old']);
      expect(redone.mtimeSecs, Int64(9007199254740));
      expect(await storage.getCard(generatedCard.id), isNotNull);
      expect(storage.tags.getTag('new-tag'), isNotNull);
      expect(await storage.queryInt('SELECT mod FROM col'), 9007199254740993);
      expect(storage.existingNoteUpdateUndoStatus.canUndo, isTrue);
      expect(storage.existingNoteUpdateUndoStatus.canRedo, isFalse);
      expect(storage.existingNoteUpdateUndoStatus.lastStep, 3);
    },
  );

  test('no-op edit creates no undo history', () async {
    await storage.updateExistingNote(
      _note(fields: ['front', 'back'], tags: ['old']),
    );
    expect(storage.existingNoteUpdateUndoStatus.canUndo, isFalse);
    expect(storage.existingNoteUpdateUndoStatus.canRedo, isFalse);
    await expectLater(storage.undoLastExistingNoteUpdate(), throwsStateError);
  });

  test('rapid edits to the same note coalesce into one undo step', () async {
    database.execute('''
      INSERT INTO cards (
        id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps,
        lapses, left, odue, odid, flags, data
      ) VALUES (1, 42, 1, 0, 100, 0, 0, 0, 1, 0, 2500, 0, 0, 0, 0, 0, 0, '')
    ''');

    await storage.updateExistingNote(_note(fields: ['first edit', 'back']));
    nowMillis += 59_000;
    await storage.updateExistingNote(_note(fields: ['second edit', 'back']));

    expect(storage.existingNoteUpdateUndoStatus.lastStep, 2);
    await storage.undoLastExistingNoteUpdate();
    expect((await storage.getNote(Int64(42)))!.fields, ['front', 'back']);
    await storage.redoLastExistingNoteUpdate();
    expect((await storage.getNote(Int64(42)))!.fields, ['second edit', 'back']);
    expect(storage.existingNoteUpdateUndoStatus.lastStep, 4);
  });

  test('edits at the 60-second boundary remain separate undo steps', () async {
    database.execute('''
      INSERT INTO cards (
        id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps,
        lapses, left, odue, odid, flags, data
      ) VALUES (1, 42, 1, 0, 100, 0, 0, 0, 1, 0, 2500, 0, 0, 0, 0, 0, 0, '')
    ''');

    await storage.updateExistingNote(_note(fields: ['first edit', 'back']));
    nowMillis += 60_000;
    await storage.updateExistingNote(_note(fields: ['second edit', 'back']));

    await storage.undoLastExistingNoteUpdate();
    expect((await storage.getNote(Int64(42)))!.fields, ['first edit', 'back']);
    await storage.undoLastExistingNoteUpdate();
    expect((await storage.getNote(Int64(42)))!.fields, ['front', 'back']);
  });

  test('rapid edits with card or tag changes remain separate steps', () async {
    await storage.updateExistingNote(
      _note(fields: ['first edit', 'back'], tags: ['old', 'new-first']),
    );
    nowMillis += 1_000;
    await storage.updateExistingNote(
      _note(
        fields: ['second edit', 'back'],
        tags: ['old', 'new-first', 'new-second'],
      ),
    );

    await storage.undoLastExistingNoteUpdate();
    expect((await storage.getNote(Int64(42)))!.fields, ['first edit', 'back']);
    expect(storage.tags.getTag('new-first'), isNotNull);
    await storage.undoLastExistingNoteUpdate();
    expect((await storage.getNote(Int64(42)))!.fields, ['front', 'back']);
    expect(storage.tags.getTag('new-first'), isNull);
  });

  test(
    'coalescing window is checked after the second edit completes',
    () async {
      database.execute('''
      INSERT INTO cards (
        id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps,
        lapses, left, odue, odid, flags, data
      ) VALUES (1, 42, 1, 0, 100, 0, 0, 0, 1, 0, 2500, 0, 0, 0, 0, 0, 0, '')
    ''');
      await storage.updateExistingNote(_note(fields: ['first edit', 'back']));

      nowMillis += 59_000;
      nowMillisReads = 0;
      advanceClockAtCommit = true;
      await storage.updateExistingNote(_note(fields: ['second edit', 'back']));
      advanceClockAtCommit = false;

      await storage.undoLastExistingNoteUpdate();
      expect((await storage.getNote(Int64(42)))!.fields, [
        'first edit',
        'back',
      ]);
    },
  );

  test('a new edit after undo clears note-update redo history', () async {
    await storage.updateExistingNote(_note(fields: ['first', 'back']));
    await storage.undoLastExistingNoteUpdate();
    await storage.updateExistingNote(_note(fields: ['second', 'back']));
    expect(storage.existingNoteUpdateUndoStatus.canUndo, isTrue);
    expect(storage.existingNoteUpdateUndoStatus.canRedo, isFalse);
    await expectLater(storage.redoLastExistingNoteUpdate(), throwsStateError);
  });

  test(
    'changing notetype uses edited type and snapshots the original type',
    () async {
      await _saveNotetype(storage, _normalNotetype(id: Int64(10)));
      final edited = _note(
        notetypeId: Int64(10),
        fields: ['new front', 'back'],
        tags: ['old'],
      );

      final result = await storage.updateExistingNote(edited);
      final stored = await storage.getNote(Int64(42));

      expect(result.changed, isTrue);
      expect(stored!.notetypeId, Int64(10));
      expect(result.undoRecord!.oldNote.notetypeId, Int64(9));
      expect(result.addedCards.single.noteId, Int64(42));
    },
  );

  test(
    'normalizes note fields only when collection setting enables NFC',
    () async {
      const decomposed = 'e\u0301';
      final normalized = await storage.updateExistingNote(
        _note(fields: [decomposed, 'back']),
      );
      expect(normalized.note.fields.first, 'é');

      await storage.writeCollectionConfig('normalize_note_text', false);
      final raw = await storage.updateExistingNote(
        _note(fields: ['e\u0301!', 'back']),
      );
      expect(raw.note.fields.first, 'e\u0301!');
    },
  );

  test('normal template requirements add only newly required cards', () async {
    final optionalType = _normalNotetype(
      requirements: [
        proto.Notetype_Config_CardRequirement(
          cardOrd: 0,
          kind: proto.Notetype_Config_CardRequirement_Kind.KIND_ANY,
          fieldOrds: [0],
        ),
        proto.Notetype_Config_CardRequirement(
          cardOrd: 1,
          kind: proto.Notetype_Config_CardRequirement_Kind.KIND_ANY,
          fieldOrds: [1],
        ),
      ],
      templates: 2,
    );
    await _saveNotetype(storage, optionalType);
    await storage.removeNote(Int64(42));
    await _insertStoredNote(_note(fields: ['', 'back']));
    await storage.addOrUpdateCard(
      Card(
        id: Int64(88),
        noteId: Int64(42),
        deckId: Int64.ONE,
        templateIdx: 1,
        due: 12,
      ),
    );
    final result = await storage.updateExistingNote(
      _note(fields: ['front', 'back']),
    );

    expect(result.addedCards.map((card) => card.templateIdx), [0]);
  });

  test('normal card generation parses negated template conditionals', () async {
    final notetype = _normalNotetype(
      templates: 2,
      requirements: [
        proto.Notetype_Config_CardRequirement(
          cardOrd: 0,
          kind: proto.Notetype_Config_CardRequirement_Kind.KIND_ANY,
          fieldOrds: [0],
        ),
        proto.Notetype_Config_CardRequirement(
          cardOrd: 1,
          kind: proto.Notetype_Config_CardRequirement_Kind.KIND_ANY,
          fieldOrds: [1],
        ),
      ],
    );
    notetype.templates[1].config.qFormat = '{{^Front}}{{Back}}{{/Front}}';
    await _saveNotetype(storage, notetype);
    await storage.addOrUpdateCard(
      Card(id: Int64(77), noteId: Int64(42), deckId: Int64.ONE, templateIdx: 0),
    );

    final result = await storage.updateExistingNote(
      _note(fields: ['front', 'back'], tags: ['old']),
    );

    expect(result.addedCards, isEmpty);
  });

  test(
    'random new-card insertion follows pinned due-position sequence',
    () async {
      final inner = DeckConfig.defaults().inner.deepCopy()
        ..newCardInsertOrder = config_proto
            .DeckConfig_Config_NewCardInsertOrder
            .NEW_CARD_INSERT_ORDER_RANDOM;
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        DeckConfig(id: Int64.ONE, inner: inner),
      );
      await storage.writeCollectionConfig('nextPos', 5);
      final beforeConfig = database.select(
        'SELECT usn, mtime_secs, val FROM config WHERE key = ?',
        ['nextPos'],
      ).single;

      final result = await storage.updateExistingNote(
        _note(fields: ['new front', 'back'], tags: ['old']),
      );
      final afterConfig = database.select(
        'SELECT usn, mtime_secs, val FROM config WHERE key = ?',
        ['nextPos'],
      ).single;

      expect(result.addedCards.single.due, 180);
      expect(storage.readCollectionConfig('nextPos'), 6);
      await storage.undoLastExistingNoteUpdate();
      expect(storage.readCollectionConfig('nextPos'), 5);
      final undoneConfig = database.select(
        'SELECT usn, mtime_secs, val FROM config WHERE key = ?',
        ['nextPos'],
      ).single;
      expect(undoneConfig['usn'], beforeConfig['usn']);
      expect(undoneConfig['mtime_secs'], beforeConfig['mtime_secs']);
      expect(
        List<int>.from(undoneConfig['val'] as List<int>),
        List<int>.from(beforeConfig['val'] as List<int>),
      );

      await storage.redoLastExistingNoteUpdate();
      expect(storage.readCollectionConfig('nextPos'), 6);
      final redoneConfig = database.select(
        'SELECT usn, mtime_secs, val FROM config WHERE key = ?',
        ['nextPos'],
      ).single;
      expect(redoneConfig['usn'], afterConfig['usn']);
      expect(redoneConfig['mtime_secs'], afterConfig['mtime_secs']);
      expect(
        List<int>.from(redoneConfig['val'] as List<int>),
        List<int>.from(afterConfig['val'] as List<int>),
      );
    },
  );

  test(
    'template target deck overrides note deck and selects its due policy',
    () async {
      final randomInner = DeckConfig.defaults().inner.deepCopy()
        ..newCardInsertOrder = config_proto
            .DeckConfig_Config_NewCardInsertOrder
            .NEW_CARD_INSERT_ORDER_RANDOM;
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        DeckConfig(id: Int64.ONE, inner: randomInner),
      );
      database.execute('INSERT INTO decks VALUES (2, ?, 0, 0, ?, ?)', [
        'Target',
        deck_proto.Deck_Common().writeToBuffer(),
        deck_proto.Deck_KindContainer(
          normal: deck_proto.Deck_Normal(configId: Int64(2)),
        ).writeToBuffer(),
      ]);
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        DeckConfig(id: Int64(2), inner: DeckConfig.defaults().inner),
      );
      await _saveNotetype(
        storage,
        _normalNotetype(templateTargetDeckId: Int64(2)),
      );
      await storage.writeCollectionConfig('nextPos', 5);

      final result = await storage.updateExistingNote(
        _note(fields: ['new front', 'back'], tags: ['old']),
      );

      expect(result.addedCards.single.deckId, Int64(2));
      expect(result.addedCards.single.due, 5);
      expect(storage.readCollectionConfig('nextPos'), 6);
    },
  );

  test('undo and redo restore whether nextPos config existed', () async {
    database.execute('DELETE FROM config WHERE key = ?', ['nextPos']);
    expect(storage.readCollectionConfig('nextPos'), isNull);

    await storage.updateExistingNote(_note(fields: ['new front', 'back']));
    expect(storage.readCollectionConfig('nextPos'), 1);

    await storage.undoLastExistingNoteUpdate();
    expect(storage.readCollectionConfig('nextPos'), isNull);
    expect(
      await storage.queryInt(
        "SELECT count(*) FROM config WHERE key = 'nextPos'",
      ),
      0,
    );

    await storage.redoLastExistingNoteUpdate();
    expect(storage.readCollectionConfig('nextPos'), 1);
  });

  test('missing template target deck falls back to Default', () async {
    await _saveNotetype(
      storage,
      _normalNotetype(templateTargetDeckId: Int64(999)),
    );

    final result = await storage.updateExistingNote(
      _note(fields: ['new front', 'back'], tags: ['old']),
    );

    expect(result.addedCards.single.deckId, Int64.ONE);
  });

  test(
    'cloze update adds missing ordinals and leaves existing cards intact',
    () async {
      final cloze = _normalNotetype(cloze: true);
      await _saveNotetype(storage, cloze);
      final existing = Card(
        id: Int64(77),
        noteId: Int64(42),
        deckId: Int64.ONE,
        templateIdx: 0,
        mtimeSecs: Int64(50),
        usn: 8,
        due: 12,
      );
      await storage.addOrUpdateCard(existing);
      await storage.updateExistingNote(
        _note(fields: ['{{c1::one}} {{c2::two}}', 'back']),
      );

      expect(await storage.getCard(Int64(77)), isNotNull);
      final cards = await storage.allCardsOfNote(Int64(42));
      expect(cards.map((card) => card.templateIdx), [0, 1]);
      expect(cards.first.due, 12);
    },
  );

  test(
    'new-card position reuses original due for suspended or filtered cards',
    () async {
      final randomInner = DeckConfig.defaults().inner.deepCopy()
        ..newCardInsertOrder = config_proto
            .DeckConfig_Config_NewCardInsertOrder
            .NEW_CARD_INSERT_ORDER_RANDOM;
      storage.deckConfigs.addOrUpdateDeckConfigWithExistingId(
        DeckConfig(id: Int64.ONE, inner: randomInner),
      );
      await _saveNotetype(storage, _normalNotetype(cloze: true));
      await storage.addOrUpdateCard(
        Card(
          id: Int64(77),
          noteId: Int64(42),
          deckId: Int64.ONE,
          templateIdx: 0,
          ctype: CardType.newCard,
          queue: CardQueue.suspended,
          due: -5,
          originalDue: 22,
        ),
      );

      final result = await storage.updateExistingNote(
        _note(fields: ['{{c1::one}} {{c2::two}}', 'back'], tags: ['old']),
      );

      expect(result.addedCards.single.due, 22);
      expect(storage.readCollectionConfig('nextPos'), 1);
    },
  );

  test('cloze generation extracts nested comma-separated ordinals', () async {
    await _saveNotetype(storage, _normalNotetype(cloze: true));
    final result = await storage.updateExistingNote(
      _note(fields: ['{{c1,3::outer {{c2::inner}}}}', 'back'], tags: ['old']),
    );

    expect(clozeNumbersInFields(['{{c1,3::outer {{c2::inner}}}}']), {1, 2, 3});
    expect(clozeNumbersInFields(['{{c0::zero}}']), isEmpty);
    expect(result.addedCards.map((card) => card.templateIdx), [0, 1, 2]);
  });

  test('cloze generation ignores a template target deck', () async {
    database.execute('INSERT INTO decks VALUES (2, ?, 0, 0, ?, ?)', [
      'Target',
      deck_proto.Deck_Common().writeToBuffer(),
      deck_proto.Deck_KindContainer(
        normal: deck_proto.Deck_Normal(configId: Int64.ONE),
      ).writeToBuffer(),
    ]);
    await _saveNotetype(
      storage,
      _normalNotetype(cloze: true, templateTargetDeckId: Int64(2)),
    );

    final result = await storage.updateExistingNote(
      _note(fields: ['{{c1::one}}', 'back'], tags: ['old']),
    );

    expect(result.addedCards.single.deckId, Int64.ONE);
  });

  test('unclosed outer cloze does not create an inner ordinal card', () async {
    await _saveNotetype(storage, _normalNotetype(cloze: true));
    await storage.addOrUpdateCard(
      Card(id: Int64(77), noteId: Int64(42), deckId: Int64.ONE, templateIdx: 0),
    );

    final result = await storage.updateExistingNote(
      _note(fields: ['{{c12::outer {{c1::inner}}', 'back'], tags: ['old']),
    );

    expect(clozeNumbersInFields(['{{c12::outer {{c1::inner}}']), isEmpty);
    expect(result.addedCards, isEmpty);
  });

  test('unclosed c0 outer cloze does not expose an inner ordinal', () async {
    await _saveNotetype(storage, _normalNotetype(cloze: true));
    await storage.addOrUpdateCard(
      Card(id: Int64(77), noteId: Int64(42), deckId: Int64.ONE, templateIdx: 0),
    );

    final result = await storage.updateExistingNote(
      _note(fields: ['{{c0::outer {{c1::inner}}', 'back'], tags: ['old']),
    );

    expect(clozeNumbersInFields(['{{c0::outer {{c1::inner}}']), isEmpty);
    expect(result.addedCards, isEmpty);
  });

  test('c0 clozes do not add a cloze ordinal card already present', () async {
    await _saveNotetype(storage, _normalNotetype(cloze: true));
    await storage.addOrUpdateCard(
      Card(id: Int64(77), noteId: Int64(42), deckId: Int64.ONE, templateIdx: 0),
    );
    final result = await storage.updateExistingNote(
      _note(fields: ['{{c0::zero}}', 'back'], tags: ['old']),
    );

    expect(result.addedCards, isEmpty);
  });

  test(
    'tag canonicalization normalizes, sorts, deduplicates and preserves parent case',
    () async {
      database.execute('INSERT INTO tags VALUES (?, -1, 1)', ['Café']);
      final result = await storage.updateExistingNote(
        _note(
          fields: ['changed', 'back'],
          tags: ['cafe\u0301::child OTHER', 'café::CHILD', '\u0001'],
        ),
      );

      expect(result.note.tags, ['blank', 'Café::child', 'OTHER']);
      expect(result.undoRecord!.addedTags, ['Café::child', 'OTHER', 'blank']);
      expect(await storage.tags.preferredTagCase('café::child'), 'Café::child');
    },
  );

  test(
    'new card ids retain 64-bit values beyond JavaScript safe integer',
    () async {
      await storage.updateExistingNote(
        _note(fields: ['front', 'back'], tags: ['old']),
      );
      final result = await storage.updateExistingNote(
        _note(fields: ['updated', 'back']),
      );
      expect(result.addedCards.single.id.toString(), '9007199254740993');
    },
  );

  test('generated card failure rolls back note and tag writes', () async {
    await _saveNotetype(
      storage,
      _normalNotetype(
        requirements: [
          proto.Notetype_Config_CardRequirement(
            cardOrd: 0,
            kind: proto.Notetype_Config_CardRequirement_Kind.KIND_ANY,
            fieldOrds: [0],
          ),
        ],
      ),
    );
    await storage.executeBatch('''
      CREATE TRIGGER reject_generated_card BEFORE INSERT ON cards
      BEGIN SELECT RAISE(ABORT, 'blocked'); END;
    ''');

    await expectLater(
      storage.updateExistingNote(
        _note(fields: ['changed', 'back'], tags: ['new-tag']),
      ),
      throwsA(isA<SqliteException>()),
    );
    expect((await storage.getNote(Int64(42)))!.fields, ['front', 'back']);
    expect(
      await storage.queryInt("SELECT count(*) FROM tags WHERE tag = 'new-tag'"),
      0,
    );
  });

  test('an untracked collection mutation clears note-update history', () async {
    await storage.updateExistingNote(_note(fields: ['edited', 'back']));
    expect(storage.existingNoteUpdateUndoStatus.canUndo, isTrue);

    await storage.writeCollectionConfig('untracked-change', true);

    expect(storage.existingNoteUpdateUndoStatus.canUndo, isFalse);
    expect(storage.existingNoteUpdateUndoStatus.canRedo, isFalse);
  });

  test(
    'direct substore writes invalidate operation history automatically',
    () async {
      await storage.updateExistingNote(_note(fields: ['edited', 'back']));
      await storage.runUndoableCollectionOperation(
        apply: () async {},
        undo: () async {},
        redo: () async {},
      );
      expect(storage.canUndoCollectionOperation, isTrue);

      storage.tags.registerTag(Tag(name: 'direct', usn: -1, expanded: false));

      expect(storage.existingNoteUpdateUndoStatus.canUndo, isFalse);
      expect(storage.existingNoteUpdateUndoStatus.canRedo, isFalse);
      expect(storage.canUndoCollectionOperation, isFalse);
    },
  );

  test(
    'interleaved writes wait until a failing bulk operation rolls back',
    () async {
      final operationStarted = Completer<void>();
      final continueOperation = Completer<void>();
      final operation = storage.runUndoableCollectionOperation(
        apply: () async {
          database.execute('UPDATE col SET mod = 700');
          operationStarted.complete();
          await continueOperation.future;
          throw StateError('bulk operation failed');
        },
        undo: () async => database.execute('UPDATE col SET mod = 500'),
        redo: () async => database.execute('UPDATE col SET mod = 800'),
      );
      await operationStarted.future;

      final externalWrite = storage.writeCollectionConfig(
        'interleaved-write',
        true,
      );
      continueOperation.complete();
      await expectLater(operation, throwsA(isA<StateError>()));
      await externalWrite;

      expect(await storage.readCollectionConfig('interleaved-write'), isTrue);
      expect(storage.canUndoCollectionOperation, isFalse);
    },
  );

  test(
    'collection undo preparation is protected from external writes',
    () async {
      final preparationStarted = Completer<void>();
      final continuePreparation = Completer<void>();
      Object? preparedValue;
      final operation = storage.runUndoableCollectionOperation(
        prepare: () async {
          preparedValue = storage.readCollectionConfig('prepare-race');
          preparationStarted.complete();
          await continuePreparation.future;
          return true;
        },
        apply: () async => database.execute('UPDATE col SET mod = 700'),
        undo: () async => database.execute('UPDATE col SET mod = 500'),
        redo: () async => database.execute('UPDATE col SET mod = 700'),
      );
      await preparationStarted.future;

      final externalWrite = storage.writeCollectionConfig('prepare-race', true);
      continuePreparation.complete();
      expect(await operation, isTrue);
      await externalWrite;

      expect(preparedValue, isNull);
      expect(await storage.readCollectionConfig('prepare-race'), isTrue);
      expect(storage.canUndoCollectionOperation, isFalse);
    },
  );

  test(
    'undo waits for an in-flight bulk operation before choosing its step',
    () async {
      await storage.runUndoableCollectionOperation(
        apply: () async => database.execute('UPDATE col SET mod = 100'),
        undo: () async => database.execute('UPDATE col SET mod = 0'),
        redo: () async => database.execute('UPDATE col SET mod = 100'),
      );
      final operationStarted = Completer<void>();
      final continueOperation = Completer<void>();
      final operation = storage.runUndoableCollectionOperation(
        apply: () async {
          operationStarted.complete();
          await continueOperation.future;
          database.execute('UPDATE col SET mod = 200');
        },
        undo: () async => database.execute('UPDATE col SET mod = 100'),
        redo: () async => database.execute('UPDATE col SET mod = 200'),
      );
      await operationStarted.future;

      final undo = storage.undoLastCollectionOperation();
      continueOperation.complete();
      expect(await operation, isTrue);
      await undo;

      expect(await storage.queryInt('SELECT mod FROM col'), 100);
      expect(storage.canUndoCollectionOperation, isTrue);
    },
  );

  test(
    'public transaction controls cannot interrupt bulk operations',
    () async {
      final operationStarted = Completer<void>();
      final continueOperation = Completer<void>();
      final operation = storage.runUndoableCollectionOperation(
        apply: () async {
          operationStarted.complete();
          await continueOperation.future;
          database.execute('UPDATE col SET mod = 700');
        },
        undo: () async => database.execute('UPDATE col SET mod = 500'),
        redo: () async => database.execute('UPDATE col SET mod = 700'),
      );
      await operationStarted.future;

      await expectLater(storage.commit(), throwsA(isA<StateError>()));
      await expectLater(storage.rollback(), throwsA(isA<StateError>()));
      continueOperation.complete();

      expect(await operation, isTrue);
      expect(await storage.queryInt('SELECT mod FROM col'), 700);
    },
  );

  test('revlog substore writes invalidate collection operation undo', () async {
    database.execute('''
      CREATE TABLE revlog (
        id INTEGER PRIMARY KEY, cid INTEGER, usn INTEGER, ease INTEGER,
        ivl INTEGER, lastIvl INTEGER, factor INTEGER, time INTEGER, type INTEGER
      )
    ''');
    await storage.runUndoableCollectionOperation(
      apply: () async {},
      undo: () async {},
      redo: () async {},
    );
    expect(storage.canUndoCollectionOperation, isTrue);

    storage.revlog.addRevlogEntry(
      RevlogEntry(id: RevlogId(Int64(123)), cardId: Int64(42)),
    );

    expect(storage.canUndoCollectionOperation, isFalse);
  });

  test('public note updates invalidate collection operation undo', () async {
    await storage.runUndoableCollectionOperation(
      apply: () async {},
      undo: () async {},
      redo: () async {},
    );
    expect(storage.canUndoCollectionOperation, isTrue);
    final note = (await storage.getNote(Int64(42)))!;
    note.fieldsMut()[0] = 'external update';
    final notetype = (await storage.getNotetypesByIds([
      NotetypeId(note.notetypeId),
    ])).single;
    note.prepareForUpdate(notetype, normalizeText: false);

    await storage.updateNote(note);

    expect(storage.canUndoCollectionOperation, isFalse);
  });

  test('public undo helpers invalidate stale collection history', () async {
    database.execute(
      'CREATE TABLE graves (usn INTEGER, oid INTEGER, type INTEGER)',
    );

    Future<void> addUndoStep() async {
      await storage.runUndoableCollectionOperation(
        apply: () async {},
        undo: () async {},
        redo: () async {},
      );
    }

    await addUndoStep();
    storage.addDeletionGrave(Int64(55), note: false);
    expect(storage.canUndoCollectionOperation, isFalse);

    await addUndoStep();
    storage.removeDeletionGrave(Int64(55), note: false);
    expect(storage.canUndoCollectionOperation, isFalse);

    await addUndoStep();
    storage.restoreCollectionModifiedAt(Int64(99));
    expect(storage.canUndoCollectionOperation, isFalse);
  });

  test('bulk operation supersedes existing note edit undo history', () async {
    await storage.updateExistingNote(_note(fields: ['edited', 'back']));
    expect(storage.existingNoteUpdateUndoStatus.canUndo, isTrue);

    await storage.runUndoableCollectionOperation(
      apply: () async => database.execute('UPDATE col SET mod = 700'),
      undo: () async => database.execute('UPDATE col SET mod = 500'),
      redo: () async => database.execute('UPDATE col SET mod = 700'),
    );

    expect(storage.existingNoteUpdateUndoStatus.canUndo, isFalse);
    expect(storage.canUndoCollectionOperation, isTrue);
  });

  test('post-commit flush failure retains the committed undo step', () async {
    flushHook = () async => throw StateError('injected flush failure');

    await expectLater(
      storage.runUndoableCollectionOperation(
        apply: () async => database.execute('UPDATE col SET mod = 700'),
        undo: () async => database.execute('UPDATE col SET mod = 500'),
        redo: () async => database.execute('UPDATE col SET mod = 700'),
      ),
      throwsA(isA<StateError>()),
    );
    flushHook = null;

    expect(await storage.queryInt('SELECT mod FROM col'), 700);
    expect(storage.canUndoCollectionOperation, isTrue);
    await storage.undoLastCollectionOperation();
    expect(await storage.queryInt('SELECT mod FROM col'), 500);
  });

  test(
    'executeBatch invalidates note-update history before direct SQL writes',
    () async {
      await storage.updateExistingNote(_note(fields: ['edited', 'back']));
      expect(storage.existingNoteUpdateUndoStatus.canUndo, isTrue);

      await storage.executeBatch(
        "UPDATE notes SET flds = 'external edit' WHERE id = 42",
      );

      expect(storage.existingNoteUpdateUndoStatus.canUndo, isFalse);
      expect((await storage.getNote(Int64(42)))!.fields, ['external edit']);
    },
  );

  test(
    'adapter mutation during update flush prevents stale undo history',
    () async {
      final firstFlushStarted = Completer<void>();
      final releaseFirstFlush = Completer<void>();
      var flushCount = 0;
      flushHook = () async {
        flushCount++;
        if (flushCount == 1) {
          firstFlushStarted.complete();
          await releaseFirstFlush.future;
        }
      };

      final update = storage.updateExistingNote(
        _note(fields: ['note update', 'back']),
      );
      await firstFlushStarted.future;
      final concurrent = _note(fields: ['concurrent change', 'back'])
        ..prepareForUpdate(_normalNotetype(), normalizeText: true);
      await storage.updateNote(concurrent);
      releaseFirstFlush.complete();
      await update;

      expect((await storage.getNote(Int64(42)))!.fields, [
        'concurrent change',
        'back',
      ]);
      expect(storage.existingNoteUpdateUndoStatus.canUndo, isFalse);
    },
  );

  test(
    'failed undo rolls back SQLite rows and consumes the popped undo entry',
    () async {
      final result = await storage.updateExistingNote(
        _note(fields: ['edited', 'back'], tags: ['old', 'new-tag']),
      );
      database.execute('''
      CREATE TRIGGER reject_card_delete BEFORE DELETE ON cards
      BEGIN SELECT RAISE(ABORT, 'blocked'); END
    ''');

      await expectLater(
        storage.undoLastExistingNoteUpdate(),
        throwsA(anything),
      );

      expect(storage.existingNoteUpdateUndoStatus.canUndo, isFalse);
      expect(storage.existingNoteUpdateUndoStatus.canRedo, isFalse);
      expect((await storage.getNote(Int64(42)))!.fields, ['edited', 'back']);
      expect(await storage.getCard(result.addedCards.single.id), isNotNull);
      expect(storage.tags.getTag('new-tag'), isNotNull);
      expect(await storage.queryInt('SELECT mod FROM col'), 9007199254740993);

      expect(storage.existingNoteUpdateUndoStatus.canRedo, isFalse);
      await expectLater(storage.undoLastExistingNoteUpdate(), throwsStateError);
    },
  );

  test('failed edit clears older undo and redo entries', () async {
    await storage.updateExistingNote(_note(fields: ['first edit', 'back']));
    await storage.undoLastExistingNoteUpdate();
    expect(storage.existingNoteUpdateUndoStatus.canRedo, isTrue);
    database.execute('''
      CREATE TRIGGER reject_note_update BEFORE UPDATE ON notes
      BEGIN SELECT RAISE(ABORT, 'blocked'); END
    ''');

    await expectLater(
      storage.updateExistingNote(_note(fields: ['second edit', 'back'])),
      throwsA(anything),
    );

    expect(storage.existingNoteUpdateUndoStatus.canUndo, isFalse);
    expect(storage.existingNoteUpdateUndoStatus.canRedo, isFalse);
    expect((await storage.getNote(Int64(42)))!.fields, ['front', 'back']);
  });

  test(
    'note-update undo history retains only the newest 30 operations',
    () async {
      for (var index = 0; index < 31; index++) {
        if (index > 0) nowMillis += 60_000;
        await storage.updateExistingNote(
          _note(fields: ['edit $index', 'back']),
        );
      }

      expect(storage.existingNoteUpdateUndoStatus.lastStep, 31);
      for (var index = 0; index < 30; index++) {
        await storage.undoLastExistingNoteUpdate();
      }
      expect(storage.existingNoteUpdateUndoStatus.canUndo, isFalse);
      expect(storage.existingNoteUpdateUndoStatus.canRedo, isTrue);
      expect((await storage.getNote(Int64(42)))!.fields.first, 'edit 0');
    },
  );

  test(
    'card update is serialized before a later undoable operation snapshots it',
    () async {
      final original = Card.newCard(
        noteId: Int64(42),
        templateIdx: 0,
        deckId: Int64.ONE,
        due: 1,
      );
      final cardId = await storage.addCard(original);
      final stored = (await storage.getCard(cardId))!;
      final externalUpdate = Card.fromProto(
        stored.toProto()..queue = CardQueue.suspended.value,
      );
      final update = storage.updateCard(externalUpdate);
      late Card beforeBulk;
      final bulk = storage.runUndoableCollectionOperation(
        prepare: () async {
          beforeBulk = (await storage.getCard(cardId))!;
          return true;
        },
        apply: () async {
          await storage.updateCard(
            Card.fromProto(
              beforeBulk.toProto()..queue = CardQueue.userBuried.value,
            ),
          );
        },
        undo: () async => storage.addOrUpdateCard(beforeBulk),
        redo: () async => storage.addOrUpdateCard(
          Card.fromProto(
            beforeBulk.toProto()..queue = CardQueue.userBuried.value,
          ),
        ),
      );

      await update;
      expect(await bulk, isTrue);
      await storage.undoLastCollectionOperation();
      expect((await storage.getCard(cardId))!.queue, CardQueue.suspended);
    },
  );

  test(
    'deck collapse waits until an undoable collection operation finishes',
    () async {
      final operationStarted = Completer<void>();
      final continueOperation = Completer<void>();
      final operation = storage.runUndoableCollectionOperation(
        apply: () async {
          operationStarted.complete();
          await continueOperation.future;
        },
        undo: () async {},
        redo: () async {},
      );
      await operationStarted.future;

      final collapse = storage.setDeckCollapsed(Int64.ONE, collapsed: false);
      continueOperation.complete();
      await operation;
      await collapse;

      expect(storage.decks.getDeck(Int64.ONE)!.common.studyCollapsed, isFalse);
    },
  );

  test(
    'bulk mutation started during note update waits until its database writes finish',
    () async {
      late Future<bool> bulkOperation;
      onNowMillis = () {
        onNowMillis = null;
        bulkOperation = storage.runUndoableCollectionOperation(
          apply: () async {
            final note = (await storage.getNote(Int64(42)))!
              ..setField(0, 'bulk change');
            note.prepareForUpdate(_normalNotetype(), normalizeText: true);
            await storage.updateNote(note);
          },
          undo: () async {},
          redo: () async {},
        );
      };

      await storage.updateExistingNote(_note(fields: ['note update', 'back']));
      expect(await bulkOperation, isTrue);
      expect((await storage.getNote(Int64(42)))!.fields, [
        'bulk change',
        'back',
      ]);
    },
  );

  test(
    'concurrent note updates do not roll back another successful update',
    () async {
      await _saveNotetype(storage, _normalNotetype());
      await _insertStoredNote(_note(id: Int64(43)));
      await storage.executeBatch('''
      CREATE TRIGGER reject_first_note_card BEFORE INSERT ON cards
      WHEN NEW.nid = 42
      BEGIN SELECT RAISE(ABORT, 'blocked first note'); END;
    ''');

      final results = await Future.wait<Object?>([
        storage
            .updateExistingNote(
              _note(fields: ['failed', 'back'], tags: ['one']),
            )
            .then<Object?>(
              (result) => result,
              onError: (Object error) => error,
            ),
        storage
            .updateExistingNote(
              _note(
                id: Int64(43),
                fields: ['succeeded', 'back'],
                tags: ['two'],
              ),
            )
            .then<Object?>(
              (result) => result,
              onError: (Object error) => error,
            ),
      ]);

      expect(results.first, isA<SqliteException>());
      expect(results.last, isA<ExistingNoteUpdateResult>());
      expect((await storage.getNote(Int64(42)))!.fields, ['front', 'back']);
      expect((await storage.getNote(Int64(43)))!.fields, ['succeeded', 'back']);
      expect(await storage.allCardsOfNote(Int64(43)), hasLength(1));
    },
  );
}

Future<void> _saveNotetype(
  CollectionSqliteStorage storage,
  Notetype notetype,
) async {
  final database = _databaseFor(storage);
  database.execute('INSERT OR REPLACE INTO notetypes VALUES (?, ?, 0, 0, ?)', [
    notetype.id.value.toInt(),
    notetype.name,
    notetype.config.writeToBuffer(),
  ]);
  database.execute('DELETE FROM fields WHERE ntid = ?', [
    notetype.id.value.toInt(),
  ]);
  database.execute('DELETE FROM templates WHERE ntid = ?', [
    notetype.id.value.toInt(),
  ]);
  for (var index = 0; index < notetype.fields.length; index++) {
    database.execute('INSERT INTO fields VALUES (?, ?, ?, ?)', [
      notetype.id.value.toInt(),
      index,
      notetype.fields[index].name,
      notetype.fields[index].config.writeToBuffer(),
    ]);
  }
  for (var index = 0; index < notetype.templates.length; index++) {
    database.execute('INSERT INTO templates VALUES (?, ?, ?, 0, 0, ?)', [
      notetype.id.value.toInt(),
      index,
      notetype.templates[index].name,
      notetype.templates[index].config.writeToBuffer(),
    ]);
  }
}

Database _databaseFor(CollectionSqliteStorage storage) =>
    // The test keeps the in-memory handle to inspect precise transactional
    // writes; this helper is assigned by setUp before any test executes.
    _activeDatabase!;

Database? _activeDatabase;

Future<void> _saveDefaultDeck() async {
  _activeDatabase!.execute('INSERT INTO decks VALUES (1, ?, 0, 0, ?, ?)', [
    'Default',
    deck_proto.Deck_Common().writeToBuffer(),
    deck_proto.Deck_KindContainer(
      normal: deck_proto.Deck_Normal(configId: Int64.ONE),
    ).writeToBuffer(),
  ]);
  _activeDatabase!.execute('INSERT INTO deck_config VALUES (1, ?, 0, 0, ?)', [
    'Default',
    DeckConfig.defaults().toProto().config.writeToBuffer(),
  ]);
}

Future<void> _insertStoredNote(Note note) async {
  final prepared =
      Note(
        id: note.id,
        guid: note.guid,
        notetypeId: note.notetypeId,
        mtimeSecs: note.mtimeSecs,
        usn: note.usn,
        fields: note.fields,
        tags: note.tags,
      )..prepareForUpdate(
        _normalNotetype(id: note.notetypeId),
        normalizeText: true,
      );
  _activeDatabase!.execute(
    '''
    INSERT OR REPLACE INTO notes
      (id, guid, mid, mod, usn, tags, flds, sfld, csum)
    VALUES (?, ?, ?, 100, 0, ?, ?, ?, ?)
  ''',
    [
      note.id.toInt(),
      prepared.guid,
      note.notetypeId.toInt(),
      prepared.tags.isEmpty ? '' : ' ${prepared.tags.join(' ')} ',
      prepared.fields.join('\x1f'),
      prepared.sortField,
      prepared.checksum,
    ],
  );
}

Note _note({
  Int64? id,
  Int64? notetypeId,
  List<String> fields = const ['front', 'back'],
  List<String> tags = const [],
}) {
  final noteId = id ?? Int64(42);
  final note = Note(
    id: noteId,
    guid: 'guid-$noteId',
    notetypeId: notetypeId ?? Int64(9),
    mtimeSecs: Int64(200),
    usn: 0,
    tags: tags,
    fields: fields,
  );
  return note;
}

Notetype _normalNotetype({
  Int64? id,
  bool cloze = false,
  int templates = 1,
  Int64? templateTargetDeckId,
  List<proto.Notetype_Config_CardRequirement>? requirements,
}) {
  final notetype = Notetype(
    id: NotetypeId(id ?? Int64(9)),
    name: 'Basic',
    fields: [
      NoteField(ord: 0, name: 'Front', config: proto.Notetype_Field_Config()),
      NoteField(ord: 1, name: 'Back', config: proto.Notetype_Field_Config()),
    ],
    templates: [
      for (var index = 0; index < templates; index++)
        CardTemplate(
          ord: index,
          name: 'Card ${index + 1}',
          config: proto.Notetype_Template_Config(
            qFormat: index == 0 ? '{{Front}}' : '{{Back}}',
            aFormat: '{{Back}}',
            targetDeckId: templateTargetDeckId ?? Int64.ZERO,
          ),
        ),
    ],
    config: proto.Notetype_Config(
      kind: cloze
          ? proto.Notetype_Config_Kind.KIND_CLOZE
          : proto.Notetype_Config_Kind.KIND_NORMAL,
      reqs:
          requirements ??
          [
            proto.Notetype_Config_CardRequirement(
              cardOrd: 0,
              kind: proto.Notetype_Config_CardRequirement_Kind.KIND_ANY,
              fieldOrds: [0],
            ),
          ],
    ),
  );
  return notetype;
}
