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
 * Behavioral reference: CardBrowserViewModel.setQuery() in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'browser_search_request.dart';

/// One ordered host action from a Card Browser query plan.
sealed class BrowserSetQueryDirective {
  const BrowserSetQueryDirective();
}

/// Assigns the request whose query was copied from the current request.
final class BrowserUpdateQuerySearchRequestDirective
    extends BrowserSetQueryDirective {
  const BrowserUpdateQuerySearchRequestDirective(this.request);

  final BrowserSearchRequest request;
}

/// Requests the source search with its exact refresh and user-search values.
final class BrowserRequestQuerySearchDirective
    extends BrowserSetQueryDirective {
  const BrowserRequestQuerySearchDirective({
    required this.request,
    required this.forceRefresh,
    required this.fromUserSearch,
  });

  final BrowserSearchRequest request;
  final bool forceRefresh;
  final bool fromUserSearch;
}

/// The source-ordered request assignment and search actions for `setQuery()`.
final class BrowserSetQueryPlan {
  BrowserSetQueryPlan({
    required this.updatedRequest,
    required this.forceRefresh,
    required this.fromUserSearch,
  }) : directives = List.unmodifiable([
         BrowserUpdateQuerySearchRequestDirective(updatedRequest),
         BrowserRequestQuerySearchDirective(
           request: updatedRequest,
           forceRefresh: forceRefresh,
           fromUserSearch: fromUserSearch,
         ),
       ]);

  final BrowserSearchRequest updatedRequest;
  final bool forceRefresh;
  final bool fromUserSearch;
  final List<BrowserSetQueryDirective> directives;
}

/// Projects the pure gate and direct effects inside `setQuery()`.
///
/// The host supplies whether the current and query-copied requests have equal
/// serialized SearchStrings. This result must come from Anki's backend; Dart
/// request or query equality is not equivalent. When refresh is not forced and
/// the host reports equality, this returns null without assignment or search.
/// Otherwise it returns the copied request and the source-ordered assignment
/// and search request. The host owns request state, serialization, collection
/// access, search execution, and coroutine/cancellation behavior.
BrowserSetQueryPlan? planBrowserSetQuery({
  required BrowserSearchRequest currentRequest,
  required String query,
  required bool forceRefresh,
  required bool serializedSearchStringsEqual,
  required bool fromUserSearch,
}) {
  if (!forceRefresh && serializedSearchStringsEqual) return null;

  final updatedRequest = BrowserSearchRequest(
    query: query,
    filters: currentRequest.filters,
  );
  return BrowserSetQueryPlan(
    updatedRequest: updatedRequest,
    forceRefresh: forceRefresh,
    fromUserSearch: fromUserSearch,
  );
}
