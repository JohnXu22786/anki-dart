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
 * Behavioral reference: `syncState` and `resetSearchState` in
 * CardBrowserSearchViewModel.kt, AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'browser_filter_update.dart';
import 'browser_search_request.dart';
import 'browser_search_text_state.dart';

/// A single ordered effect from Card Browser search synchronization/reset.
///
/// The host executes these effects against its StateFlows and SavedStateHandle.
/// This model preserves source order and does not schedule or execute them.
sealed class BrowserSearchStateEffect {
  const BrowserSearchStateEffect();
}

/// Publishes a System-originated filter update.
final class BrowserFilterUpdateEffect extends BrowserSearchStateEffect {
  const BrowserFilterUpdateEffect(this.update);

  final BrowserFilterUpdate update;
}

/// Submits the exact search request supplied to the source method.
final class BrowserSearchSubmittedEffect extends BrowserSearchStateEffect {
  const BrowserSearchSubmittedEffect(this.search);

  final BrowserSearchRequest search;
}

/// Sets Basic/Advanced mode; reset sets [enabled] to false.
final class BrowserAdvancedSearchModeEffect extends BrowserSearchStateEffect {
  const BrowserAdvancedSearchModeEffect({required this.enabled});

  final bool enabled;
}

/// Sets the Basic search text without normalization.
final class BrowserBasicSearchTextEffect extends BrowserSearchStateEffect {
  const BrowserBasicSearchTextEffect(this.text);

  final String text;
}

/// Sets the Advanced search text without normalization.
final class BrowserAdvancedSearchTextEffect extends BrowserSearchStateEffect {
  const BrowserAdvancedSearchTextEffect(this.text);

  final String text;
}

/// Sets whether the Card Browser search screen is open.
final class BrowserSearchScreenOpenEffect extends BrowserSearchStateEffect {
  const BrowserSearchScreenOpenEffect({required this.isOpen});

  final bool isOpen;
}

/// Removes one SavedStateHandle entry after reset's flow updates.
final class BrowserSavedStateKeyRemovalEffect extends BrowserSearchStateEffect {
  const BrowserSavedStateKeyRemovalEffect(this.key);

  final String key;
}

const browserAdvancedSearchStateKey = 'advancedSearch';
const browserBasicSearchTextStateKey = 'basicSearchText';
const browserAdvancedSearchTextStateKey = 'advancedSearchText';

/// Projects AnkiDroid's `syncState` calls in their source order.
///
/// It emits a System filter update and then the exact request submission. It
/// emits no text, screen-open, history-expanded, or SavedStateHandle effects.
List<BrowserSearchStateEffect> browserSyncStateEffects(
  BrowserSearchRequest search,
) =>
    List.unmodifiable([
      BrowserFilterUpdateEffect(
        BrowserFilterUpdateSystem(search.filters),
      ),
      BrowserSearchSubmittedEffect(search),
    ]);

/// Projects `resetSearchState` calls in their source order.
///
/// Query text is copied verbatim. The source removes three SavedStateHandle
/// keys after updating flows and closing the screen; `historyExpanded` is not
/// among them. The host owns the actual StateFlow and SavedStateHandle writes.
List<BrowserSearchStateEffect> browserResetSearchStateEffects(
  BrowserSearchRequest submittedSearch,
) =>
    List.unmodifiable([
      const BrowserAdvancedSearchModeEffect(enabled: false),
      BrowserBasicSearchTextEffect(submittedSearch.query),
      BrowserAdvancedSearchTextEffect(submittedSearch.query),
      BrowserFilterUpdateEffect(
        BrowserFilterUpdateSystem(submittedSearch.filters),
      ),
      const BrowserSearchScreenOpenEffect(isOpen: false),
      const BrowserSavedStateKeyRemovalEffect(browserAdvancedSearchStateKey),
      const BrowserSavedStateKeyRemovalEffect(
        browserBasicSearchTextStateKey,
      ),
      const BrowserSavedStateKeyRemovalEffect(
        browserAdvancedSearchTextStateKey,
      ),
    ]);

/// Applies only a text-related effect to the current headless text snapshot.
///
/// Non-text effects leave [state] unchanged; Android hosts still apply every
/// effect in sequence to their own state holders.
BrowserSearchTextState browserSearchTextStateAfterEffect(
  BrowserSearchTextState state,
  BrowserSearchStateEffect effect,
) =>
    switch (effect) {
      BrowserAdvancedSearchModeEffect(:final enabled) => BrowserSearchTextState(
          isAdvancedSearch: enabled,
          basicText: state.basicText,
          advancedText: state.advancedText,
        ),
      BrowserBasicSearchTextEffect(:final text) => BrowserSearchTextState(
          isAdvancedSearch: state.isAdvancedSearch,
          basicText: text,
          advancedText: state.advancedText,
        ),
      BrowserAdvancedSearchTextEffect(:final text) => BrowserSearchTextState(
          isAdvancedSearch: state.isAdvancedSearch,
          basicText: state.basicText,
          advancedText: text,
        ),
      _ => state,
    };
