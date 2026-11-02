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
 * Behavioral reference: CardBrowserSearchViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'browser_saved_searches.dart';
import 'browser_search_history_display.dart';

/// Whether AnkiDroid's search-history availability projection is true.
///
/// The source checks the `entryToSearchString` list, including Loading pairs
/// whose search strings are null. The host owns the StateFlow that supplies
/// [items] and renders any availability-dependent controls.
bool browserSearchHistoryIsAvailable(BrowserSearchHistoryItems items) =>
    items.isNotEmpty();

/// Whether the Card Browser has any saved searches to manage.
///
/// This mirrors `savedSearches.isNotEmpty()` over a host-supplied snapshot; it
/// does not load or mutate saved-search storage.
bool browserCanManageSavedSearches(List<BrowserSavedSearch> savedSearches) =>
    savedSearches.isNotEmpty;
