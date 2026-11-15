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
 * Behavioral reference: CardBrowserViewModel.filterByTags() and
 * setFilterQuery() in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'browser_filter_tags_query.dart';
import 'browser_search_request.dart';

/// One ordered host action from a Card Browser tag-filter search plan.
sealed class BrowserTagFilterSearchDirective {
  const BrowserTagFilterSearchDirective();
}

/// Emits `flowOfFilterQuery` with the parenthesized backend query.
final class BrowserEmitTagFilterQueryDirective
    extends BrowserTagFilterSearchDirective {
  const BrowserEmitTagFilterQueryDirective(this.query);

  final String query;
}

/// Assigns the current request copied with the tag-filter query.
final class BrowserUpdateTagFilterSearchRequestDirective
    extends BrowserTagFilterSearchDirective {
  const BrowserUpdateTagFilterSearchRequestDirective(this.request);

  final BrowserSearchRequest request;
}

/// Requests the source's default refresh search for the updated request.
final class BrowserRequestTagFilterSearchDirective
    extends BrowserTagFilterSearchDirective {
  const BrowserRequestTagFilterSearchDirective({
    required this.request,
    required this.forceRefresh,
    required this.fromUserSearch,
  });

  final BrowserSearchRequest request;
  final bool forceRefresh;
  final bool fromUserSearch;
}

/// The source-ordered values and actions from `filterByTags()`.
final class BrowserTagFilterSearchPlan {
  BrowserTagFilterSearchPlan({
    required this.query,
    required this.updatedRequest,
  }) : directives = List.unmodifiable([
         BrowserEmitTagFilterQueryDirective(query),
         BrowserUpdateTagFilterSearchRequestDirective(updatedRequest),
         BrowserRequestTagFilterSearchDirective(
           request: updatedRequest,
           forceRefresh: true,
           fromUserSearch: false,
         ),
       ]);

  final String query;
  final BrowserSearchRequest updatedRequest;
  final List<BrowserTagFilterSearchDirective> directives;
}

/// Projects `filterByTags()` from a host-resolved backend search string and
/// the current request.
///
/// The plan parenthesizes the exact backend string, emits it, copies it into
/// the request while retaining structured filters, then requests a default
/// refresh search in source order. The host constructs and serializes the
/// `SearchRequest`, emits the flow, updates request state, and performs search;
/// this function does not perform those effects.
BrowserTagFilterSearchPlan planBrowserTagFilterSearch({
  required String resolvedSearchString,
  required BrowserSearchRequest currentRequest,
}) {
  final query = browserFilterTagsQuery(resolvedSearchString);
  final updatedRequest = BrowserSearchRequest(
    query: query,
    filters: currentRequest.filters,
  );
  return BrowserTagFilterSearchPlan(
    query: query,
    updatedRequest: updatedRequest,
  );
}
