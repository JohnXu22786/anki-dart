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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md. Hosts apply the returned patch to their state.
 */

import 'browser_launch_options.dart';

/// A field that is either left unchanged or explicitly assigned a value.
sealed class BrowserLaunchPatch<T> {
  const BrowserLaunchPatch();
}

/// Indicates that a launch option does not update this field.
final class BrowserLaunchUnchanged<T> extends BrowserLaunchPatch<T> {
  const BrowserLaunchUnchanged();
}

/// Indicates that a launch option explicitly assigns [value] to this field.
final class BrowserLaunchAssigned<T> extends BrowserLaunchPatch<T> {
  const BrowserLaunchAssigned(this.value);

  final T value;
}

/// Source-ordered initial state assignments from a Card Browser launch option.
final class BrowserLaunchStatePatch {
  const BrowserLaunchStatePatch({
    required this.searchTerms,
    required this.allDecks,
    required this.cardIdToBeScrolledTo,
  });

  const BrowserLaunchStatePatch.unchanged()
    : searchTerms = const BrowserLaunchUnchanged(),
      allDecks = const BrowserLaunchUnchanged(),
      cardIdToBeScrolledTo = const BrowserLaunchUnchanged();

  final BrowserLaunchPatch<String> searchTerms;
  final BrowserLaunchPatch<bool> allDecks;
  final BrowserLaunchPatch<int> cardIdToBeScrolledTo;
}

/// Projects an already resolved [BrowserLaunchOption] to initial state writes.
///
/// This mirrors the `when (options)` assignments in AnkiDroid's
/// `CardBrowserViewModel.init`: system text and deep links set search, JavaScript
/// search sets both search and all-decks, and scroll options set only the card
/// ID. A null option makes no assignments. The host applies the patch and owns
/// search execution, deck resolution, and collection access.
BrowserLaunchStatePatch projectBrowserLaunchState(
  BrowserLaunchOption? option,
) => switch (option) {
  BrowserLaunchSystemContextMenu(:final search) => BrowserLaunchStatePatch(
    searchTerms: BrowserLaunchAssigned(search),
    allDecks: const BrowserLaunchUnchanged(),
    cardIdToBeScrolledTo: const BrowserLaunchUnchanged(),
  ),
  BrowserLaunchDeepLink(:final search) => BrowserLaunchStatePatch(
    searchTerms: BrowserLaunchAssigned(search),
    allDecks: const BrowserLaunchUnchanged(),
    cardIdToBeScrolledTo: const BrowserLaunchUnchanged(),
  ),
  BrowserLaunchSearchQueryJs(:final search, :final allDecks) =>
    BrowserLaunchStatePatch(
      searchTerms: BrowserLaunchAssigned(search),
      allDecks: BrowserLaunchAssigned(allDecks),
      cardIdToBeScrolledTo: const BrowserLaunchUnchanged(),
    ),
  BrowserLaunchScrollToCard(:final cardId) => BrowserLaunchStatePatch(
    searchTerms: const BrowserLaunchUnchanged(),
    allDecks: const BrowserLaunchUnchanged(),
    cardIdToBeScrolledTo: BrowserLaunchAssigned(cardId),
  ),
  null => const BrowserLaunchStatePatch.unchanged(),
};
