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
 * Behavioral reference: CardBrowserViewModel.setFlagFilter() and
 * setFilterQuery() in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'browser_flag_filter_query.dart';
import 'browser_search_request.dart';

/// One ordered host action from a Card Browser flag-filter search plan.
sealed class BrowserFlagFilterSearchDirective {
  const BrowserFlagFilterSearchDirective();
}

/// Emits `flowOfFilterQuery` with the transformed flag query.
final class BrowserEmitFlagFilterQueryDirective
    extends BrowserFlagFilterSearchDirective {
  const BrowserEmitFlagFilterQueryDirective(this.query);

  final String query;
}

/// Assigns the current request copied with the flag query.
final class BrowserUpdateFlagFilterSearchRequestDirective
    extends BrowserFlagFilterSearchDirective {
  const BrowserUpdateFlagFilterSearchRequestDirective(this.request);

  final BrowserSearchRequest request;
}

/// Requests the source's default refresh search for the updated request.
final class BrowserRequestFlagFilterSearchDirective
    extends BrowserFlagFilterSearchDirective {
  const BrowserRequestFlagFilterSearchDirective({
    required this.request,
    required this.forceRefresh,
    required this.fromUserSearch,
  });

  final BrowserSearchRequest request;
  final bool forceRefresh;
  final bool fromUserSearch;
}

/// The source-ordered values and actions for `setFlagFilter()`.
final class BrowserFlagFilterSearchPlan {
  BrowserFlagFilterSearchPlan({
    required this.query,
    required this.updatedRequest,
  }) : directives = List.unmodifiable([
         BrowserEmitFlagFilterQueryDirective(query),
         BrowserUpdateFlagFilterSearchRequestDirective(updatedRequest),
         BrowserRequestFlagFilterSearchDirective(
           request: updatedRequest,
           forceRefresh: true,
           fromUserSearch: false,
         ),
       ]);

  final String query;
  final BrowserSearchRequest updatedRequest;
  final List<BrowserFlagFilterSearchDirective> directives;
}

/// Projects `setFlagFilter()` from its host-supplied current search terms,
/// flag code, and request.
///
/// The query uses [browserSearchTermsWithFlag] on [searchTerms] exactly, then
/// the plan emits the query, copies it into the current request while retaining
/// its structured filters, and requests a default refresh search. The host owns
/// flag resolution, Flow emission, request-state mutation, search execution,
/// and UI; this function does not perform those effects.
BrowserFlagFilterSearchPlan planBrowserFlagFilterSearch({
  required String searchTerms,
  required int flagCode,
  required BrowserSearchRequest currentRequest,
}) {
  final query = browserSearchTermsWithFlag(
    searchTerms: searchTerms,
    flagCode: flagCode,
  );
  final updatedRequest = BrowserSearchRequest(
    query: query,
    filters: currentRequest.filters,
  );
  return BrowserFlagFilterSearchPlan(
    query: query,
    updatedRequest: updatedRequest,
  );
}
