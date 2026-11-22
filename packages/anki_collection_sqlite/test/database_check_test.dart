// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as protoDeck;
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CollectionSqliteStorage storage;
  var failSecondCheckFlush = false;
  var checkFlushCount = 0;

  setUp(() async {
    failSecondCheckFlush = false;
    checkFlushCount = 0;
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => sqlite3.openInMemory(),
        flush: () {
          if (failSecondCheckFlush && ++checkFlushCount == 2) {
            throw StateError('flush failed after database check commit');
          }
        },
      ),
      location: ':memory:',
      nowMillis: () => 1000000000000,
    );
    await storage.executeBatch('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY, guid TEXT NOT NULL, mid INTEGER NOT NULL,
        mod INTEGER NOT NULL, usn INTEGER NOT NULL, tags TEXT NOT NULL,
        flds TEXT NOT NULL, sfld TEXT NOT NULL, csum INTEGER NOT NULL
      );
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY, nid INTEGER NOT NULL, did INTEGER NOT NULL,
        ord INTEGER NOT NULL, mod INTEGER NOT NULL, usn INTEGER NOT NULL,
        type INTEGER NOT NULL, queue INTEGER NOT NULL, due INTEGER NOT NULL,
        ivl INTEGER NOT NULL, factor INTEGER NOT NULL, reps INTEGER NOT NULL,
        lapses INTEGER NOT NULL, left INTEGER NOT NULL, odue INTEGER NOT NULL,
        odid INTEGER NOT NULL, flags INTEGER NOT NULL, data TEXT NOT NULL
      );
      CREATE TABLE revlog (
        id INTEGER PRIMARY KEY, cid INTEGER NOT NULL, usn INTEGER NOT NULL,
        ease INTEGER NOT NULL, ivl INTEGER NOT NULL, lastIvl INTEGER NOT NULL,
        factor INTEGER NOT NULL, time INTEGER NOT NULL, type INTEGER NOT NULL
      );
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY, name TEXT NOT NULL, mtime_secs INTEGER NOT NULL,
        usn INTEGER NOT NULL, common BLOB NOT NULL, kind BLOB NOT NULL
      );
      CREATE TABLE deck_config (
        id INTEGER PRIMARY KEY, name TEXT NOT NULL COLLATE unicase,
        mtime_secs INTEGER NOT NULL, usn INTEGER NOT NULL, config BLOB NOT NULL
      );
      CREATE TABLE config (
        key TEXT PRIMARY KEY, usn INTEGER NOT NULL, mtime_secs INTEGER NOT NULL,
        val BLOB NOT NULL
      );
      CREATE TABLE col (crt INTEGER NOT NULL, conf TEXT NOT NULL, scm INTEGER NOT NULL);
      INSERT INTO col VALUES (0, '{}', 0);
      CREATE TABLE notetypes (
        id INTEGER PRIMARY KEY, name TEXT NOT NULL, mtime_secs INTEGER NOT NULL,
        usn INTEGER NOT NULL, config BLOB NOT NULL
      );
      CREATE TABLE fields (
        ntid INTEGER NOT NULL, ord INTEGER NOT NULL, name TEXT NOT NULL,
        config BLOB NOT NULL
      );
      CREATE TABLE templates (
        ntid INTEGER NOT NULL, ord INTEGER NOT NULL, name TEXT NOT NULL,
        mtime_secs INTEGER NOT NULL, usn INTEGER NOT NULL, config BLOB NOT NULL
      );
      CREATE TABLE tags (
        tag TEXT COLLATE unicase PRIMARY KEY, usn INTEGER NOT NULL,
        collapsed INTEGER NOT NULL
      );
      INSERT INTO notetypes VALUES (999, 'Basic', 0, 0, x'');
      INSERT INTO fields VALUES (999, 0, 'Front', x'');
      INSERT INTO templates VALUES (999, 0, 'Card 1', 0, 0, x'');
      INSERT INTO notes VALUES (1, 'a', 999, 0, 0, '', 'one', 'one', 1);
      INSERT INTO notes VALUES (9007199254740995, 'b', 999, 0, 0, '', 'two', 'two', 2);
      INSERT INTO cards VALUES (10, 1, 1, 0, 0, 0, 0, 0, 1, 0, 2500, 0, 0, 0, 0, 0, 0, '{}');
      INSERT INTO cards VALUES (11, 999, 1, 0, 0, 0, 0, 0, 2, 0, 2500, 0, 0, 0, 0, 0, 0, '{}');
      INSERT INTO cards VALUES (9007199254740993, 9007199254740995, 1, 0, 0, 0, 0, 0, 3, 0, 2500, 0, 0, 0, 0, 0, 0, '{}');
    ''');
    await storage.addInitialDeck('Default');
    await storage.addInitialDeckConfig('Default');
  });

  tearDown(() async => storage.close());

  test(
    'repairs orphan cards in Core stage order and reports completion',
    () async {
      final progress = <DatabaseCheckProgress>[];
      final result = await storage.checkDatabase(onProgress: progress.add);

      expect(result.orphanedCardsRemoved, 1);
      expect(result.invalidIdsFixed, 2);
      expect(result.isComplete, isTrue);
      expect(await storage.queryInt('SELECT count(*) FROM cards'), 2);
      expect(
        await storage.queryInt('''
        SELECT count(*) FROM cards c JOIN notes n ON n.id = c.nid
      '''),
        2,
      );
      expect(
        await storage.queryInt(
          'SELECT count(*) FROM cards WHERE id > 9007199254740995',
        ),
        0,
      );
      final stageTransitions = <DatabaseCheckStage>[];
      for (final event in progress) {
        if (stageTransitions.isEmpty || stageTransitions.last != event.stage) {
          stageTransitions.add(event.stage);
        }
      }
      expect(stageTransitions, [
        DatabaseCheckStage.integrity,
        DatabaseCheckStage.optimize,
        DatabaseCheckStage.cards,
        DatabaseCheckStage.notes,
        DatabaseCheckStage.history,
      ]);
      expect(progress[3].current, 0);
      expect(progress[3].total, 2);
    },
  );

  test(
    'cancellation rolls back repairs and does not return a result',
    () async {
      final progress = <DatabaseCheckProgress>[];
      var cancelled = false;

      await expectLater(
        storage.checkDatabase(
          onProgress: (event) {
            progress.add(event);
            if (event.stage == DatabaseCheckStage.notes) cancelled = true;
          },
          isCancelled: () => cancelled,
        ),
        throwsA(isA<DatabaseCheckCancelled>()),
      );

      expect(await storage.queryInt('SELECT count(*) FROM cards'), 3);
      expect(progress.last.stage, DatabaseCheckStage.notes);
    },
  );

  test(
    'cancellation during history repairs rolls back revlog normalization',
    () async {
      await storage.executeBatch('''
      INSERT INTO revlog VALUES (3000000, 10, 0, 3, 2147483648, 0, 2500, 1000, 1);
    ''');
      var inHistory = false;
      var historyChecks = 0;

      await expectLater(
        storage.checkDatabase(
          onProgress: (event) {
            if (event.stage == DatabaseCheckStage.history) inHistory = true;
          },
          isCancelled: () => inHistory && historyChecks++ >= 1,
        ),
        throwsA(isA<DatabaseCheckCancelled>()),
      );

      expect(await storage.queryInt('SELECT ivl FROM revlog'), 2147483648);
      expect(await storage.queryInt('SELECT count(*) FROM cards'), 3);
    },
  );

  test(
    'serializes collection mutations until a cancelled check rolls back',
    () async {
      var cancelled = false;
      late Future<void> mutation;

      await expectLater(
        storage.checkDatabase(
          onProgress: (event) {
            if (event.stage == DatabaseCheckStage.history) {
              mutation = storage.executeBatch(
                "UPDATE col SET conf = 'concurrent mutation'",
              );
              cancelled = true;
            }
          },
          isCancelled: () => cancelled,
        ),
        throwsA(isA<DatabaseCheckCancelled>()),
      );

      await mutation;
      expect(
        await storage.queryString('SELECT conf FROM col'),
        'concurrent mutation',
      );
    },
  );

  test(
    'post-commit flush failure still invalidates operation history',
    () async {
      await storage.executeBatch('UPDATE cards SET ivl = -1 WHERE id = 10');
      await storage.runUndoableCollectionOperation(
        apply: () async {
          await storage.executeBatch(
            "UPDATE col SET conf = '{\"undoable\":true}'",
          );
        },
        undo: () async {
          await storage.executeBatch("UPDATE col SET conf = '{}'");
        },
        redo: () async {
          await storage.executeBatch(
            "UPDATE col SET conf = '{\"undoable\":true}'",
          );
        },
      );
      expect(storage.canUndoCollectionOperation, isTrue);
      failSecondCheckFlush = true;

      await expectLater(
        storage.checkDatabase(onProgress: (_) {}),
        throwsA(isA<StateError>()),
      );

      expect(await storage.queryInt('SELECT ivl FROM cards WHERE id = 10'), 0);
      expect(storage.canUndoCollectionOperation, isFalse);
    },
  );

  test('repair errors roll back and do not return a result', () async {
    await storage.executeBatch('''
      CREATE TRIGGER reject_orphan_delete
      BEFORE DELETE ON cards
      WHEN OLD.nid = 999
      BEGIN
        SELECT RAISE(ABORT, 'repair rejected');
      END;
    ''');

    await expectLater(
      storage.checkDatabase(onProgress: (_) {}),
      throwsA(anything),
    );
    expect(await storage.queryInt('SELECT count(*) FROM cards'), 3);
  });

  test('removes duplicate card ordinals and reports the removed row', () async {
    await storage.executeBatch('''
      INSERT INTO cards VALUES (12, 1, 1, 0, 0, 0, 0, 0, 1, 0, 2500, 0, 0, 0, 0, 0, 0, '{}');
    ''');

    final result = await storage.checkDatabase(onProgress: (_) {});

    expect(result.duplicateCardOrdinalsRemoved, 1);
    expect(
      await storage.queryInt('SELECT count(*) FROM cards WHERE nid = 1'),
      1,
    );
  });

  test('removes cards whose ordinal has no normal template', () async {
    await storage.executeBatch('''
      UPDATE cards SET ord = 5 WHERE id = 10;
    ''');

    final result = await storage.checkDatabase(onProgress: (_) {});

    expect(result.cardsWithoutTemplateRemoved, 1);
    expect(result.missingCardsRegenerated, 1);
    expect(
      await storage.queryInt('SELECT count(*) FROM cards WHERE id = 10'),
      0,
    );
    expect(
      await storage.queryInt('SELECT count(*) FROM cards WHERE nid = 1'),
      1,
    );
  });

  test(
    'recovers a missing notetype using existing notes and card ordinals',
    () async {
      await storage.executeBatch('''
        DELETE FROM templates WHERE ntid = 999;
        DELETE FROM fields WHERE ntid = 999;
        DELETE FROM notetypes WHERE id = 999;
      ''');

      final result = await storage.checkDatabase(onProgress: (_) {});
      final recovered = (await storage.getNotetypesByIds([
        NotetypeId(Int64(999)),
      ])).single;

      expect(result.notetypesRecovered, 1);
      expect(recovered.name, startsWith('db-check-'));
      expect(recovered.fields.length, 2);
      expect(recovered.templates.length, 1);
    },
  );

  test('creates a stock notetype when the collection has none', () async {
    await storage.executeBatch('''
      DELETE FROM cards;
      DELETE FROM notes;
      DELETE FROM templates;
      DELETE FROM fields;
      DELETE FROM notetypes;
    ''');

    final result = await storage.checkDatabase(onProgress: (_) {});

    expect(await storage.queryInt('SELECT count(*) FROM notetypes'), 1);
    expect(result.notetypesRecovered, 1);
    expect(await storage.queryInt('SELECT scm FROM col'), 1000000000000);
  });

  test('replaces invalid note field and tag UTF-8 without aborting', () async {
    await storage.executeBatch('''
      UPDATE notes
      SET flds = CAST(x'80' AS TEXT), tags = CAST(x'ff' AS TEXT)
      WHERE id = 1;
    ''');

    final result = await storage.checkDatabase(onProgress: (_) {});
    final note = (await storage.getNote(Int64.ONE))!;

    expect(result.invalidUtf8NotesFixed, 1);
    expect(note.fields.first, '\uFFFD');
    expect(note.tags, ['\uFFFD']);
  });

  test('rebuilds tags from notes and preserves expanded tag state', () async {
    await storage.executeBatch("UPDATE notes SET tags = 'alpha' WHERE id = 1");
    storage.tags.registerTag(Tag(name: 'alpha', expanded: true));
    storage.tags.registerTag(Tag(name: 'stale', expanded: false));

    final result = await storage.checkDatabase(onProgress: (_) {});

    expect(storage.tags.getTag('alpha')?.expanded, isTrue);
    expect(storage.tags.getTag('stale'), isNull);
    expect(result.tagRegistryChanged, isTrue);
  });

  test('marks note tag normalization as a collection change', () async {
    await storage.executeBatch("UPDATE notes SET tags = 'á' WHERE id = 1");
    storage.tags.registerTag(Tag(name: 'á', expanded: true));

    final result = await storage.checkDatabase(onProgress: (_) {});
    final note = (await storage.getNote(Int64.ONE))!;

    expect(result.noteTagsFixed, 1);
    expect(note.tags, ['á']);
    expect(await storage.queryInt('SELECT scm FROM col'), 1000000000000);
  });

  test(
    'repairs card values, missing decks, filtered state, and revlog rows',
    () async {
      await storage.executeBatch('''
      UPDATE cards
      SET did = 99, odid = 3, odue = 500, due = 2000001, ivl = -1, ord = 30001
      WHERE id = 10;
      INSERT INTO revlog VALUES (20, 10, 0, 0, 1.5, 3.4, 0, 0, 0);
    ''');

      final result = await storage.checkDatabase(onProgress: (_) {});
      final card = (await storage.allCardsOfNote(Int64.ONE)).single;

      expect(result.newCardPositionsFixed, 1);
      expect(result.invalidCardPropertiesFixed, 2);
      expect(result.missingDecksRecovered, 1);
      expect(result.filteredCardsFixed, 1);
      expect(result.cardsWithoutTemplateRemoved, 1);
      expect(result.missingCardsRegenerated, 1);
      expect(result.revlogRowsFixed, 1);
      expect(card.deckId, Int64.ONE);
      expect(card.interval, 0);
      expect(card.templateIdx, 0);
      expect(card.originalDeckId, Int64.ZERO);
      expect(card.originalDue, 0);
      expect(storage.decks.getDeck(Int64(99))?.name, 'recovered99');
      expect(await storage.queryInt('SELECT ivl FROM revlog WHERE id = 20'), 2);
      expect(
        await storage.queryInt('SELECT lastIvl FROM revlog WHERE id = 20'),
        3,
      );
      expect(
        await storage.queryInt('SELECT type FROM revlog WHERE id = 20'),
        5,
      );
    },
  );

  test(
    'repairs note field counts and future modification times with progress',
    () async {
      await storage.executeBatch('''
        UPDATE notetypes SET name = 'Recovered' WHERE id = 999;
        INSERT INTO fields VALUES (999, 1, 'Back', x'');
        UPDATE notes SET mod = 9999999999 WHERE id = 1;
      ''');
      final progress = <DatabaseCheckProgress>[];

      final result = await storage.checkDatabase(onProgress: progress.add);

      expect(result.notesVisited, 2);
      expect(result.noteFieldCountMismatches, 2);
      expect(result.futureNoteModificationTimesFixed, 1);
      expect(
        await storage.queryString('SELECT flds FROM notes WHERE id = 1'),
        'one\x1f',
      );
      expect(
        progress
            .where((event) => event.stage == DatabaseCheckStage.notes)
            .map((event) => (event.current, event.total)),
        [(0, 2), (1, 2), (2, 2)],
      );
    },
  );

  test(
    'restores missing last-review time from scheduled review history',
    () async {
      await storage.executeBatch('''
      UPDATE cards SET type = 2, queue = 2 WHERE id = 10;
      INSERT INTO revlog VALUES (
        3000000, 10, 0, 3, 2147483648, 0, 2500, 1000, 1
      );
    ''');

      final result = await storage.checkDatabase(onProgress: (_) {});
      final card = (await storage.getCard(Int64(10)))!;

      expect(result.cardLastReviewTimesFixed, 1);
      expect(card.lastReviewTimeSecs, Int64(3000));
      expect(await storage.queryInt('SELECT ivl FROM revlog'), 2147483647);
      expect(await storage.queryInt('SELECT scm FROM col'), 1000000000000);
    },
  );

  test(
    'marks the collection modified when next new-card position changes',
    () async {
      await storage.executeBatch('''
      DELETE FROM cards WHERE id = 11;
      INSERT INTO config VALUES ('nextPos', 0, 0, x'30');
    ''');

      final result = await storage.checkDatabase(onProgress: (_) {});

      expect(
        await storage.queryString(
          'SELECT CAST(val AS TEXT) FROM config WHERE key = \'nextPos\'',
        ),
        '4',
      );
      expect(await storage.queryInt('SELECT scm FROM col'), 1000000000000);
      expect(result.nextNewPositionFixed, isTrue);
    },
  );

  test(
    'missing deck parents do not replace existing nested deck rows',
    () async {
      final existing = storage.decks.addDeck(
        Deck(
          name: 'Parent::Existing',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      storage.decks.addDeck(
        Deck(
          name: 'Parent::Existing::Child',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64.ONE)),
        ),
      );

      final result = await storage.checkDatabase(onProgress: (_) {});

      expect(result.missingDeckNamesRecovered, 1);
      expect(
        storage.decks.getDeckByName('Parent\x1fExisting')?.id,
        existing.id,
      );
      expect(storage.decks.getDeckByName('Parent')?.name, 'Parent');
    },
  );

  test(
    'counts missing immediate parent while restoring all ancestors',
    () async {
      storage.decks.addDeck(
        Deck(
          name: 'A::B::Child',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64.ONE)),
        ),
      );

      final result = await storage.checkDatabase(onProgress: (_) {});

      expect(result.missingDeckNamesRecovered, 1);
      expect(storage.decks.getDeckByName('A')?.name, 'A');
      expect(storage.decks.getDeckByName('A\x1fB')?.name, 'A::B');
    },
  );

  test(
    'missing deck ID recovery keeps an existing recovered-name deck',
    () async {
      final existing = storage.decks.addDeck(
        Deck(
          name: 'recovered99',
          kind: NormalDeckKind(protoDeck.Deck_Normal(configId: Int64.ONE)),
        ),
      );
      await storage.executeBatch('UPDATE cards SET did = 99 WHERE id = 10');

      final result = await storage.checkDatabase(onProgress: (_) {});

      expect(result.missingDecksRecovered, 1);
      expect(storage.decks.getDeckByName('recovered99')?.id, existing.id);
      expect(storage.decks.getDeck(Int64(99))?.name, 'recovered99+');
    },
  );

  test('invalid ID repair avoids collisions at the validity cutoff', () async {
    const cutoff = 1000086400000;
    await storage.executeBatch('''
      INSERT INTO notes VALUES ($cutoff, 'valid-cutoff', 999, 0, 0, '', 'x', 'x', 1);
      INSERT INTO notes VALUES (${cutoff + 1}, 'invalid-next', 999, 0, 0, '', 'y', 'y', 2);
      INSERT INTO cards VALUES (20, $cutoff, 1, 0, 0, 0, 0, 0, 4, 0, 2500, 0, 0, 0, 0, 0, 0, '{}');
      INSERT INTO cards VALUES (21, ${cutoff + 1}, 1, 0, 0, 0, 0, 0, 5, 0, 2500, 0, 0, 0, 0, 0, 0, '{}');
    ''');

    final result = await storage.checkDatabase(onProgress: (_) {});

    expect(result.invalidIdsFixed, 3);
    expect(
      await storage.queryInt('SELECT count(*) FROM notes WHERE id > $cutoff'),
      0,
    );
    expect(
      await storage.queryInt(
        "SELECT count(*) FROM notes WHERE guid = 'valid-cutoff'",
      ),
      1,
    );
  });

  test('integrity failure stops before optimization and repair', () async {
    await storage.close();
    final progress = <DatabaseCheckProgress>[];

    await expectLater(
      storage.checkDatabase(onProgress: progress.add),
      throwsA(isA<CollectionIntegrityException>()),
    );
    expect(progress.map((event) => event.stage), [
      DatabaseCheckStage.integrity,
    ]);
  });
}
