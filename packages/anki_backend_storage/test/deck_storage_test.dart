// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:ffi';
import 'dart:io';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as proto;
import 'package:anki_backend_storage/anki_backend_storage.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/open.dart';
import 'package:test/test.dart';

void main() {
  late Database database;
  late DeckStorage storage;

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  setUp(() {
    database = sqlite3.openInMemory();
    database.execute('''
CREATE TABLE decks (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  mtime_secs INTEGER NOT NULL,
  usn INTEGER NOT NULL,
  common BLOB NOT NULL,
  kind BLOB NOT NULL
)''');
    storage = DeckStorage(_DeckDb(database), nowMillis: () => 1000);
  });

  tearDown(() => database.dispose());

  test('normal and filtered decks round-trip protobuf columns', () {
    final normal = storage.addDeck(_normalDeck('parent :: child'));
    expect(normal.name, 'parent::child');
    final filtered = Deck(
      id: Int64(20),
      name: 'Filtered',
      mtimeSecs: Int64(111),
      usn: 5,
      common: proto.Deck_Common(millisecondsStudied: 456),
      kind: FilteredDeckKind(
        proto.Deck_Filtered(searchTerms: [
          proto.Deck_Filtered_SearchTerm(search: 'deck:Filtered'),
        ]),
      ),
    );
    storage.addOrUpdateDeckWithExistingId(filtered);

    final decodedNormal = storage.getDeck(normal.id)!;
    expect(decodedNormal.name, 'parent::child');
    expect(decodedNormal.toProto().normal.configId, Int64(7));
    expect(decodedNormal.common.studyCollapsed, isTrue);
    expect(storage.getDeckByName('parent\x1fchild')!.id, normal.id);
    expect(storage.getDeckId('parent\x1fchild'), normal.id);

    final decodedFiltered = storage.getDeck(Int64(20))!;
    expect(decodedFiltered.name, 'Filtered');
    expect(decodedFiltered.toProto().filtered.searchTerms.single.search,
        'deck:Filtered');
    expect(decodedFiltered.common.millisecondsStudied, 456);
    expect(
      storage.getAllDeckNames(),
      [(Int64(20), 'Filtered'), (Int64(1000), 'parent::child')],
    );
  });

  test('ID allocation uses current milliseconds and then max plus one', () {
    final first = storage.addDeck(_normalDeck('First'));
    expect(first.id, Int64(1000));

    final next = storage.addDeck(_normalDeck('Second'));
    expect(next.id, Int64(1001));
  });

  test('upsert keeps the supplied ID and update requires an existing row', () {
    final deck = _normalDeck('Before', id: Int64(11));
    storage.addOrUpdateDeckWithExistingId(deck);
    final replacement = _normalDeck(
      'After',
      id: Int64(11),
      mtimeSecs: Int64(22),
    );
    storage.addOrUpdateDeckWithExistingId(replacement);
    expect(storage.getDeck(Int64(11))!.name, 'After');

    storage.updateDeck(_normalDeck('Updated', id: Int64(11)));
    expect(storage.getDeck(Int64(11))!.name, 'Updated');
    expect(
      () => storage.updateDeck(_normalDeck('Missing', id: Int64(12))),
      throwsStateError,
    );
  });

  test('signed large IDs survive reads, writes, and deletion', () {
    final id = Int64.parseInt('9007199254740993');
    final deck = _normalDeck('Large', id: id);
    storage.addOrUpdateDeckWithExistingId(deck);
    expect(storage.getDeck(id)!.id, id);
    storage.removeDeck(id);
    expect(storage.getDeck(id), isNull);
    storage.removeDeck(id);
  });

  test('invalid stored kind reports the source deck ID', () {
    database.execute(
      'INSERT INTO decks VALUES (?, ?, ?, ?, ?, ?)',
      [
        33,
        'Bad',
        0,
        0,
        proto.Deck_Common().writeToBuffer(),
        <int>[],
      ],
    );
    expect(
      () => storage.getDeck(Int64(33)),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'invalid deck kind: 33',
        ),
      ),
    );
  });
}

Deck _normalDeck(
  String name, {
  Int64 id = Int64.ZERO,
  Int64 mtimeSecs = Int64.ZERO,
}) =>
    Deck(
      id: id,
      name: name,
      mtimeSecs: mtimeSecs,
      usn: -3,
      common: proto.Deck_Common(studyCollapsed: true, browserCollapsed: true),
      kind: NormalDeckKind(proto.Deck_Normal(configId: Int64(7))),
    );

final class _DeckDb implements DeckStorageDatabase {
  _DeckDb(this.database);

  final Database database;

  @override
  List<Map<String, Object?>> select(String sql,
      [List<Object?> parameters = const []]) {
    final rows = database.select(sql, parameters);
    final names = rows.columnNames;
    return rows
        .map(
          (row) => {
            for (var index = 0; index < names.length; index++)
              names[index]: row.columnAt(index),
          },
        )
        .toList(growable: false);
  }

  @override
  int execute(String sql, [List<Object?> parameters = const []]) {
    database.execute(sql, parameters);
    return database.updatedRows;
  }
}
