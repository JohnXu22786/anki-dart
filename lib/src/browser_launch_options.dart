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
 * Behavioral reference: CardBrowserLaunchOptions.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md. Android Intent/Uri extraction remains host-side.
 */

/// One source-equivalent way to open AnkiDroid's Card Browser.
sealed class BrowserLaunchOption {
  const BrowserLaunchOption();
}

/// Opens the browser with the `search` query parameter from a deep link.
final class BrowserLaunchDeepLink extends BrowserLaunchOption {
  const BrowserLaunchDeepLink(this.search);

  final String search;

  @override
  bool operator ==(Object other) =>
      other is BrowserLaunchDeepLink && other.search == search;

  @override
  int get hashCode => search.hashCode;
}

/// Opens the browser with the search supplied by the JavaScript API.
final class BrowserLaunchSearchQueryJs extends BrowserLaunchOption {
  const BrowserLaunchSearchQueryJs(this.search, {required this.allDecks});

  final String search;
  final bool allDecks;

  @override
  bool operator ==(Object other) =>
      other is BrowserLaunchSearchQueryJs &&
      other.search == search &&
      other.allDecks == allDecks;

  @override
  int get hashCode => Object.hash(search, allDecks);
}

/// Opens the browser scrolled to the host-resolved card ID.
final class BrowserLaunchScrollToCard extends BrowserLaunchOption {
  const BrowserLaunchScrollToCard(this.cardId);

  final int cardId;

  @override
  bool operator ==(Object other) =>
      other is BrowserLaunchScrollToCard && other.cardId == cardId;

  @override
  int get hashCode => cardId.hashCode;
}

/// Opens the browser with text passed through the system process-text action.
final class BrowserLaunchSystemContextMenu extends BrowserLaunchOption {
  const BrowserLaunchSystemContextMenu(this.search);

  final String search;

  @override
  bool operator ==(Object other) =>
      other is BrowserLaunchSystemContextMenu && other.search == search;

  @override
  int get hashCode => search.hashCode;
}

/// Projects host-decoded intent fields to the source launch option.
///
/// Arguments are already extracted by the host from Android `Intent` and `Uri`
/// APIs. Their order here matches `toCardBrowserLaunchOptions()`: deep-link
/// search, JavaScript search, card ID, then non-empty process text for the
/// process-text action. A null search means absent; an empty deep-link or
/// JavaScript search is still present. Missing `all_decks` is represented by
/// [allDecks]'s false default. [cardId] is an already decoded signed 64-bit ID
/// on Android hosts; this platform-independent API does not inspect extras.
BrowserLaunchOption? browserLaunchOptionFromInput({
  String? deepLinkSearch,
  String? searchQueryJs,
  bool allDecks = false,
  int? cardId,
  bool actionIsProcessText = false,
  String? processTextSearch,
}) {
  if (deepLinkSearch != null) {
    return BrowserLaunchDeepLink(deepLinkSearch);
  }

  if (searchQueryJs != null) {
    return BrowserLaunchSearchQueryJs(searchQueryJs, allDecks: allDecks);
  }

  if (cardId != null) {
    return BrowserLaunchScrollToCard(cardId);
  }

  if (actionIsProcessText &&
      processTextSearch != null &&
      processTextSearch.isNotEmpty) {
    return BrowserLaunchSystemContextMenu(processTextSearch);
  }

  return null;
}
