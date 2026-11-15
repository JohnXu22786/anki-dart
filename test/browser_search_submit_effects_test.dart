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
 * Source-derived ordered-effect cases for CardBrowserSearchViewModel.kt's
 * SearchRequest submit overload; its pinned tests do not call that overload.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser request-submission effects', () {
    test('history Loading precedes close-view and exact request events', () {
      const oldEntry = BrowserSearchHistoryEntry(query: 'old');
      final history = BrowserSearchHistoryModel(entries: [oldEntry]);
      final filters = BrowserSearchFilters(
        decks: [
          BrowserDeckNameId(name: 'Languages', id: 7),
          BrowserDeckNameId(name: 'Default', id: 1),
        ],
        flags: [1, 4],
        tags: ['first', 'second'],
        noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: 3)],
        cardStateCodes: [0, 2],
      );
      final request = BrowserSearchRequest(
        query: ' \u00a0search query\t ',
        filters: filters,
      );

      final effects = browserSubmitCurrentSearchEffects(
        request,
        history: history,
      );

      expect(
        effects.map((effect) => effect.runtimeType),
        [
          BrowserSearchHistoryLoadingEffect,
          BrowserCloseSearchViewEventEffect,
          BrowserSearchSubmittedEffect,
        ],
      );
      final loading = (effects[0] as BrowserSearchHistoryLoadingEffect).history;
      const addedEntry = BrowserSearchHistoryEntry(
        query: 'search query',
        deckIds: [7, 1],
        flags: [1, 4],
        tags: ['first', 'second'],
        noteTypeIds: [3],
        cardStateCodes: [0, 2],
      );
      expect(loading, isA<BrowserSearchHistoryLoading>());
      expect(loading.input, [addedEntry, oldEntry]);
      expect(loading.entryToSearchString, [
        (entry: addedEntry, searchString: null),
        (entry: oldEntry, searchString: null),
      ]);
      expect(history.entries, [addedEntry, oldEntry]);
      expect(
          identical(
              (effects[2] as BrowserSearchSubmittedEffect).search, request),
          isTrue);
      expect(request.query, ' \u00a0search query\t ');
    });

    test('blank unfiltered request still publishes unchanged Loading history',
        () {
      const existingEntry = BrowserSearchHistoryEntry(
        query: 'existing',
        tags: ['kept'],
      );
      final history = BrowserSearchHistoryModel(entries: [existingEntry]);
      const request = BrowserSearchRequest(query: ' \u00a0\t ');

      final effects = browserSubmitCurrentSearchEffects(
        request,
        history: history,
      );

      expect(
        effects.map((effect) => effect.runtimeType),
        [
          BrowserSearchHistoryLoadingEffect,
          BrowserCloseSearchViewEventEffect,
          BrowserSearchSubmittedEffect,
        ],
      );
      final loading = (effects[0] as BrowserSearchHistoryLoadingEffect).history;
      expect(loading, BrowserSearchHistoryLoading([existingEntry]));
      expect(history.entries, [existingEntry]);
      expect(
          identical(
              (effects[2] as BrowserSearchSubmittedEffect).search, request),
          isTrue);
      expect(effects.whereType<BrowserSearchScreenOpenEffect>(), isEmpty);
    });

    test(
        'blank query with filters is recorded without changing submitted request',
        () {
      final history = BrowserSearchHistoryModel();
      const request = BrowserSearchRequest(
        query: ' \t',
        filters: BrowserSearchFilters(flags: [4]),
      );

      final effects = browserSubmitCurrentSearchEffects(
        request,
        history: history,
      );

      expect(
        (effects[0] as BrowserSearchHistoryLoadingEffect).history.input,
        [
          const BrowserSearchHistoryEntry(query: '', flags: [4])
        ],
      );
      expect((effects[2] as BrowserSearchSubmittedEffect).search.query, ' \t');
      expect(history.entries, [
        const BrowserSearchHistoryEntry(query: '', flags: [4])
      ]);
    });
  });
}
