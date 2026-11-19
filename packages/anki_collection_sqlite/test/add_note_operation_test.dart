// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CollectionSqliteStorage storage;
  late Database database;
  var nowMillis = 9007199254740993;

  setUp(() async {
    nowMillis = 9007199254740993;
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => database = sqlite3.openInMemory(),
      ),
      location: ':memory:',
      nowMillis: () => nowMillis,
    );
    database.execute('''
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
        key TEXT PRIMARY KEY, usn INTEGER, mtime_secs INTEGER, val BLOB
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
    database.execute('INSERT INTO col VALUES (500)');
    await _saveNotetype(database, _normalNotetype());
    await _saveNotetype(database, _normalNotetype(id: Int64(10), cloze: true));
    database.execute('INSERT INTO config VALUES (?, 0, 1, ?)', [
      'normalize_note_text',
      utf8.encode('true'),
    ]);
    database.execute('INSERT INTO config VALUES (?, 0, 1, ?)', [
      'nextPos',
      utf8.encode('1'),
    ]);
    _saveDeck(database, id: Int64.ONE, name: 'Default');
    _saveDeck(database, id: Int64(9007199254740995), name: 'Custom');
  });

  tearDown(() async => storage.close());

  test(
    'adds a prepared note, tags, normal cards, and config atomically',
    () async {
      const decomposed = 'e\u0301';
      final note = _newNote(
        fields: [decomposed, 'back'],
        tags: [' Topic ', 'topic'],
      );
      final result = await storage.addNoteToDeck(note, Int64(9007199254740995));

      expect(result.generatedCardCount, 2);
      expect(result.changes.note, isTrue);
      expect(result.changes.card, isTrue);
      expect(result.changes.tag, isTrue);
      expect(result.changes.config, isTrue);
      expect(result.changes.mtime, isTrue);
      expect(note.id, Int64(9007199254740993));
      expect(note.fields, ['é', 'back']);
      expect(note.tags, ['Topic']);
      expect(note.usn, -1);
      expect(note.mtimeSecs, Int64(9007199254740));
      expect(await storage.queryInt('SELECT COUNT(*) FROM cards'), 2);
      expect(await storage.allCardsOfNote(note.id), hasLength(2));
      expect(
        (await storage.allCardsOfNote(note.id)).map((card) => card.deckId),
        everyElement(Int64(9007199254740995)),
      );
      expect(
        (await storage.allCardsOfNote(
          note.id,
        )).map((card) => card.id.toString()).toSet(),
        {'9007199254740993', '9007199254740994'},
      );
      expect(
        (await storage.allCardsOfNote(note.id)).map((card) => card.templateIdx),
        [0, 1],
      );
      expect(storage.tags.getTag('topic')!.name, 'Topic');
      expect(_readConfig(database, '_nt_9_lastDeck'), 9007199254740995);
      expect(
        _readRawConfigValue(database, '_nt_9_lastDeck'),
        '9007199254740995',
      );
      expect(_readConfig(database, '_deck_9007199254740995_lastNotetype'), 9);
      expect(_readConfig(database, 'curModel'), 9);
      expect(_readConfig(database, 'nextPos'), 2);
      expect(await storage.queryInt('SELECT mod FROM col'), 9007199254740993);
    },
  );

  test(
    'uses the host-selected default deck for normal card generation',
    () async {
      final result = await storage.addNoteToDeck(_newNote(), Int64.ONE);
      final cards = await storage.allCardsOfNote(result.note.id);

      expect(result.generatedCardCount, 2);
      expect(cards.map((card) => card.deckId), everyElement(Int64.ONE));
      expect(cards.map((card) => card.due), [1, 1]);
      expect(_readConfig(database, 'nextPos'), 2);
    },
  );

  test(
    'generates cloze ordinals from the shared template and keeps count',
    () async {
      final note = _newNote(
        notetypeId: Int64(10),
        fields: ['{{c2::two}} {{c1::one}} {{c2::again}}', 'back'],
      );
      final result = await storage.addNoteToDeck(note, Int64.ONE);
      final cards = await storage.allCardsOfNote(note.id);

      expect(result.generatedCardCount, 2);
      expect(cards.map((card) => card.templateIdx), [0, 1]);
    },
  );

  test(
    'last-deck config preserves an ID above JavaScript safe integer',
    () async {
      final added = await storage.addNoteToDeck(
        _newNote(),
        Int64(9007199254740995),
      );
      database.execute('DELETE FROM cards WHERE nid = ?', [
        BigInt.parse(added.note.id.toString()),
      ]);
      final edited = Note(
        id: added.note.id,
        guid: added.note.guid,
        notetypeId: added.note.notetypeId,
        tags: added.note.tags,
        fields: ['changed front', 'back'],
      );

      await storage.updateExistingNote(edited);

      expect(
        (await storage.allCardsOfNote(
          added.note.id,
        )).map((card) => card.deckId),
        everyElement(Int64(9007199254740995)),
      );
    },
  );

  test('ensures a new note has one card when no template renders', () async {
    final result = await storage.addNoteToDeck(
      _newNote(fields: ['', '']),
      Int64.ONE,
    );

    expect(result.generatedCardCount, 1);
    expect(
      (await storage.allCardsOfNote(result.note.id)).single.templateIdx,
      0,
    );
  });

  test(
    'honors disabled normalization and ignores a missing selected deck',
    () async {
      await storage.writeCollectionConfig('normalize_note_text', false);
      final note = _newNote(fields: ['e\u0301', 'back']);
      final result = await storage.addNoteToDeck(note, Int64(123456));

      expect(note.fields.first, 'e\u0301');
      expect(result.generatedCardCount, 2);
      expect(
        (await storage.allCardsOfNote(note.id)).map((card) => card.deckId),
        everyElement(Int64.ONE),
      );
    },
  );

  test('rolls back note and tags when card insertion fails', () async {
    database.execute('''
      CREATE TRIGGER fail_add_card BEFORE INSERT ON cards
      BEGIN SELECT RAISE(ABORT, 'card insert failed'); END
    ''');
    final note = _newNote(tags: ['new-tag']);

    await expectLater(
      storage.addNoteToDeck(note, Int64.ONE),
      throwsA(isA<SqliteException>()),
    );
    expect(await storage.queryInt('SELECT count(*) FROM notes'), 0);
    expect(await storage.queryInt('SELECT count(*) FROM tags'), 0);
    expect(await storage.queryInt('SELECT count(*) FROM cards'), 0);
    expect(await storage.queryInt('SELECT mod FROM col'), 500);
    expect(note.id, Int64.ZERO);
  });

  test('rolls back inserted note and cards when config write fails', () async {
    database.execute('''
      CREATE TRIGGER fail_last_deck BEFORE INSERT ON config
      WHEN NEW.key = '_nt_9_lastDeck'
      BEGIN SELECT RAISE(ABORT, 'config write failed'); END
    ''');

    await expectLater(
      storage.addNoteToDeck(_newNote(), Int64.ONE),
      throwsA(isA<SqliteException>()),
    );
    expect(await storage.queryInt('SELECT count(*) FROM notes'), 0);
    expect(await storage.queryInt('SELECT count(*) FROM cards'), 0);
    expect(_readConfig(database, 'nextPos'), 1);
    expect(_readConfig(database, '_nt_9_lastDeck'), isNull);
    expect(await storage.queryInt('SELECT mod FROM col'), 500);
  });

  test('rolls back registered tags when note insertion fails', () async {
    database.execute('''
      CREATE TRIGGER fail_add_note BEFORE INSERT ON notes
      BEGIN SELECT RAISE(ABORT, 'note insert failed'); END
    ''');
    final note = _newNote(tags: ['new-tag']);

    await expectLater(
      storage.addNoteToDeck(note, Int64.ONE),
      throwsA(isA<SqliteException>()),
    );
    expect(await storage.queryInt('SELECT count(*) FROM notes'), 0);
    expect(await storage.queryInt('SELECT count(*) FROM tags'), 0);
    expect(await storage.queryInt('SELECT count(*) FROM cards'), 0);
    expect(note.id, Int64.ZERO);
  });

  test('fails and rolls back if the default deck is unavailable', () async {
    database.execute('DELETE FROM decks WHERE id = 1');
    final note = _newNote();

    await expectLater(
      storage.addNoteToDeck(note, Int64(123456)),
      throwsStateError,
    );
    expect(await storage.queryInt('SELECT count(*) FROM notes'), 0);
    expect(await storage.queryInt('SELECT count(*) FROM cards'), 0);
    expect(_readConfig(database, 'nextPos'), 1);
    expect(note.id, Int64.ZERO);
  });

  test('missing notetype fails without writing collection state', () async {
    final note = _newNote(notetypeId: Int64(987654321));

    await expectLater(storage.addNoteToDeck(note, Int64.ONE), throwsStateError);
    expect(await storage.queryInt('SELECT count(*) FROM notes'), 0);
    expect(await storage.queryInt('SELECT count(*) FROM tags'), 0);
    expect(await storage.queryInt('SELECT count(*) FROM cards'), 0);
    expect(await storage.queryInt('SELECT mod FROM col'), 500);
  });
}

Future<void> _saveNotetype(Database database, Notetype notetype) async {
  database.execute('INSERT OR REPLACE INTO notetypes VALUES (?, ?, 0, 0, ?)', [
    notetype.id.value.toInt(),
    notetype.name,
    notetype.config.writeToBuffer(),
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

void _saveDeck(Database database, {required Int64 id, required String name}) {
  database.execute('INSERT INTO decks VALUES (?, ?, 0, 0, ?, ?)', [
    BigInt.parse(id.toString()),
    name,
    deck_proto.Deck_Common().writeToBuffer(),
    deck_proto.Deck_KindContainer(
      normal: deck_proto.Deck_Normal(configId: Int64.ONE),
    ).writeToBuffer(),
  ]);
  if (database.select('SELECT 1 FROM deck_config WHERE id = 1').isEmpty) {
    database.execute('INSERT INTO deck_config VALUES (1, ?, 0, 0, ?)', [
      'Default',
      DeckConfig.defaults().toProto().config.writeToBuffer(),
    ]);
  }
}

Object? _readConfig(Database database, String key) {
  final rows = database.select('SELECT val FROM config WHERE key = ?', [key]);
  return rows.isEmpty
      ? null
      : jsonDecode(utf8.decode(rows.single['val'] as List<int>));
}

String? _readRawConfigValue(Database database, String key) {
  final rows = database.select('SELECT val FROM config WHERE key = ?', [key]);
  return rows.isEmpty ? null : utf8.decode(rows.single['val'] as List<int>);
}

Note _newNote({
  Int64? notetypeId,
  List<String> fields = const ['front', 'back'],
  List<String> tags = const [],
}) => Note(
  guid: 'new-note',
  notetypeId: notetypeId ?? Int64(9),
  fields: fields,
  tags: tags,
);

Notetype _normalNotetype({Int64? id, bool cloze = false, int templates = 2}) =>
    Notetype(
      id: NotetypeId(id ?? Int64(9)),
      name: cloze ? 'Cloze' : 'Basic',
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
            ),
          ),
      ],
      config: proto.Notetype_Config(
        kind: cloze
            ? proto.Notetype_Config_Kind.KIND_CLOZE
            : proto.Notetype_Config_Kind.KIND_NORMAL,
      ),
    );
