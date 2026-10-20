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
 * Behavioral reference: CardBrowserSearchViewModelTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser saved-search messages', () {
    test('successful add projects SEARCH_SAVED', () {
      final saved = BrowserSavedSearchesModel();
      final result = saved.add(const BrowserSavedSearch(name: 'a', query: 'b'));

      expect(
        browserSavedSearchUserMessageForMutation(
          operation: BrowserSavedSearchMutationOperation.add,
          result: result,
        ),
        BrowserSavedSearchUserMessage.SEARCH_SAVED,
      );
    });

    test('duplicate add projects SAVED_SEARCH_DUPLICATE_ADDED', () {
      final saved = BrowserSavedSearchesModel();
      saved.add(const BrowserSavedSearch(name: 'a', query: 'b'));
      final result =
          saved.add(const BrowserSavedSearch(name: 'a', query: 'another'));

      expect(
        browserSavedSearchUserMessageForMutation(
          operation: BrowserSavedSearchMutationOperation.add,
          result: result,
        ),
        BrowserSavedSearchUserMessage.SAVED_SEARCH_DUPLICATE_ADDED,
      );
    });

    test('successful delete projects SAVED_SEARCH_DELETED', () {
      final saved = BrowserSavedSearchesModel(
        configValues: {'a': 'b'},
      );
      final result = saved.removeByName('a');

      expect(
        browserSavedSearchUserMessageForMutation(
          operation: BrowserSavedSearchMutationOperation.delete,
          result: result,
        ),
        BrowserSavedSearchUserMessage.SAVED_SEARCH_DELETED,
      );
    });

    test('missing delete projects SAVED_SEARCH_NAME_DOES_NOT_EXIST', () {
      final result = BrowserSavedSearchesModel().removeByName('missing');

      expect(
        browserSavedSearchUserMessageForMutation(
          operation: BrowserSavedSearchMutationOperation.delete,
          result: result,
        ),
        BrowserSavedSearchUserMessage.SAVED_SEARCH_NAME_DOES_NOT_EXIST,
      );
    });
  });
}
