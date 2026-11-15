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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'browser_column_collection.dart';

/// The host-side load and update requests from `refreshColumnsFromPrefs`.
final class BrowserRefreshColumnsFromPrefsPlan {
  const BrowserRefreshColumnsFromPrefsPlan({
    required this.shouldLoadPreferences,
    required this.shouldUpdateActiveColumns,
    required this.columnsToUpdate,
  });

  final bool shouldLoadPreferences;
  final bool shouldUpdateActiveColumns;

  /// The loaded columns to pass to the host update, or null when no update is
  /// requested.
  final List<BrowserColumn>? columnsToUpdate;
}

/// Plans the source initialization guard and ordered comparison after loading.
///
/// Call once without [storedColumns] to decide whether the host should load its
/// mode-specific preferences. After loading, call again with those columns to
/// decide whether the host should request `updateActiveColumns`. This keeps
/// preference access and the update itself on the host, while retaining the
/// source's ordered structural comparison.
BrowserRefreshColumnsFromPrefsPlan planBrowserRefreshColumnsFromPrefs({
  required bool initCompleted,
  required List<BrowserColumn> activeColumns,
  List<BrowserColumn>? storedColumns,
}) {
  if (!initCompleted) {
    return const BrowserRefreshColumnsFromPrefsPlan(
      shouldLoadPreferences: false,
      shouldUpdateActiveColumns: false,
      columnsToUpdate: null,
    );
  }

  if (storedColumns == null) {
    return const BrowserRefreshColumnsFromPrefsPlan(
      shouldLoadPreferences: true,
      shouldUpdateActiveColumns: false,
      columnsToUpdate: null,
    );
  }

  final changed = !_sameOrderedColumns(activeColumns, storedColumns);
  return BrowserRefreshColumnsFromPrefsPlan(
    shouldLoadPreferences: false,
    shouldUpdateActiveColumns: changed,
    columnsToUpdate: changed ? storedColumns : null,
  );
}

bool _sameOrderedColumns(List<BrowserColumn> left, List<BrowserColumn> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
