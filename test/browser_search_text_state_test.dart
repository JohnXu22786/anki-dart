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
 * Behavioral reference: `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/
 * CardBrowserSearchViewModel.kt` and its `CardBrowserSearchViewModelTest.kt`.
 * See ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser search text state', () {
    test('starts in Basic mode with empty independent buffers', () {
      const state = BrowserSearchTextState();

      expect(state.isAdvancedSearch, isFalse);
      expect(state.basicText, '');
      expect(state.advancedText, '');
      expect(state.displayedText, '');
    });

    test('mode toggling preserves both buffers and changes projection', () {
      final basic = const BrowserSearchTextState().onSearchTextChanged('basic');
      final advanced = basic
          .appendAdvancedSearch('advanced while Basic')
          .toggleAdvancedSearch();

      expect(advanced.isAdvancedSearch, isTrue);
      expect(advanced.displayedText, 'advanced while Basic ');
      expect(advanced.basicText, 'basic');

      final backToBasic = advanced.toggleAdvancedSearch();
      expect(backToBasic.isAdvancedSearch, isFalse);
      expect(backToBasic.displayedText, 'basic');
      expect(backToBasic.advancedText, 'advanced while Basic ');
    });

    test('advanced append separates tokens and retains trailing space', () {
      final state = const BrowserSearchTextState()
          .toggleAdvancedSearch()
          .appendAdvancedSearch('hello')
          .appendAdvancedSearch('deck:aa');

      expect(state.advancedText, 'hello deck:aa ');
      expect(state.displayedText, 'hello deck:aa ');
    });

    test('advanced append uses Kotlin blank and exact ASCII-space checks', () {
      final blankCurrent =
          const BrowserSearchTextState(advancedText: '\u00a0\t\u2003')
              .appendAdvancedSearch('term');
      final nonAsciiSpaceSuffix =
          const BrowserSearchTextState(advancedText: 'word\t')
              .appendAdvancedSearch('term');
      final asciiSpaceSuffix =
          const BrowserSearchTextState(advancedText: 'word  ')
              .appendAdvancedSearch('term');
      final emptyAppend = const BrowserSearchTextState(advancedText: 'word')
          .appendAdvancedSearch('');

      expect(blankCurrent.advancedText, '\u00a0\t\u2003term ');
      expect(nonAsciiSpaceSuffix.advancedText, 'word\t term ');
      expect(asciiSpaceSuffix.advancedText, 'word  term ');
      expect(emptyAppend.advancedText, 'word  ');
    });

    test('text changes replace LF only in the selected buffer', () {
      final state = const BrowserSearchTextState(
        basicText: 'keep basic',
        advancedText: 'old advanced',
      ).toggleAdvancedSearch().onSearchTextChanged('first\nsecond\r\nlast\r');

      expect(state.advancedText, 'first second\r last\r');
      expect(state.basicText, 'keep basic');
      expect(state.displayedText, 'first second\r last\r');
    });

    test('typing replaces previously appended Advanced text', () {
      final state = const BrowserSearchTextState()
          .toggleAdvancedSearch()
          .appendAdvancedSearch('old')
          .onSearchTextChanged('replaced');

      expect(state.advancedText, 'replaced');
      expect(state.displayedText, 'replaced');
    });

    test('applying a saved query to empty Basic text adds a trailing space',
        () {
      final state =
          const BrowserSearchTextState().applySavedSearch('sample\nquery');

      expect(state.isAdvancedSearch, isFalse);
      expect(state.basicText, 'sample query ');
      expect(state.displayedText, 'sample query ');
      expect(state.advancedText, '');
    });

    test('applying a saved query replaces existing Basic text', () {
      final state = const BrowserSearchTextState(
        basicText: 'testing',
        advancedText: 'advanced kept',
      ).applySavedSearch('sample query');

      expect(state.basicText, 'sample query ');
      expect(state.advancedText, 'advanced kept');
      expect(state.displayedText, 'sample query ');
    });
  });
}
