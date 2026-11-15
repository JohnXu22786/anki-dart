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

/// Host callbacks for the full `updateActiveColumns` boundary.
///
/// SharedPreferences, coroutine scheduling, backend access, and StateFlow stay
/// host-owned. The callbacks make their source order explicit for portable
/// hosts: read and save the selected mode's columns, schedule an active-mode
/// update, then set backend keys before publishing the active columns.
final class BrowserActiveColumnUpdateCallbacks {
  const BrowserActiveColumnUpdateCallbacks({
    required this.readPreference,
    required this.defaultColumnKeys,
    required this.writePreference,
    required this.scheduleActiveUpdate,
    required this.setBackendActiveColumns,
    required this.publishActiveColumns,
  });

  final Future<String?> Function(BrowserColumnMode mode) readPreference;
  final List<String> Function(BrowserColumnMode mode) defaultColumnKeys;
  final Future<void> Function(BrowserColumnMode mode, String value)
  writePreference;
  final void Function(Future<void> Function() update) scheduleActiveUpdate;
  final Future<void> Function(Iterable<String> keys) setBackendActiveColumns;
  final void Function(BrowserColumnCollection columns) publishActiveColumns;
}

/// Applies the portable callback boundary for `CardBrowserViewModel.updateActiveColumns`.
///
/// Empty and structurally unchanged requests return before touching preference
/// callbacks. Accepted requests load and persist the target mode's ordered
/// columns. When updating the current mode, the scheduled host task awaits the
/// backend write before publishing; a backend error therefore suppresses the
/// publication. The host scheduler owns when that task runs and how its error
/// is delivered.
Future<bool> updateBrowserActiveColumns({
  required List<BrowserColumn> currentActiveColumns,
  required List<BrowserColumn> requestedColumns,
  required BrowserColumnMode currentMode,
  required BrowserColumnMode targetMode,
  required BrowserActiveColumnUpdateCallbacks callbacks,
}) async {
  final plan = planBrowserActiveColumnUpdate(
    currentActiveColumns: currentActiveColumns,
    requestedColumns: requestedColumns,
    currentMode: currentMode,
    targetMode: targetMode,
  );
  if (!plan.returnedValue) return false;

  final defaults = callbacks.defaultColumnKeys(targetMode);
  String? storedValue;
  try {
    storedValue = await callbacks.readPreference(targetMode);
  } on Exception {
    // BrowserColumnCollection.load logs the failure and falls back to defaults.
    // Logging stays with the host callback adapter.
  }
  final replacement = BrowserColumnCollection.replace(
    preferenceValue: storedValue,
    defaultColumnKeys: defaults,
    newColumns: requestedColumns,
  );
  await callbacks.writePreference(targetMode, replacement.preferenceValue);

  if (plan.shouldUpdateActiveFlow) {
    callbacks.scheduleActiveUpdate(() async {
      await callbacks.setBackendActiveColumns(
        replacement.newColumns.backendKeys,
      );
      callbacks.publishActiveColumns(replacement.newColumns);
    });
  }

  return true;
}
