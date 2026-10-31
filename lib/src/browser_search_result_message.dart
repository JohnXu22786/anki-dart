/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from CardBrowserViewModel.kt:1514–1528 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// A result-message choice for a completed Card Browser search.
///
/// The host owns the completed search state and delivers/localizes any message.
sealed class BrowserSearchResultMessage {
  const BrowserSearchResultMessage();
}

/// The host should display its localized card-count message.
final class BrowserSearchResultCardCount extends BrowserSearchResultMessage {
  const BrowserSearchResultCardCount({
    required this.includeSearchAllDecksAction,
  });

  final bool includeSearchAllDecksAction;

  @override
  bool operator ==(Object other) =>
      other is BrowserSearchResultCardCount &&
      other.includeSearchAllDecksAction == includeSearchAllDecksAction;

  @override
  int get hashCode => includeSearchAllDecksAction.hashCode;
}

/// The host should display its localized empty-selected-deck message.
final class BrowserSearchResultNoCardsInSelectedDeck
    extends BrowserSearchResultMessage {
  const BrowserSearchResultNoCardsInSelectedDeck();

  @override
  bool operator ==(Object other) =>
      other is BrowserSearchResultNoCardsInSelectedDeck;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Selects the source-equivalent result message for a completed search.
///
/// Inputs come from the host's search state. The all-decks check intentionally
/// precedes the zero-row check, matching AnkiDroid even when all-decks has no
/// rows; the source retains a TODO for that case. The host still constructs and
/// publishes the completed state, executes any snackbar action, and owns UI,
/// navigation, and row-count derivation.
BrowserSearchResultMessage? browserSearchResultMessage({
  required bool fromUserSearch,
  required bool hasSelectedAllDecks,
  required int rowCount,
}) {
  if (!fromUserSearch) {
    return null;
  }
  if (hasSelectedAllDecks) {
    return const BrowserSearchResultCardCount(
      includeSearchAllDecksAction: false,
    );
  }
  if (rowCount == 0) {
    return const BrowserSearchResultNoCardsInSelectedDeck();
  }
  return const BrowserSearchResultCardCount(
    includeSearchAllDecksAction: true,
  );
}
