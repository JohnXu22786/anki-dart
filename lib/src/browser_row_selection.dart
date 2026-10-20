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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'dart:collection';

import 'browser_row_collection.dart';

/// The row and adapter offset carried by AnkiDroid's `RowSelection` value.
final class BrowserRowSelection {
  const BrowserRowSelection({required this.rowId, required this.topOffset});

  final BrowserRowId rowId;
  final int topOffset;

  @override
  bool operator ==(Object other) =>
      other is BrowserRowSelection &&
      other.rowId == rowId &&
      other.topOffset == topOffset;

  @override
  int get hashCode => Object.hash(rowId, topOffset);
}

/// The source mode-change variants produced by a row selection toggle.
enum BrowserRowSelectionModeCause { rowSelected, deselectRow }

/// A source `ChangeMultiSelectMode` cause associated with a row toggle.
final class BrowserRowSelectionModeChange {
  const BrowserRowSelectionModeChange({
    required this.cause,
    required this.selection,
  });

  final BrowserRowSelectionModeCause cause;
  final BrowserRowSelection selection;

  bool get resultedInMultiSelect =>
      cause == BrowserRowSelectionModeCause.rowSelected;

  @override
  bool operator ==(Object other) =>
      other is BrowserRowSelectionModeChange &&
      other.cause == cause &&
      other.selection == selection;

  @override
  int get hashCode => Object.hash(cause, selection);
}

/// The immutable result of toggling one row in the selected-row set.
final class BrowserRowSelectionTransition {
  BrowserRowSelectionTransition._({
    required Iterable<BrowserRowId> selectedRows,
    required this.modeChange,
    required this.isInMultiSelectMode,
    required this.lastSelectedRowId,
  }) : selectedRows = List.unmodifiable(selectedRows);

  /// Selected IDs in the source `LinkedHashSet` iteration order.
  final List<BrowserRowId> selectedRows;

  /// Null when removing a row leaves other selected rows and the source emits
  /// no mode-change value.
  final BrowserRowSelectionModeChange? modeChange;

  /// The mode after any source mode-change event, or the previous mode if there
  /// is no event.
  final bool isInMultiSelectMode;

  /// `toggleRowSelection` updates this to the toggled row after every action.
  final BrowserRowId lastSelectedRowId;

  /// Every source row toggle asks the selected-row flow to refresh.
  bool get refreshSelectedRows => true;
}

/// Projects the selection-set and mode effects of AnkiDroid's row toggle.
///
/// [selectedRows] is a snapshot in source insertion order. As with the source
/// `LinkedHashSet`, duplicate IDs in the supplied iterable collapse to one row.
/// The returned list is a new immutable snapshot; the input is not mutated.
BrowserRowSelectionTransition toggleBrowserRowSelection({
  required Iterable<BrowserRowId> selectedRows,
  required BrowserRowSelection selection,
  required bool isInMultiSelectMode,
}) {
  final nextSelectedRows = LinkedHashSet<BrowserRowId>.of(selectedRows);
  final wasSelected = nextSelectedRows.remove(selection.rowId);

  final BrowserRowSelectionModeChange? modeChange;
  if (wasSelected) {
    if (nextSelectedRows.isEmpty) {
      modeChange = BrowserRowSelectionModeChange(
        cause: BrowserRowSelectionModeCause.deselectRow,
        selection: selection,
      );
    } else {
      modeChange = null;
    }
  } else {
    nextSelectedRows.add(selection.rowId);
    modeChange = BrowserRowSelectionModeChange(
      cause: BrowserRowSelectionModeCause.rowSelected,
      selection: selection,
    );
  }

  return BrowserRowSelectionTransition._(
    selectedRows: nextSelectedRows,
    modeChange: modeChange,
    isInMultiSelectMode:
        modeChange?.resultedInMultiSelect ?? isInMultiSelectMode,
    lastSelectedRowId: selection.rowId,
  );
}

/// The action selected by AnkiDroid's cached toggle-selection flow value.
enum BrowserSelectAllOrNoneState { selectAll, selectNone }

/// Ordered asynchronous effects after a bulk selection mutates its row set.
enum BrowserBulkSelectionEffect {
  /// Corresponds to assigning `MultiSelectCause.Other` before refreshing rows.
  emitMultiSelectOther,

  /// Corresponds to emitting the selected-row refresh signal.
  refreshSelectedRows,
}

