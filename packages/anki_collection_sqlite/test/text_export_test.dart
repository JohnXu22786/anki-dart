// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('empty text exports retain source metadata headers', () {
    final result = generateCollectionTextExport(
      cards: true,
      options: const CollectionTextExportOptions(includeHtml: false),
      notes: const [],
      cardRecords: const [],
    );
    expect(result.text, '#separator:tab\n#html:false\n');
    expect(result.count, 0);
  });

  test('note export orders optional columns, pads fields, and quotes TSV', () {
    final result = generateCollectionTextExport(
      cards: false,
      options: const CollectionTextExportOptions(
        includeHtml: true,
        includeGuid: true,
        includeNotetypeName: true,
        includeDeckName: true,
        includeTags: true,
      ),
      cardRecords: const [],
      fieldColumnCount: 3,
      notes: const [
        CollectionTextExportNote(
          guid: 'g',
          notetypeName: 'Basic',
          deckName: 'D',
          fields: ['one', 'two\t"quoted"\nline'],
          tags: ['a', 'b'],
        ),
        CollectionTextExportNote(
          guid: 'h',
          notetypeName: 'Basic',
          deckName: 'D',
          fields: ['three'],
          tags: [],
        ),
      ],
    );
    expect(
      result.text,
      '#separator:tab\n#html:true\n#guid column:1\n#notetype column:2\n#deck column:3\n#tags column:7\n'
      'g\tBasic\tD\tone\t"two\t""quoted""\nline"\t\ta b\n'
      'h\tBasic\tD\tthree\t\t\t\n',
    );
    expect(result.count, 2);
  });

  test('card records retain ascending exact 64-bit identities', () {
    final low = CollectionTextExportCard(
      id: Int64(2),
      question: 'q',
      answer: 'a',
    );
    final high = CollectionTextExportCard(
      id: Int64.parseInt('9007199254740993'),
      question: 'x',
      answer: 'y',
    );
    final result = generateCollectionTextExport(
      cards: true,
      options: const CollectionTextExportOptions(includeHtml: true),
      notes: const [],
      cardRecords: [low, high],
    );
    expect(result.text, '#separator:tab\n#html:true\nq\ta\nx\ty\n');
    expect(high.id.toString(), '9007199254740993');
  });

  test('plain text export decodes full numeric HTML entities', () {
    expect(exportTextField('<b>&#x27; &#169; &amp;</b>', false), "' © &");
  });

  test('HTML-enabled export still removes Core redundant sections', () {
    expect(
      exportTextField('<style>.x {}</style>[[type:Back]]<b>text</b>', true),
      '<b>text</b>',
    );
  });

  test('redundant type syntax is stripped case-insensitively like Core', () {
    expect(exportTextField('before[[TYPE:Back]]after', true), 'beforeafter');
  });

  test('card answer export removes FrontSide before stripping HTML', () {
    const answer = '<b>front</b><hr id=answer>\n<strong>back</strong>';
    expect(exportCardAnswer(answer, false), 'back');
    expect(exportCardAnswer(answer, true), '<strong>back</strong>');
  });

  test('All decks exports orphaned cards using exact large IDs', () async {
    final storage = await CollectionSqliteStorage.open(
      driver: CollectionSqliteDriver(
        openDatabase: (_) => sqlite3.openInMemory(),
      ),
      location: ':memory:',
    );
    try {
      await storage.executeBatch('''
        CREATE TABLE cards (id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER, mod INTEGER, usn INTEGER, type INTEGER, queue INTEGER, due INTEGER, ivl REAL, factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER, odue INTEGER, odid INTEGER, flags INTEGER, data TEXT);
        CREATE TABLE notes (id INTEGER PRIMARY KEY, guid TEXT, mid INTEGER, mod INTEGER, usn INTEGER, tags TEXT, flds TEXT, sfld TEXT, csum INTEGER);
        CREATE TABLE decks (id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER, common BLOB, kind BLOB);
        CREATE TABLE notetypes (id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER, config BLOB);
        CREATE TABLE fields (ntid INTEGER, ord INTEGER, name TEXT, config BLOB);
        CREATE TABLE templates (ntid INTEGER, ord INTEGER, name TEXT, mtime_secs INTEGER, usn INTEGER, config BLOB);
        INSERT INTO cards VALUES (9007199254740995, 9007199254740996, 9007199254740997, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '{}');
        INSERT INTO notes VALUES (9007199254740996, 'guid', 9007199254740998, 0, 0, 'tag', '<b>field</b>', '<b>field</b>', 0);
      ''');
      final result = await storage.exportText(
        cards: false,
        options: const CollectionTextExportOptions(includeHtml: true),
      );
      expect(result.count, 1);
      expect(result.text, '#separator:tab\n#html:true\n<b>field</b>\n');
    } finally {
      await storage.close();
    }
  });

  test(
    'selected parent export includes child decks and preserves Int64 ID',
    () async {
      final storage = await CollectionSqliteStorage.open(
        driver: CollectionSqliteDriver(
          openDatabase: (_) => sqlite3.openInMemory(),
        ),
        location: ':memory:',
      );
      try {
        await storage.executeBatch('''
        CREATE TABLE cards (id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER, mod INTEGER, usn INTEGER, type INTEGER, queue INTEGER, due INTEGER, ivl REAL, factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER, odue INTEGER, odid INTEGER, flags INTEGER, data TEXT);
        CREATE TABLE notes (id INTEGER PRIMARY KEY, guid TEXT, mid INTEGER, mod INTEGER, usn INTEGER, tags TEXT, flds TEXT, sfld TEXT, csum INTEGER);
        CREATE TABLE decks (id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER, common BLOB, kind BLOB);
        CREATE TABLE notetypes (id INTEGER PRIMARY KEY, name TEXT, mtime_secs INTEGER, usn INTEGER, config BLOB);
        CREATE TABLE fields (ntid INTEGER, ord INTEGER, name TEXT, config BLOB);
        CREATE TABLE templates (ntid INTEGER, ord INTEGER, name TEXT, mtime_secs INTEGER, usn INTEGER, config BLOB);
      ''');
        final parentId = Int64.parseInt('9007199254741000');
        final childId = parentId + Int64.ONE;
        final siblingId = parentId + Int64(2);
        storage.decks.addOrUpdateDeckWithExistingId(
          Deck(
            id: parentId,
            name: 'Parent',
            kind: NormalDeckKind(proto.Deck_Normal(configId: Int64.ONE)),
          ),
        );
        storage.decks.addOrUpdateDeckWithExistingId(
          Deck(
            id: childId,
            name: 'Parent::Child',
            kind: NormalDeckKind(proto.Deck_Normal(configId: Int64.ONE)),
          ),
        );
        storage.decks.addOrUpdateDeckWithExistingId(
          Deck(
            id: siblingId,
            name: 'Sibling',
            kind: NormalDeckKind(proto.Deck_Normal(configId: Int64.ONE)),
          ),
        );
        await storage.executeBatch('''
        INSERT INTO cards VALUES (1001, 2001, 9007199254741001, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '{}');
        INSERT INTO cards VALUES (1002, 2002, 9007199254741002, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '{}');
        INSERT INTO notes VALUES (2001, 'child', 3001, 0, 0, '', 'child note', 'child note', 0);
        INSERT INTO notes VALUES (2002, 'sibling', 3001, 0, 0, '', 'sibling note', 'sibling note', 0);
      ''');
        final result = await storage.exportText(
          cards: false,
          deckId: parentId,
          options: const CollectionTextExportOptions(includeHtml: true),
        );
        expect(result.count, 1);
        expect(result.text, '#separator:tab\n#html:true\nchild note\n');
      } finally {
        await storage.close();
      }
    },
  );
}
