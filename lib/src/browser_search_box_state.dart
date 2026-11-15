/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// One ordered assignment from the Card Browser search-box state transitions.
/// The host applies these changes to its flows; null and false are explicit
/// assigned values, while an absent change leaves that field untouched.
sealed class BrowserSearchBoxStateChange {
  const BrowserSearchBoxStateChange();
}

/// Sets the unsubmitted query text, or clears it when [text] is null.
final class BrowserSearchBoxInputChange extends BrowserSearchBoxStateChange {
  const BrowserSearchBoxInputChange(this.text);

  final String? text;
}

/// Sets whether the search box is expanded.
final class BrowserSearchBoxExpansionChange
    extends BrowserSearchBoxStateChange {
  const BrowserSearchBoxExpansionChange(this.isExpanded);

  final bool isExpanded;
}

/// Projects `setSearchQueryExpanded(expand)` in source order.
///
/// Expanding changes only expansion. Collapsing clears unsubmitted input first,
/// then sets expansion to false. The host owns StateFlow mutation, focus, and UI.
List<BrowserSearchBoxStateChange> setBrowserSearchQueryExpanded(bool expand) =>
    List.unmodifiable([
      if (expand)
        const BrowserSearchBoxExpansionChange(true)
      else ...[
        const BrowserSearchBoxInputChange(null),
        const BrowserSearchBoxExpansionChange(false),
      ],
    ]);

/// Projects `updateQueryText(newText)` without normalization or expansion
/// changes. An empty string is an explicit text value, distinct from clearing.
List<BrowserSearchBoxStateChange> updateBrowserSearchQueryText(
  String newText,
) => List.unmodifiable([BrowserSearchBoxInputChange(newText)]);

/// Projects `removeUnsubmittedInput()`, preserving expansion.
List<BrowserSearchBoxStateChange> removeBrowserUnsubmittedInput() =>
    List.unmodifiable([const BrowserSearchBoxInputChange(null)]);
