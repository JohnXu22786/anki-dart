/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:convert';

import 'package:anki_app/collection_text_export.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as proto;
import 'package:anki_dart/deck_picker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test(
    'Notes routing forwards exact deck IDs and selected descendants',
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
        for (final (id, name) in [
          (parentId, 'Parent'),
          (childId, 'Parent::Child'),
          (siblingId, 'Sibling'),
        ]) {
          storage.decks.addOrUpdateDeckWithExistingId(
            Deck(
              id: id,
              name: name,
              kind: NormalDeckKind(proto.Deck_Normal(configId: Int64.ONE)),
            ),
          );
        }
        await storage.executeBatch('''
        INSERT INTO cards VALUES (1, 11, 9007199254741001, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '{}');
        INSERT INTO cards VALUES (2, 12, 9007199254741002, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '{}');
        INSERT INTO notes VALUES (11, 'child', 3001, 0, 0, '', 'child note', 'child note', 0);
        INSERT INTO notes VALUES (12, 'sibling', 3001, 0, 0, '', 'sibling note', 'sibling note', 0);
      ''');

        final request = projectDeckPickerExportDeck(
          legacyDeckId: 5,
          exactDeckId: parentId,
          format: DeckPickerExportFormat.notes,
          options: DeckPickerExportOptions.defaultsFor(
            DeckPickerExportFormat.notes,
          ),
        );
        final result = await generateDeckPickerTextExport(storage, request);
        final artifact = createDeckPickerTextExportArtifact(request, result);

        expect(request.deckId, parentId);
        expect(
          result.text,
          '#separator:tab\n#html:true\n#tags column:2\nchild note\t\n',
        );
        expect(result.text, isNot(contains('sibling note')));
        expect(artifact.fileName, 'notes.txt');
        expect(artifact.bytes, utf8.encode(result.text));
      } finally {
        await storage.close();
      }
    },
  );
}