/// The pure result of a Card Browser select-all/select-none operation.
final class BrowserBulkSelectionTransition {
  BrowserBulkSelectionTransition._({
    required Iterable<BrowserRowId> selectedRows,
    required Iterable<BrowserRowId>? previouslySelectedRows,
    required this.changed,
    required this.isInMultiSelectMode,
    required Iterable<BrowserBulkSelectionEffect> effects,
  })  : selectedRows = List.unmodifiable(selectedRows),
        previouslySelectedRows = previouslySelectedRows == null
            ? null
            : List.unmodifiable(previouslySelectedRows),
        effects = List.unmodifiable(effects);

  /// The rows after the source set mutation, in linked-set insertion order.
  final List<BrowserRowId> selectedRows;

  /// The copy captured by `selectNone()` before the source clears its set.
  /// This is null for select-all and for an empty select-none no-op.
  final List<BrowserRowId>? previouslySelectedRows;

  /// True when the source returns a refresh job; false for its early return.
  final bool changed;

  /// Mode after source mode effects, or the supplied mode when no mode effect
  /// is emitted. `selectNone()` deliberately retains an active mode.
  final bool isInMultiSelectMode;

  /// Effects after the synchronous row-set mutation, in source order.
  final List<BrowserBulkSelectionEffect> effects;
}

/// Projects `CardBrowserViewModel.selectAll()` over host-supplied row IDs.
///
/// The source mutates its internal `LinkedHashSet` in place. This pure model
/// returns an immutable snapshot instead: existing order is retained, new
/// distinct rows are appended in [availableRows] order, and duplicates are
/// collapsed as `Set.addAll()` does. The mode-change effect precedes refresh.
BrowserBulkSelectionTransition planBrowserSelectAll({
  required Iterable<BrowserRowId> selectedRows,
  required Iterable<BrowserRowId> availableRows,
  required bool isInMultiSelectMode,
}) {
  final nextRows = LinkedHashSet<BrowserRowId>.of(selectedRows);
  final originalLength = nextRows.length;
  nextRows.addAll(availableRows);
  final changed = nextRows.length != originalLength;

  return BrowserBulkSelectionTransition._(
    selectedRows: nextRows,
    previouslySelectedRows: null,
    changed: changed,
    isInMultiSelectMode: changed ? true : isInMultiSelectMode,
    effects: changed
        ? const [
            BrowserBulkSelectionEffect.emitMultiSelectOther,
            BrowserBulkSelectionEffect.refreshSelectedRows,
          ]
        : const [],
  );
}

/// Projects `CardBrowserViewModel.selectNone()` over the current ordered IDs.
///
/// The source snapshots the selected IDs and clears its mutable set before the
/// asynchronous refresh. It does not emit a mode change because it passes
/// `disableMultiSelectIfEmpty: false` to its removal callback.
BrowserBulkSelectionTransition planBrowserSelectNone({
  required Iterable<BrowserRowId> selectedRows,
  required bool isInMultiSelectMode,
}) {
  final previousRows = LinkedHashSet<BrowserRowId>.of(selectedRows);
  if (previousRows.isEmpty) {
    return BrowserBulkSelectionTransition._(
      selectedRows: previousRows,
      previouslySelectedRows: null,
      changed: false,
      isInMultiSelectMode: isInMultiSelectMode,
      effects: const [],
    );
  }

  return BrowserBulkSelectionTransition._(
    selectedRows: const [],
    previouslySelectedRows: previousRows,
    changed: true,
    isInMultiSelectMode: isInMultiSelectMode,
    effects: const [BrowserBulkSelectionEffect.refreshSelectedRows],
  );
}

/// Dispatches to the source operation indicated by the current cached flow
/// state. The host supplies that state because StateFlow scheduling is outside
/// this pure model.
BrowserBulkSelectionTransition planBrowserToggleSelectAllOrNone({
  required BrowserSelectAllOrNoneState state,
  required Iterable<BrowserRowId> selectedRows,
  required Iterable<BrowserRowId> availableRows,
  required bool isInMultiSelectMode,
}) =>
    switch (state) {
      BrowserSelectAllOrNoneState.selectAll => planBrowserSelectAll(
          selectedRows: selectedRows,
          availableRows: availableRows,
          isInMultiSelectMode: isInMultiSelectMode,
        ),
      BrowserSelectAllOrNoneState.selectNone => planBrowserSelectNone(
          selectedRows: selectedRows,
          isInMultiSelectMode: isInMultiSelectMode,
        ),
    };
