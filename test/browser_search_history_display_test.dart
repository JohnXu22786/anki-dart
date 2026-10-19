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
 * Behavioral reference: CardBrowserSearchViewModel.kt and
 * CardBrowserSearchViewModelTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser search-history display', () {
    test('starts collapsed and toggles between truncated and full history', () {
      final model = BrowserSearchHistoryDisplayModel();
      final items = _loadedItems(7);

      expect(model.isHistoryExpanded, isFalse);
      expect(model.project(items).items.entryToSearchString, hasLength(5));

      model.toggleHistoryExpanded();
      expect(model.isHistoryExpanded, isTrue);
      expect(model.project(items).items.entryToSearchString, hasLength(7));

      model.toggleHistoryExpanded();
      expect(model.isHistoryExpanded, isFalse);
      expect(model.project(items).items.entryToSearchString, hasLength(5));
    });

    test('five collapsed items are all shown without a history toggle', () {
      final projection = BrowserSearchHistoryDisplayModel().project(
        _loadedItems(5),
      );

      expect(projection.items.entryToSearchString, hasLength(5));
      expect(projection.showHistoryToggle, isFalse);
    });

    test('six collapsed items show five and the toggle uses full history size',
        () {
      final allItems = _loadedItems(6);
      final projection = BrowserSearchHistoryDisplayModel().project(allItems);

      expect(projection.items.entryToSearchString, hasLength(5));
      expect(projection.items.entryToSearchString,
          allItems.entryToSearchString.take(5));
      expect(projection.showHistoryToggle, isTrue);
    });

    test('expansion shows all entries and collapse preserves source order', () {
      final model = BrowserSearchHistoryDisplayModel();
      final items = _loadedItems(8);

      model.toggleHistoryExpanded();
      expect(model.project(items).items.entryToSearchString,
          items.entryToSearchString);

      model.toggleHistoryExpanded();
      expect(model.project(items).items.entryToSearchString,
          items.entryToSearchString.take(5));
    });

    test('truncating Loading preserves its shape and null search-string pairs',
        () {
      final entries = _entries(6);
      final loading = BrowserSearchHistoryLoading(entries);

      expect(loading.isNotEmpty(), isTrue);
      final projection = BrowserSearchHistoryDisplayModel().project(loading);

      expect(projection.items, isA<BrowserSearchHistoryLoading>());
      final visible = projection.items as BrowserSearchHistoryLoading;
      expect(visible.input, entries.take(5));
      expect(
        visible.entryToSearchString,
        entries.take(5).map((entry) => (entry: entry, searchString: null)),
      );
    });

    test('Loading captures entry pairs when it is constructed', () {
      final entries = _entries(1);
      final loading = BrowserSearchHistoryLoading(entries);
      final projection = loading.entryToSearchString;

      entries.add(BrowserSearchHistoryEntry(query: 'later'));

      expect(projection, hasLength(1));
      expect(loading.entryToSearchString, hasLength(1));
      expect(loading.entryToSearchString.single.entry.query, 'search 0');
    });

    test('Loading and Loaded use their source data-class value equality', () {
      final entry = BrowserSearchHistoryEntry(query: 'same');
      final loading = BrowserSearchHistoryLoading([entry]);
      final equalLoading = BrowserSearchHistoryLoading([
        BrowserSearchHistoryEntry(query: 'same'),
      ]);
      final loaded = BrowserSearchHistoryLoaded([
        (entry: entry, searchString: 's:same'),
      ]);
      final equalLoaded = BrowserSearchHistoryLoaded([
        (
          entry: BrowserSearchHistoryEntry(query: 'same'),
          searchString: 's:same',
        ),
      ]);

      expect(loading, equalLoading);
      expect(loading.hashCode, equalLoading.hashCode);
      expect(loaded, equalLoaded);
      expect(loaded.hashCode, equalLoaded.hashCode);
      expect(loading, isNot(loaded));
    });

    test('truncating Loaded preserves nullable converted search strings', () {
      final loaded = BrowserSearchHistoryLoaded([
        for (final entry in _entries(6))
          (
            entry: entry,
            searchString: entry.query == 'search 2' ? null : 's:${entry.query}'
          ),
      ]);

      final collapsed = BrowserSearchHistoryDisplayModel().project(loaded);
      expect(collapsed.items, isA<BrowserSearchHistoryLoaded>());
      expect(
        collapsed.items.entryToSearchString,
        loaded.entryToSearchString.take(5),
      );
      expect(collapsed.items.entryToSearchString[2].searchString, isNull);

      final model = BrowserSearchHistoryDisplayModel()..toggleHistoryExpanded();
      final expanded = model.project(loaded);
      expect(expanded.items.entryToSearchString, loaded.entryToSearchString);
      expect(expanded.showHistoryToggle, isTrue);
    });
  });
}

List<BrowserSearchHistoryEntry> _entries(int count) => [
      for (var index = 0; index < count; index++)
        BrowserSearchHistoryEntry(query: 'search $index'),
    ];

BrowserSearchHistoryLoaded _loadedItems(int count) =>
    BrowserSearchHistoryLoaded([
      for (final entry in _entries(count))
        (entry: entry, searchString: 's:${entry.query}'),
    ]);
