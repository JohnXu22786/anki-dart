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
 * Behavioral reference: BrowserColumnSelectionFragment.kt and
 * CardBrowserViewModel.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'browser_column_collection.dart';

/// The host-facing effects emitted by the column-selection save handler.
enum BrowserColumnSelectionSaveEffect {
  dismissDialog,
  showNoColumnsMessage,
}

/// The inputs the host passes to `updateActiveColumns` after the pre-effects.
final class BrowserColumnSelectionSaveRequest {
  BrowserColumnSelectionSaveRequest({
    required List<BrowserColumn> columns,
    required this.mode,
  }) : columns = List<BrowserColumn>.unmodifiable(columns);

  final List<BrowserColumn> columns;
  final BrowserColumnMode mode;
}

/// The ordered completion effects and Boolean returned by the source handler.
final class BrowserColumnSelectionSaveOutcome {
  BrowserColumnSelectionSaveOutcome({
    required List<BrowserColumnSelectionSaveEffect> effects,
    required this.returnedValue,
  }) : effects = List<BrowserColumnSelectionSaveEffect>.unmodifiable(effects);

  final List<BrowserColumnSelectionSaveEffect> effects;
  final bool returnedValue;
}

/// The first stage of the save handler, before the host updates its columns.
///
/// The source dismisses immediately when the selected values equal the initial
/// values, but deliberately falls through and still calls
/// `updateActiveColumns`. The host executes [effectsBeforeUpdate], then supplies
/// that method's Boolean result to [complete].
final class BrowserColumnSelectionSavePlan {
  BrowserColumnSelectionSavePlan({
    required List<BrowserColumn> initialSelectedColumns,
    required List<BrowserColumn> selectedColumns,
    required BrowserColumnMode mode,
  })  : initialSelectedColumns =
            List<BrowserColumn>.unmodifiable(initialSelectedColumns),
        selectedColumns = List<BrowserColumn>.unmodifiable(selectedColumns),
        updateRequest = BrowserColumnSelectionSaveRequest(
          columns: selectedColumns,
          mode: mode,
        ),
        hasUnsavedChanges =
            !_sameOrderedColumns(initialSelectedColumns, selectedColumns),
        effectsBeforeUpdate =
            _sameOrderedColumns(initialSelectedColumns, selectedColumns)
                ? const [BrowserColumnSelectionSaveEffect.dismissDialog]
                : const [];

  final List<BrowserColumn> initialSelectedColumns;
  final List<BrowserColumn> selectedColumns;
  final BrowserColumnSelectionSaveRequest updateRequest;
  final bool hasUnsavedChanges;
  final List<BrowserColumnSelectionSaveEffect> effectsBeforeUpdate;

  /// Maps the host's `updateActiveColumns` result to the remaining source
  /// effects and the handler's return value.
  BrowserColumnSelectionSaveOutcome complete(bool updateSucceeded) =>
      BrowserColumnSelectionSaveOutcome(
        effects: [
          updateSucceeded
              ? BrowserColumnSelectionSaveEffect.dismissDialog
              : BrowserColumnSelectionSaveEffect.showNoColumnsMessage,
        ],
        returnedValue: updateSucceeded,
      );
}

/// Plans the source save-handler transition from a pair of ordered selections.
///
/// Lists are snapshotted because the Kotlin handler receives its initial and
/// displayed selections as materialized `List` values. The host owns applying
/// effects, updating preferences/backend state, and dialog/snackbar delivery.
BrowserColumnSelectionSavePlan planBrowserColumnSelectionSave({
  required List<BrowserColumn> initialSelectedColumns,
  required List<BrowserColumn> selectedColumns,
  required BrowserColumnMode mode,
}) =>
    BrowserColumnSelectionSavePlan(
      initialSelectedColumns: initialSelectedColumns,
      selectedColumns: selectedColumns,
      mode: mode,
    );

bool _sameOrderedColumns(List<BrowserColumn> left, List<BrowserColumn> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
