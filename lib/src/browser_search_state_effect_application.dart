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
 * Source-derived from `syncState` and `resetSearchState` in
 * CardBrowserSearchViewModel.kt, AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'browser_filter_update.dart';
import 'browser_search_request.dart';
import 'browser_search_state_effects.dart';

/// Synchronous host callbacks for applying `resetSearchState` effects.
///
/// The host implements StateFlow and SavedStateHandle writes. Callbacks run
/// immediately in source order; an error propagates and stops later callbacks.
final class BrowserResetSearchStateCallbacks {
  const BrowserResetSearchStateCallbacks({
    required this.setAdvancedSearchMode,
    required this.setBasicSearchText,
    required this.setAdvancedSearchText,
    required this.updateSystemFilters,
    required this.setSearchScreenOpen,
    required this.removeSavedStateKey,
  });

  final void Function(bool enabled) setAdvancedSearchMode;
  final void Function(String text) setBasicSearchText;
  final void Function(String text) setAdvancedSearchText;
  final void Function(BrowserSearchFilters filters) updateSystemFilters;
  final void Function(bool isOpen) setSearchScreenOpen;
  final void Function(String key) removeSavedStateKey;
}

/// Applies `resetSearchState` through immediate host state callbacks.
///
/// It reuses [browserResetSearchStateEffects] so the modeled plan remains the
/// source of callback values and ordering. Android state holders and persistence
/// remain with the host.
void browserResetSearchState(
  BrowserSearchRequest submittedSearch, {
  required BrowserResetSearchStateCallbacks callbacks,
}) {
  for (final effect in browserResetSearchStateEffects(submittedSearch)) {
    switch (effect) {
      case BrowserAdvancedSearchModeEffect(:final enabled):
        callbacks.setAdvancedSearchMode(enabled);
      case BrowserBasicSearchTextEffect(:final text):
        callbacks.setBasicSearchText(text);
      case BrowserAdvancedSearchTextEffect(:final text):
        callbacks.setAdvancedSearchText(text);
      case BrowserFilterUpdateEffect(:final update):
        if (update case BrowserFilterUpdateSystem(:final state)) {
          callbacks.updateSystemFilters(state);
        } else {
          throw StateError('Expected a System filter update during reset.');
        }
      case BrowserSearchScreenOpenEffect(:final isOpen):
        callbacks.setSearchScreenOpen(isOpen);
      case BrowserSavedStateKeyRemovalEffect(:final key):
        callbacks.removeSavedStateKey(key);
      case _:
        throw StateError('Unexpected effect in browser reset plan: $effect');
    }
  }
}

/// Asynchronous host callbacks for applying `syncState` effects.
///
/// The filter update and submitted request are awaited in source order. A
/// callback error propagates and prevents every later callback.
final class BrowserSyncSearchStateCallbacks {
  const BrowserSyncSearchStateCallbacks({
    required this.updateSystemFilters,
    required this.submitSearch,
  });

  final Future<void> Function(BrowserSearchFilters filters) updateSystemFilters;
  final Future<void> Function(BrowserSearchRequest search) submitSearch;
}

/// Applies `syncState` through sequential asynchronous host callbacks.
///
/// It reuses [browserSyncStateEffects] to preserve the exact request and filter
/// objects. The host owns coroutine scheduling, collection access, and search
/// execution.
Future<void> browserSyncSearchState(
  BrowserSearchRequest search, {
  required BrowserSyncSearchStateCallbacks callbacks,
}) async {
  for (final effect in browserSyncStateEffects(search)) {
    switch (effect) {
      case BrowserFilterUpdateEffect(:final update):
        if (update case BrowserFilterUpdateSystem(:final state)) {
          await callbacks.updateSystemFilters(state);
        } else {
          throw StateError('Expected a System filter update during sync.');
        }
      case BrowserSearchSubmittedEffect(:final search):
        await callbacks.submitSearch(search);
      case _:
        throw StateError('Unexpected effect in browser sync plan: $effect');
    }
  }
}
