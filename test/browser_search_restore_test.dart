/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral references: CardBrowserSearchViewModel.kt, SearchHistoryTest.kt,
 * SearchFilters.kt, and SearchRequest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser search-history restoration', () {
    test('separate note type values retain source identity semantics', () {
      final first = BrowserNoteTypeNameId(name: 'Basic', id: 3);
      final second = BrowserNoteTypeNameId(name: 'Basic', id: 3);

      expect(identical(first, second), isFalse);
      expect(first, isNot(second));
    });

    final decks = [
      const BrowserDeckNameId(name: 'Default', id: 1),
      const BrowserDeckNameId(name: 'Language::Spanish', id: 2),
    ];
    final noteTypes = [
      BrowserNoteTypeNameId(name: 'Basic', id: 3),
      BrowserNoteTypeNameId(name: 'Cloze', id: 4),
    ];

    test('maps all filter IDs while retaining other filter values', () {
      const entry = BrowserSearchHistoryEntry(
        query: 'queryString',
        deckIds: [1, 2],
        flags: [1, 4],
        tags: ['Hello::World', 'tag'],
        noteTypeIds: [3, 4],
        cardStateCodes: [0, 1, 2, 3, 4],
      );

      final filters = BrowserSearchFilters.fromHistoryEntry(
        entry,
        deckNameMap: decks,
        noteTypeMap: noteTypes,
      );

      expect(filters, isNotNull);
      expect(filters!.decks.map((deck) => deck.name),
          ['Default', 'Language::Spanish']);
      expect(filters.flags, [1, 4]);
      expect(filters.tags, ['Hello::World', 'tag']);
      expect(filters.noteTypes.map((type) => type.name), ['Basic', 'Cloze']);
      expect(filters.cardStateCodes, [0, 1, 2, 3, 4]);
    });

    test('search filters and requests use Kotlin data-class value equality',
        () {
      final firstDeck = BrowserDeckNameId(name: 'Default', id: 1);
      final firstNoteType = BrowserNoteTypeNameId(name: 'Basic', id: 3);
      final firstFilters = BrowserSearchFilters(
        decks: [firstDeck],
        flags: [1, 4],
        tags: ['tag'],
        noteTypes: [firstNoteType],
        cardStateCodes: [0, 2],
      );
      final equalFilters = BrowserSearchFilters(
        decks: [BrowserDeckNameId(name: 'Default', id: 1)],
        flags: [1, 4],
        tags: ['tag'],
        // NoteTypeNameID is a regular Kotlin class, so it retains identity.
        noteTypes: [firstNoteType],
        cardStateCodes: [0, 2],
      );
      final differentNoteType = BrowserSearchFilters(
        decks: [firstDeck],
        flags: [1, 4],
        tags: ['tag'],
        noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: 3)],
        cardStateCodes: [0, 2],
      );

      expect(firstDeck, BrowserDeckNameId(name: 'Default', id: 1));
      expect(firstFilters, equalFilters);
      expect(firstFilters.hashCode, equalFilters.hashCode);
      expect(firstFilters, isNot(differentNoteType));

      final request = BrowserSearchRequest(query: 'q', filters: firstFilters);
      final equalRequest = BrowserSearchRequest(
        query: 'q',
        filters: equalFilters,
      );
      expect(request, equalRequest);
      expect(request.hashCode, equalRequest.hashCode);
    });

    test('restores the original query with its structured filters', () {
      const entry = BrowserSearchHistoryEntry(
        query: '  query text  ',
        deckIds: [1],
        noteTypeIds: [4],
      );

      final request = BrowserSearchRequest.fromHistoryEntry(
        entry,
        deckNameMap: decks,
        noteTypeMap: noteTypes,
      );

      expect(request, isNotNull);
      expect(request!.query, '  query text  ');
      expect(request.filters.decks.single.name, 'Default');
      expect(request.filters.noteTypes.single.name, 'Cloze');
    });

    test('preserves repeated IDs and uses the first matching host mapping', () {
      const entry = BrowserSearchHistoryEntry(
        query: 'duplicates',
        deckIds: [9, 7, 9],
        noteTypeIds: [6, 6],
      );
      const deckMap = [
        BrowserDeckNameId(name: 'First deck', id: 9),
        BrowserDeckNameId(name: 'Ignored duplicate deck', id: 9),
        BrowserDeckNameId(name: 'Other deck', id: 7),
      ];
      final noteTypeMap = [
        BrowserNoteTypeNameId(name: 'First type', id: 6),
        BrowserNoteTypeNameId(name: 'Ignored duplicate type', id: 6),
      ];

      final request = BrowserSearchRequest.fromHistoryEntry(
        entry,
        deckNameMap: deckMap,
        noteTypeMap: noteTypeMap,
      );

      expect(request!.filters.decks.map((deck) => deck.name), [
        'First deck',
        'Other deck',
        'First deck',
      ]);
      expect(request.filters.noteTypes.map((type) => type.name), [
        'First type',
        'First type',
      ]);
    });

    test('converts a request to an ID-based history entry and trims its query',
        () {
      final request = BrowserSearchRequest(
        query: '\u00a0\t query text \u00a0',
        filters: BrowserSearchFilters(
          decks: [
            BrowserDeckNameId(name: 'Default', id: 1),
            BrowserDeckNameId(name: 'Default', id: 1),
          ],
          flags: [1, 4],
          tags: ['tag', 'other'],
          noteTypes: [
            BrowserNoteTypeNameId(name: 'Cloze', id: 4),
            BrowserNoteTypeNameId(name: 'Basic', id: 3),
          ],
          cardStateCodes: [4, 0],
        ),
      );

      expect(
        request.toHistoryEntry(),
        const BrowserSearchHistoryEntry(
          query: 'query text',
          deckIds: [1, 1],
          flags: [1, 4],
          tags: ['tag', 'other'],
          noteTypeIds: [4, 3],
          cardStateCodes: [4, 0],
        ),
      );

      const sourceWhitespace = BrowserSearchRequest(query: '\u0085query\u0085');
      expect(
        sourceWhitespace.toHistoryEntry().query,
        '\u0085query\u0085',
      );
    });

    test('returns null when any deck ID cannot be resolved', () {
      const entry =
          BrowserSearchHistoryEntry(query: 'missing', deckIds: [1, 99]);

      expect(
        BrowserSearchRequest.fromHistoryEntry(
          entry,
          deckNameMap: decks,
          noteTypeMap: noteTypes,
        ),
        isNull,
      );
    });

    test('returns null when any note-type ID cannot be resolved', () {
      const entry =
          BrowserSearchHistoryEntry(query: 'missing', noteTypeIds: [3, 99]);

      expect(
        BrowserSearchRequest.fromHistoryEntry(
          entry,
          deckNameMap: decks,
          noteTypeMap: noteTypes,
        ),
        isNull,
      );
    });
  });
}
