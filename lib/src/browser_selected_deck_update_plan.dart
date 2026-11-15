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
 * Behavioral reference: CardBrowserViewModel.setSelectedDeck() in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md. Persistence and search execution stay
 * host-side.
 */

import 'browser_search_request.dart';

/// A selected deck supplied by the host after source deck/name resolution.
sealed class BrowserSelectedDeck {
  const BrowserSelectedDeck();
}

/// The source `SelectableDeck.AllDecks` choice.
final class BrowserSelectAllDecks extends BrowserSelectedDeck {
  const BrowserSelectAllDecks();
}

/// A source `SelectableDeck.Deck` with its exact ID and host-resolved name/ID.
final class BrowserSelectSpecificDeck extends BrowserSelectedDeck {
  const BrowserSelectSpecificDeck({required this.id, required this.deckNameId});

  final int id;
  final BrowserDeckNameId deckNameId;
}

/// One ordered host action in a selected-deck update plan.
sealed class BrowserSelectedDeckUpdateEffect {
  const BrowserSelectedDeckUpdateEffect();
}

/// Persists the source `lastDeckId` value before search effects are applied.
final class BrowserPersistLastDeckIdEffect
    extends BrowserSelectedDeckUpdateEffect {
  const BrowserPersistLastDeckIdEffect(this.deckId);

  final int deckId;
}

/// Requests source search execution using the prepared request.
final class BrowserLaunchSelectedDeckSearchEffect
    extends BrowserSelectedDeckUpdateEffect {
  const BrowserLaunchSelectedDeckSearchEffect({
    required this.request,
    required this.forceRefresh,
  });

  final BrowserSearchRequest request;
  final bool forceRefresh;
}

/// Values and host actions projected from `setSelectedDeck()`.
///
/// The host executes [effects] in order, persisting [lastDeckId] before
/// launching [updatedRequest]. Request preparation copies only its deck filter;
/// all query and non-deck filter values are preserved. The host owns repository
/// writes, collection access, request-flow mutation, search comparison, and
/// actual search execution.
final class BrowserSelectedDeckUpdatePlan {
  BrowserSelectedDeckUpdatePlan({
    required this.lastDeckId,
    required this.deckFilter,
    required this.updatedRequest,
  }) : effects = List.unmodifiable([
         BrowserPersistLastDeckIdEffect(lastDeckId),
         BrowserLaunchSelectedDeckSearchEffect(
           request: updatedRequest,
           forceRefresh: false,
         ),
       ]);

  final int lastDeckId;
  final List<BrowserDeckNameId> deckFilter;
  final BrowserSearchRequest updatedRequest;
  final List<BrowserSelectedDeckUpdateEffect> effects;
}

/// Projects `CardBrowserViewModel.setSelectedDeck(deck)` for a host.
///
/// [selectedDeck] supplies the deck kind, exact selected ID, and already
/// resolved [BrowserDeckNameId]. AllDecks selects [allDecksId] and an empty
/// filter; a specific deck uses its own ID and a singleton filter. The source
/// persists the last-deck value before requesting a search with
/// `forceRefresh = false`. This function performs no persistence, request-flow
/// mutation, collection access, or search execution.
BrowserSelectedDeckUpdatePlan planBrowserSelectedDeckUpdate({
  required BrowserSelectedDeck selectedDeck,
  required int allDecksId,
  required BrowserSearchRequest currentRequest,
}) {
  final int lastDeckId;
  final List<BrowserDeckNameId> deckFilter;
  switch (selectedDeck) {
    case BrowserSelectAllDecks():
      lastDeckId = allDecksId;
      deckFilter = const [];
    case BrowserSelectSpecificDeck(:final id, :final deckNameId):
      lastDeckId = id;
      deckFilter = List.unmodifiable([deckNameId]);
  }

  final currentFilters = currentRequest.filters;
  final updatedRequest = BrowserSearchRequest(
    query: currentRequest.query,
    filters: BrowserSearchFilters(
      decks: deckFilter,
      flags: currentFilters.flags,
      tags: currentFilters.tags,
      noteTypes: currentFilters.noteTypes,
      cardStateCodes: currentFilters.cardStateCodes,
    ),
  );
  return BrowserSelectedDeckUpdatePlan(
    lastDeckId: lastDeckId,
    deckFilter: deckFilter,
    updatedRequest: updatedRequest,
  );
}
