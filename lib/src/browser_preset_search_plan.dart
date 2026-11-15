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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserViewModel.searchForMarkedNotes(),
 * searchForSuspendedCards(), setFilterQuery(), and launchSearchForCards() in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'browser_search_request.dart';

/// A Card Browser query preset that searches marked notes or suspended cards.
enum BrowserPresetSearch { markedNotes, suspendedCards }

/// One ordered host action from a marked/suspended preset search plan.
sealed class BrowserPresetSearchDirective {
  const BrowserPresetSearchDirective();
}

/// Emits `flowOfFilterQuery` with the selected preset query.
final class BrowserEmitPresetFilterQueryDirective
    extends BrowserPresetSearchDirective {
  const BrowserEmitPresetFilterQueryDirective(this.query);

  final String query;
}

/// Replaces the host's current request with its query copied to the preset.
final class BrowserUpdatePresetSearchRequestDirective
    extends BrowserPresetSearchDirective {
  const BrowserUpdatePresetSearchRequestDirective(this.request);

  final BrowserSearchRequest request;
}

/// Requests the source's default refresh search for the prepared request.
final class BrowserRequestPresetSearchDirective
    extends BrowserPresetSearchDirective {
  const BrowserRequestPresetSearchDirective({
    required this.request,
    required this.forceRefresh,
    required this.fromUserSearch,
  });

  final BrowserSearchRequest request;
  final bool forceRefresh;
  final bool fromUserSearch;
}

/// The source-ordered values and actions for a preset search.
final class BrowserPresetSearchPlan {
  BrowserPresetSearchPlan({
    required this.query,
    required this.updatedRequest,
  }) : directives = List.unmodifiable([
         BrowserEmitPresetFilterQueryDirective(query),
         BrowserUpdatePresetSearchRequestDirective(updatedRequest),
         BrowserRequestPresetSearchDirective(
           request: updatedRequest,
           forceRefresh: true,
           fromUserSearch: false,
         ),
       ]);

  final String query;
  final BrowserSearchRequest updatedRequest;
  final List<BrowserPresetSearchDirective> directives;
}

/// Projects `searchForMarkedNotes()` or `searchForSuspendedCards()`.
///
/// The host supplies whether any rows are selected and the current request. A
/// selection returns null before producing effects. Otherwise the plan emits
/// the legacy filter query, updates the request with that query, and requests
/// a default refresh search in source order. The host emits the SharedFlow,
/// updates its request state, and performs the search; this function does not
/// access selection state, flows, or the collection.
BrowserPresetSearchPlan? planBrowserPresetSearch({
  required BrowserPresetSearch preset,
  required bool hasSelectedRows,
  required BrowserSearchRequest currentRequest,
}) {
  if (hasSelectedRows) return null;

  final query = switch (preset) {
    BrowserPresetSearch.markedNotes => 'tag:marked',
    BrowserPresetSearch.suspendedCards => 'is:suspended',
  };
  final updatedRequest = BrowserSearchRequest(
    query: query,
    filters: currentRequest.filters,
  );
  return BrowserPresetSearchPlan(
    query: query,
    updatedRequest: updatedRequest,
  );
}
