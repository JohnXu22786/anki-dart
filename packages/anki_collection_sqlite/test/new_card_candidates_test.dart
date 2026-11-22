// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_collection_sqlite/src/fnvhash.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late CollectionSqliteStorage storage;

  setUp(() async {
    storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => sqlite3.openInMemory(),
      ),
      location: ':memory:',
    );
    await storage.executeBatch('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER,
        mod INTEGER, usn INTEGER, type INTEGER, queue INTEGER, due INTEGER,
        ivl REAL, factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER,
        odue INTEGER, odid INTEGER, flags INTEGER, data TEXT
      );
    ''');
  });

  tearDown(() async => storage.close());

  test('restricts candidates to the exact deck and new queue', () async {
    await _insertCards(storage, [
      _card(id: 1, noteId: 10, deckId: 7, queue: 0),
      _card(id: 2, noteId: 11, deckId: 7, queue: 1),
      _card(id: 3, noteId: 12, deckId: 8, queue: 0),
    ]);

    final result = await storage.newCardCandidates(
      deckId: Int64(7),
      sorting: NewCardCandidateSorting.lowestPosition,
    );

    expect(result.map((candidate) => candidate.id), [Int64(1)]);
  });

  test('uses both positional orders and ordinal tie order', () async {
    await _insertCards(storage, [
      _card(id: 1, noteId: 10, deckId: 7, due: 2, ordinal: 2),
      _card(id: 2, noteId: 10, deckId: 7, due: 2, ordinal: 0),
      _card(id: 3, noteId: 11, deckId: 7, due: 1, ordinal: 3),
    ]);

    final lowest = await storage.newCardCandidates(
      deckId: Int64(7),
      sorting: NewCardCandidateSorting.lowestPosition,
    );
    final highest = await storage.newCardCandidates(
      deckId: Int64(7),
      sorting: NewCardCandidateSorting.highestPosition,
    );

    expect(lowest.map((candidate) => candidate.id), [
      Int64(3),
      Int64(2),
      Int64(1),
    ]);
    expect(highest.map((candidate) => candidate.id), [
      Int64(2),
      Int64(1),
      Int64(3),
    ]);
  });

  test(
    'random note and card modes use exact FNV salts and signed 64-bit ids',
    () async {
      final cardIds = [
        BigInt.parse('9007199254740993'),
        BigInt.parse('9223372036854775807'),
        BigInt.parse('-9223372036854775808'),
      ];
      final noteIds = [
        BigInt.parse('9007199254740995'),
        BigInt.parse('9223372036854775806'),
        BigInt.parse('-9223372036854775807'),
      ];
      await _insertCards(storage, [
        for (var index = 0; index < cardIds.length; index++)
          _card(
            id: cardIds[index],
            noteId: noteIds[index],
            deckId: 7,
            due: index,
            ordinal: 0,
          ),
      ]);
      const salt = 0x7fffffff;

      final randomCards = await storage.newCardCandidates(
        deckId: Int64(7),
        sorting: NewCardCandidateSorting.randomCards,
        salt: salt,
      );
      final randomNotes = await storage.newCardCandidates(
        deckId: Int64(7),
        sorting: NewCardCandidateSorting.randomNotes,
        salt: salt,
      );
      final expectedCards = List<BigInt>.of(cardIds)
        ..sort(
          (a, b) => fnvHashSqlArguments([
            a,
            BigInt.from(salt),
          ]).compareTo(fnvHashSqlArguments([b, BigInt.from(salt)])),
        );
      final expectedNotes = List<int>.generate(noteIds.length, (index) => index)
        ..sort((a, b) {
          final hashOrder = fnvHashSqlArguments([
            noteIds[a],
            BigInt.from(salt),
          ]).compareTo(fnvHashSqlArguments([noteIds[b], BigInt.from(salt)]));
          return hashOrder != 0 ? hashOrder : a.compareTo(b);
        });
      expect(
        randomCards.map((candidate) => candidate.id.toString()),
        expectedCards.map((id) => id.toString()),
      );
      expect(
        randomNotes.map((candidate) => candidate.id.toString()),
        expectedNotes.map((index) => cardIds[index].toString()),
      );
      expect(
        randomCards.map((candidate) => candidate.id.toString()).toSet(),
        cardIds.map((id) => id.toString()).toSet(),
      );
    },
  );

  test('projects exactly the Core candidate fields', () async {
    await _insertCards(storage, [
      _card(
        id: BigInt.parse('9007199254740993'),
        noteId: BigInt.parse('9007199254740995'),
        deckId: 7,
        ordinal: 4,
        mtime: BigInt.parse('9007199254740997'),
        originalDeckId: BigInt.parse('9223372036854775807'),
      ),
    ]);

    final candidate = (await storage.newCardCandidates(
      deckId: Int64(7),
      sorting: NewCardCandidateSorting.lowestPosition,
    )).single;

    expect(candidate.id.toString(), '9007199254740993');
    expect(candidate.noteId.toString(), '9007199254740995');
    expect(candidate.templateOrdinal, 4);
    expect(candidate.mtimeSecs.toString(), '9007199254740997');
    expect(candidate.currentDeckId, Int64(7));
    expect(candidate.originalDeckId.toString(), '9223372036854775807');
  });

  test('returns no candidates for an empty deck', () async {
    expect(
      await storage.newCardCandidates(
        deckId: Int64(999),
        sorting: NewCardCandidateSorting.lowestPosition,
      ),
      isEmpty,
    );
  });

  test(
    'requires salt only for random modes and validates u32 ordinal',
    () async {
      await expectLater(
        storage.newCardCandidates(
          deckId: Int64(7),
          sorting: NewCardCandidateSorting.randomCards,
        ),
        throwsArgumentError,
      );
      await expectLater(
        storage.newCardCandidates(
          deckId: Int64(7),
          sorting: NewCardCandidateSorting.lowestPosition,
          salt: 1,
        ),
        throwsArgumentError,
      );

      await _insertCards(storage, [
        _card(id: 1, noteId: 1, deckId: 7, ordinal: 0x100000000),
      ]);
      await expectLater(
        storage.newCardCandidates(
          deckId: Int64(7),
          sorting: NewCardCandidateSorting.lowestPosition,
        ),
        throwsFormatException,
      );
    },
  );
}

Map<String, Object?> _card({
  required Object id,
  required Object noteId,
  required Object deckId,
  int ordinal = 0,
  int queue = 0,
  int due = 0,
  Object mtime = 1,
  Object originalDeckId = 0,
}) => {
  'id': id,
  'nid': noteId,
  'did': deckId,
  'ord': ordinal,
  'mod': mtime,
  'usn': 0,
  'type': 0,
  'queue': queue,
  'due': due,
  'ivl': 0,
  'factor': 0,
  'reps': 0,
  'lapses': 0,
  'left': 0,
  'odue': 0,
  'odid': originalDeckId,
  'flags': 0,
  'data': "'{}'",
};

Future<void> _insertCards(
  CollectionSqliteStorage storage,
  List<Map<String, Object?>> cards,
) async {
  for (final card in cards) {
    final values = card.values
        .map(
          (value) => switch (value) {
            BigInt integer => integer.toString(),
            _ => value.toString(),
          },
        )
        .join(', ');
    await storage.executeBatch('INSERT INTO cards VALUES ($values)');
  }
}
