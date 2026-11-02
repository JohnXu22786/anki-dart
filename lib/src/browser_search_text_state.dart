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
 * Behavioral reference: CardBrowserSearchViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'kotlin_whitespace.dart';

/// Immutable headless state for the Card Browser's Basic and Advanced text.
///
/// The host owns SavedStateHandle/StateFlow and widgets. Each transition here
/// returns a new snapshot while preserving the other text buffer.
final class BrowserSearchTextState {
  const BrowserSearchTextState({
    this.isAdvancedSearch = false,
    this.basicText = '',
    this.advancedText = '',
  });

  final bool isAdvancedSearch;
  final String basicText;
  final String advancedText;

  /// Text displayed by the currently selected search mode.
  String get displayedText => isAdvancedSearch ? advancedText : basicText;

  /// Toggles Basic/Advanced mode without changing either text buffer.
  BrowserSearchTextState toggleAdvancedSearch() => BrowserSearchTextState(
        isAdvancedSearch: !isAdvancedSearch,
        basicText: basicText,
        advancedText: advancedText,
      );

  /// Appends text to Advanced mode, whether or not it is currently selected.
  ///
  /// Matches the source's Kotlin `isNotBlank()` test and exact `endsWith(" ")`
  /// delimiter check, then always appends one trailing ASCII space.
  BrowserSearchTextState appendAdvancedSearch(String searchText) {
    final needsSeparator = trimKotlinWhitespace(advancedText).isNotEmpty &&
        !advancedText.endsWith(' ');
    return BrowserSearchTextState(
      isAdvancedSearch: isAdvancedSearch,
      basicText: basicText,
      advancedText: '$advancedText${needsSeparator ? ' ' : ''}$searchText ',
    );
  }

  /// Replaces the currently selected text buffer, mapping LF to ASCII space.
  /// Other code units, including CR, are retained unchanged.
  BrowserSearchTextState onSearchTextChanged(String searchText) {
    final sanitizedText = searchText.replaceAll('\n', ' ');
    return isAdvancedSearch
        ? BrowserSearchTextState(
            isAdvancedSearch: isAdvancedSearch,
            basicText: basicText,
            advancedText: sanitizedText,
          )
        : BrowserSearchTextState(
            isAdvancedSearch: isAdvancedSearch,
            basicText: sanitizedText,
            advancedText: advancedText,
          );
  }

  /// Replaces selected text with a saved query followed by one ASCII space.
  BrowserSearchTextState applySavedSearch(String query) =>
      onSearchTextChanged('$query ');
}
