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
 * Source-derived from CardBrowserSearchViewModel.kt initialization in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'browser_search_state_effects.dart';

const browserHistoryExpandedStateKey = 'historyExpanded';

/// The four host-supplied mutable flow objects bound by the source initializer.
///
/// The host retains SavedStateHandle and MutableStateFlow ownership.
final class BrowserSearchStateFlowBindings<BooleanFlow, StringFlow> {
  const BrowserSearchStateFlowBindings({
    required this.advancedSearch,
    required this.advancedSearchText,
    required this.basicSearchText,
    required this.historyExpanded,
  });

  final BooleanFlow advancedSearch;
  final StringFlow advancedSearchText;
  final StringFlow basicSearchText;
  final BooleanFlow historyExpanded;
}

/// Calls the host's typed flow factories in CardBrowserSearchViewModel order.
///
/// Each exact callback result is retained without copying. A callback error
/// propagates immediately, so no subsequent factory is invoked. The host owns
/// SavedStateHandle persistence, MutableStateFlow behavior, and lifecycle.
BrowserSearchStateFlowBindings<BooleanFlow, StringFlow>
bindBrowserSearchStateFlows<BooleanFlow, StringFlow>({
  required BooleanFlow Function(String key, bool defaultValue)
  getBooleanStateFlow,
  required StringFlow Function(String key, String defaultValue)
  getStringStateFlow,
}) {
  final advancedSearch = getBooleanStateFlow(
    browserAdvancedSearchStateKey,
    false,
  );
  final advancedSearchText = getStringStateFlow(
    browserAdvancedSearchTextStateKey,
    '',
  );
  final basicSearchText = getStringStateFlow(
    browserBasicSearchTextStateKey,
    '',
  );
  final historyExpanded = getBooleanStateFlow(
    browserHistoryExpandedStateKey,
    false,
  );

  return BrowserSearchStateFlowBindings(
    advancedSearch: advancedSearch,
    advancedSearchText: advancedSearchText,
    basicSearchText: basicSearchText,
    historyExpanded: historyExpanded,
  );
}
