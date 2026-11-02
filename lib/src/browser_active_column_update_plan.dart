/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
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

/// The guard and host update requests from `updateActiveColumns`.
final class BrowserActiveColumnUpdatePlan {
  const BrowserActiveColumnUpdatePlan({
    required this.returnedValue,
    required this.shouldPersist,
    required this.shouldUpdateActiveFlow,
  });

  final bool returnedValue;
  final bool shouldPersist;
  final bool shouldUpdateActiveFlow;
}

/// Plans the source's empty/equal guards and active-mode flow update request.
///
/// The equality check is ordered and structural like Kotlin `List.equals`.
/// The host performs `BrowserColumnCollection.replace` and preference writes,
/// then applies an active-flow update when [shouldUpdateActiveFlow] is true.
BrowserActiveColumnUpdatePlan planBrowserActiveColumnUpdate({
  required List<BrowserColumn> currentActiveColumns,
  required List<BrowserColumn> requestedColumns,
  required BrowserColumnMode currentMode,
  required BrowserColumnMode targetMode,
}) {
  if (requestedColumns.isEmpty) {
    return const BrowserActiveColumnUpdatePlan(
      returnedValue: false,
      shouldPersist: false,
      shouldUpdateActiveFlow: false,
    );
  }
  if (_sameOrderedColumns(currentActiveColumns, requestedColumns)) {
    return const BrowserActiveColumnUpdatePlan(
      returnedValue: false,
      shouldPersist: false,
      shouldUpdateActiveFlow: false,
    );
  }

  return BrowserActiveColumnUpdatePlan(
    returnedValue: true,
    shouldPersist: true,
    shouldUpdateActiveFlow: targetMode == currentMode,
  );
}

bool _sameOrderedColumns(List<BrowserColumn> left, List<BrowserColumn> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
