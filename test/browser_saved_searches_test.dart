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
 * Behavioral reference: SavedSearches.kt and SavedSearchesTest.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser saved searches', () {
    test('orders names case-sensitively and looks them up exactly', () {
      final saved = BrowserSavedSearchesModel(configValues: {
        'a': 'lowercase',
        'Z': 'capital z',
        'A': 'capital a',
      });

      expect(saved.searches.map((search) => search.name), ['A', 'Z', 'a']);
      expect(saved.byName('A'),
          const BrowserSavedSearch(name: 'A', query: 'capital a'));
      expect(saved.byName('a'),
          const BrowserSavedSearch(name: 'a', query: 'lowercase'));
      expect(saved.byName('z'), isNull);
    });

    test('rejects a duplicate exact name without overwriting its query', () {
      final saved = BrowserSavedSearchesModel(configValues: {'a': 'original'});

      final result =
          saved.add(const BrowserSavedSearch(name: 'a', query: 'replacement'));

      expect(result.$1, isFalse);
      expect(
          result.$2, [const BrowserSavedSearch(name: 'a', query: 'original')]);
      expect(saved.configValues, {'a': 'original'});
    });

    test('normalizes only Kotlin String.trim whitespace when adding', () {
      final saved = BrowserSavedSearchesModel();

      final trimmed = saved.add(
        const BrowserSavedSearch(
            name: 'trimmed', query: '\u00a0\t query \u00a0\t'),
      );
      final preserved = saved.add(
        const BrowserSavedSearch(name: 'next-line', query: '\u0085query\u0085'),
      );

      expect(trimmed.$1, isTrue);
      expect(trimmed.$2.single.query, 'query');
      expect(preserved.$1, isTrue);
      expect(saved.byName('next-line')?.query, '\u0085query\u0085');
    });

    test(
        'removes an exact match and leaves values unchanged for a missing name',
        () {
      final saved =
          BrowserSavedSearchesModel(configValues: {'a': 'A', 'b': 'B'});

      final found = saved.removeByName('a');
      final missing = saved.removeByName('not found');

      expect(found.$1, isTrue);
      expect(found.$2, [const BrowserSavedSearch(name: 'b', query: 'B')]);
      expect(missing.$1, isFalse);
      expect(missing.$2, found.$2);
      expect(saved.configValues, {'b': 'B'});
    });

    test('clear removes all saved-search values', () {
      final saved =
          BrowserSavedSearchesModel(configValues: {'a': 'A', 'b': 'B'});

      saved.clear();

      expect(saved.searches, isEmpty);
      expect(saved.configValues, isEmpty);
    });

    test('map-list conversion keeps the last query for duplicate names', () {
      final config = browserSavedSearchesToConfigMap([
        const BrowserSavedSearch(name: 'same', query: 'first'),
        const BrowserSavedSearch(name: 'other', query: 'other query'),
        const BrowserSavedSearch(name: 'same', query: 'last'),
      ]);

      expect(config, {'same': 'last', 'other': 'other query'});
      expect(
        browserSavedSearchesFromConfigMap(config),
        [
          const BrowserSavedSearch(name: 'other', query: 'other query'),
          const BrowserSavedSearch(name: 'same', query: 'last'),
        ],
      );
    });
  });
}
