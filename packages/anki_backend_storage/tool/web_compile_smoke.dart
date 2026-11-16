// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_storage/anki_backend_storage.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  final db = _Database();
  final storage = NoteStorage(db);
  final note = Note(
    id: Int64.parseInt('9007199254740993'),
    guid: 'web-smoke',
    notetypeId: Int64(1),
    fields: ['front'],
  );
  note.prepareForUpdate(_notetype(), normalizeText: false);
  storage.addOrUpdateNote(note);
  if (db.parameters.first != note.id) {
    throw StateError('note ID lost 64-bit precision on the web target');
  }

  final added = Note(
    guid: 'generated-web-smoke',
    notetypeId: Int64(1),
    fields: ['front'],
  )..prepareForUpdate(_notetype(), normalizeText: false);
  storage.addNote(added);
  if (added.id != db.lastInsertRowId) {
    throw StateError('generated row ID was not retained');
  }

  final deckDb = _DeckDatabase();
  final deckStorage = DeckStorage(deckDb, nowMillis: () => 1);
  final deck = Deck.newNormal();
  final storedDeck = deckStorage.addDeck(deck);
  if (storedDeck.id != Int64.parseInt('9007199254740993') ||
      deckDb.parameters.first != BigInt.parse('9007199254740993')) {
    throw StateError('deck ID lost 64-bit precision on the web target');
  }
  final hierarchyIds = deckStorage.deckIdWithChildren(storedDeck);
  if (deckDb.queryParameters.first != BigInt.parse('9007199254740993') ||
      hierarchyIds.last != Int64.parseInt('9007199254740994')) {
    throw StateError('deck hierarchy IDs lost 64-bit precision on the web');
  }
  if (deckStorage.missingDeckIds().single !=
      Int64.parseInt('9007199254740995')) {
    throw StateError('missing deck ID lost 64-bit precision on the web');
  }

  final configDb = _DeckConfigDatabase();
  final configStorage = DeckConfigStorage(configDb);
  final configId = Int64.parseInt('9007199254740993');
  configStorage.addOrUpdateDeckConfigWithExistingId(
    DeckConfig(
      id: configId,
      name: 'web config',
      inner: DeckConfig.defaults().inner,
    ),
  );
  if (configDb.parameters.first != BigInt.parse('9007199254740993')) {
    throw StateError('deck config ID lost 64-bit precision on the web');
  }

  final tagDb = _TagDatabase();
  final tagStorage = TagStorage(tagDb);
  tagStorage.registerTag(Tag(name: 'Web', usn: -1, expanded: true));
  if (tagDb.parameters.length != 3 ||
      tagDb.parameters[0] != 'Web' ||
      tagDb.parameters[1] != -1 ||
      tagDb.parameters[2] != false ||
      tagStorage.tagsPendingSync(-1).single != 'Web') {
    throw StateError('tag storage changed Core row or pending-sync behavior');
  }
}

Notetype _notetype() =>
    Notetype(id: NotetypeId(Int64(1)), config: Notetype.defaultConfig());

class _Database implements NoteStorageDatabase {
  List<Object?> parameters = [];

  @override
  Int64 lastInsertRowId = Int64.parseInt('9007199254740995');

  @override
  NoteStorageStatement prepareCached(String sql) => _Statement(this);
}

class _Statement implements NoteStorageStatement {
  _Statement(this.db);

  final _Database db;

  @override
  int execute(List<Object?> parameters) {
    db.parameters = parameters;
    return 1;
  }
}

final class _DeckDatabase implements DeckStorageDatabase {
  List<Object?> parameters = [];
  List<Object?> queryParameters = [];

  @override
  List<Map<String, Object?>> select(
    String sql, [
    List<Object?> parameters = const [],
  ]) {
    queryParameters = parameters;
    if (sql.startsWith('SELECT id FROM decks WHERE id = ? OR')) {
      return [
        {'id': BigInt.parse('9007199254740993')},
        {'id': BigInt.parse('9007199254740994')},
      ];
    }
    if (sql.startsWith('SELECT DISTINCT did')) {
      return [
        {'did': BigInt.parse('9007199254740995')},
      ];
    }
    return [
      {'id': BigInt.parse('9007199254740993')},
    ];
  }

  @override
  int execute(String sql, [List<Object?> parameters = const []]) {
    this.parameters = parameters;
    return 1;
  }
}

final class _DeckConfigDatabase implements DeckConfigStorageDatabase {
  List<Object?> parameters = [];

  @override
  List<Map<String, Object?>> select(String sql,
          [List<Object?> parameters = const []]) =>
      const [];

  @override
  int execute(String sql, [List<Object?> parameters = const []]) {
    this.parameters = parameters;
    return 1;
  }
}

final class _TagDatabase implements TagStorageDatabase {
  List<Object?> parameters = [];

  @override
  List<Map<String, Object?>> select(
    String sql, [
    List<Object?> parameters = const [],
  ]) =>
      [
        {'tag': 'Web'},
      ];

  @override
  int execute(String sql, [List<Object?> parameters = const []]) {
    this.parameters = parameters;
    return 1;
  }
}
