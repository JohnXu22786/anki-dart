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

import 'browser_search_history.dart';

/// A history entry paired with its host-generated display search string.
typedef BrowserSearchHistoryDisplayEntry = ({
  BrowserSearchHistoryEntry entry,
  String? searchString,
});

/// The source view model's loading or loaded history shape.
sealed class BrowserSearchHistoryItems {
  const BrowserSearchHistoryItems();

  List<BrowserSearchHistoryDisplayEntry> get entryToSearchString;

  bool isNotEmpty() => entryToSearchString.isNotEmpty;

  /// Keeps this item's source variant while taking the first [max] entries.
  BrowserSearchHistoryItems truncated(int max);
}

/// History entries whose corresponding display search strings are not loaded.
final class BrowserSearchHistoryLoading extends BrowserSearchHistoryItems {
  const BrowserSearchHistoryLoading(this.input);

  final List<BrowserSearchHistoryEntry> input;

  @override
  List<BrowserSearchHistoryDisplayEntry> get entryToSearchString => [
        for (final entry in input) (entry: entry, searchString: null),
      ];

  @override
  BrowserSearchHistoryLoading truncated(int max) =>
      BrowserSearchHistoryLoading(input.take(max).toList());
}

/// History entries paired with their host-generated, possibly absent strings.
final class BrowserSearchHistoryLoaded extends BrowserSearchHistoryItems {
  const BrowserSearchHistoryLoaded(this.entryToSearchString);

  @override
  final List<BrowserSearchHistoryDisplayEntry> entryToSearchString;

  @override
  BrowserSearchHistoryLoaded truncated(int max) =>
      BrowserSearchHistoryLoaded(entryToSearchString.take(max).toList());
}

/// A headless projection of the Card Browser's visible history controls.
final class BrowserSearchHistoryDisplayProjection {
  const BrowserSearchHistoryDisplayProjection({
    required this.items,
    required this.showHistoryToggle,
  });

  final BrowserSearchHistoryItems items;
  final bool showHistoryToggle;
}

/// Collapsed/expanded history state and its five-item display projection.
///
/// The host supplies [BrowserSearchHistoryItems], including any converted
/// search strings. This model does not access Android state flows or widgets.
final class BrowserSearchHistoryDisplayModel {
  static const int maxCollapsedEntries = 5;

  bool _historyExpanded = false;

  bool get isHistoryExpanded => _historyExpanded;

  void toggleHistoryExpanded() {
    _historyExpanded = !_historyExpanded;
  }

  BrowserSearchHistoryDisplayProjection project(
    BrowserSearchHistoryItems items,
  ) =>
      BrowserSearchHistoryDisplayProjection(
        items: _historyExpanded ? items : items.truncated(maxCollapsedEntries),
        showHistoryToggle:
            items.entryToSearchString.length > maxCollapsedEntries,
      );
}
