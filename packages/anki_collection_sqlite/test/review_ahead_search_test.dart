// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as deckProto;
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Review Ahead availability respects exact deck and due-day boundary',
    () async {
      final database = sqlite3.openInMemory();
      const nowMillis = 1700000000000;
      final today = (nowMillis ~/ 1000) ~/ 86400;
      final storage = await CollectionSqliteStorage.open(
        driver: CollectionSqliteDriver(openDatabase: (_) => database),
        location: ':memory:',
        nowMillis: () => nowMillis,
      );
      try {
        await storage.executeBatch('''
        CREATE TABLE config (
          key TEXT PRIMARY KEY, usn INTEGER, mtime_secs INTEGER, val BLOB
        );
        CREATE TABLE decks (
          id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER,
          common BLOB, kind BLOB
        );
        CREATE TABLE cards (
          id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER,
          mod INTEGER, usn INTEGER, type INTEGER, queue INTEGER, due INTEGER,
          ivl REAL, factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER,
          odue INTEGER, odid INTEGER, flags INTEGER, data TEXT
        );
      ''');
        storage.decks.addOrUpdateDeckWithExistingId(
          Deck(
            id: Int64(11),
            name: 'Target',
            kind: NormalDeckKind(deckProto.Deck_Normal()),
          ),
        );
        storage.decks.addOrUpdateDeckWithExistingId(
          Deck(
            id: Int64(12),
            name: 'Other',
            kind: NormalDeckKind(deckProto.Deck_Normal()),
          ),
        );
        await storage.addCard(
          Card(
            id: Int64(21),
            noteId: Int64(31),
            deckId: Int64(11),
            ctype: CardType.review,
            queue: CardQueue.review,
            due: today + 4,
          ),
        );
        await storage.addCard(
          Card(
            id: Int64(22),
            noteId: Int64(32),
            deckId: Int64(12),
            ctype: CardType.review,
            queue: CardQueue.review,
            due: today + 1,
          ),
        );

        await storage.addCard(
          Card(
            id: Int64(24),
            noteId: Int64(34),
            deckId: Int64(11),
            ctype: CardType.review,
            queue: CardQueue.suspended,
            due: today + 1,
          ),
        );
        await storage.addCard(
          Card(
            id: Int64(25),
            noteId: Int64(35),
            deckId: Int64(11),
            ctype: CardType.review,
            queue: CardQueue.schedBuried,
            due: today + 1,
          ),
        );
        await storage.addCard(
          Card(
            id: Int64(26),
            noteId: Int64(36),
            deckId: Int64(13),
            originalDeckId: Int64(11),
            ctype: CardType.review,
            queue: CardQueue.review,
            due: today + 1,
          ),
        );

        expect(
          await storage.hasCardsMatchingSearch(
            'deck:Target prop:due<=3 -is:suspended -is:buried -deck:filtered',
          ),
          isFalse,
        );
        await storage.addCard(
          Card(
            id: Int64(23),
            noteId: Int64(33),
            deckId: Int64(11),
            ctype: CardType.review,
            queue: CardQueue.review,
            due: today + 3,
          ),
        );
        expect(
          await storage.hasCardsMatchingSearch(
            'deck:Target prop:due<=3 -is:suspended -is:buried -deck:filtered',
          ),
          isTrue,
        );
      } finally {
        await storage.close();
      }
    },
  );
}
