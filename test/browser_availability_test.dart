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
  group('Card Browser availability projections', () {
    test('history availability follows entry-to-search-string values', () {
      expect(browserSearchHistoryIsAvailable(BrowserSearchHistoryLoading([])),
          isFalse);
      expect(
          browserSearchHistoryIsAvailable(const BrowserSearchHistoryLoaded([])),
          isFalse);

      final entry = BrowserSearchHistoryEntry(query: 'saved query');
      expect(
          browserSearchHistoryIsAvailable(BrowserSearchHistoryLoading([entry])),
          isTrue);
      expect(
        browserSearchHistoryIsAvailable(BrowserSearchHistoryLoaded([
          (entry: entry, searchString: null),
        ])),
        isTrue,
      );
    });

    test('saved-search manage availability follows the current list', () {
      final saved = BrowserSavedSearchesModel();

      expect(browserCanManageSavedSearches(saved.searches), isFalse);

      saved.add(const BrowserSavedSearch(name: 'A', query: 'sample query'));
      expect(browserCanManageSavedSearches(saved.searches), isTrue);

      saved.removeByName('A');
      expect(browserCanManageSavedSearches(saved.searches), isFalse);
    });
  });
}
