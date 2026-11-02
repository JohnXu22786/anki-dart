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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ManageNoteTypesViewModel.deleteSelectedNoteTypes() in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'manage_note_types_state.dart';

/// The outcome returned by a host callback that owns the undoable removal.
sealed class ManageNoteTypeRemovalResult {
  const ManageNoteTypeRemovalResult();
}

/// Successful host result, retained unchanged for the undoable operation.
final class ManageNoteTypeRemovalSuccess extends ManageNoteTypeRemovalResult {
  const ManageNoteTypeRemovalSuccess(this.changes);

  final Object? changes;
}

/// A failed safe-removal result recorded for its captured row by the host.
final class ManageNoteTypeRemovalFailure extends ManageNoteTypeRemovalResult {
  const ManageNoteTypeRemovalFailure(this.throwable);

  final Object throwable;
}

/// One source-ordered label and throwable passed to the host error combiner.
final class ManageNoteTypeDeletionError {
  const ManageNoteTypeDeletionError(this.label, this.throwable);

  final String label;
  final Object throwable;
}

/// A host-facing execution plan for `deleteSelectedNoteTypes()`.
final class ManageNoteTypeDeletionPlan {
  const ManageNoteTypeDeletionPlan._({
    required this.selectedRows,
    required void Function(ManageNoteTypesState Function(ManageNoteTypesState))
    updateState,
    required Future<ManageNoteTypeRemovalResult> Function(NoteTypeItemState)
    remove,
    required Object? Function(List<ManageNoteTypeDeletionError>) combineErrors,
  }) : _updateState = updateState,
       _remove = remove,
       _combineErrors = combineErrors;

  /// The selected row values captured before the loading update.
  final List<NoteTypeItemState> selectedRows;
  final void Function(ManageNoteTypesState Function(ManageNoteTypesState))
  _updateState;
  final Future<ManageNoteTypeRemovalResult> Function(NoteTypeItemState) _remove;
  final Object? Function(List<ManageNoteTypeDeletionError>) _combineErrors;

  /// Sequentially runs removals, then filters the host's latest rows and
  /// publishes the combined error returned by its host-owned exception wrapper.
  ///
  /// Host callback failures are allowed to escape at their original boundary.
  Future<void> run({required ManageNoteTypesState Function() readState}) async {
    final errors =
        <_NoteTypeItemKey, ({NoteTypeItemState row, Object throwable})>{};
    for (final row in selectedRows) {
      final result = await _remove(row);
      switch (result) {
        case ManageNoteTypeRemovalSuccess():
          break;
        case ManageNoteTypeRemovalFailure(:final throwable):
          errors[_keyFor(row)] = (row: row, throwable: throwable);
      }
    }

    final failedIds = errors.values.map((error) => error.row.id).toSet();
    final successfulIds = selectedRows
        .map((row) => row.id)
        .where((id) => !failedIds.contains(id))
        .toSet();
    final updatedRows = readState().noteTypes
        .where((row) => !successfulIds.contains(row.id))
        .toList();
    final combinedError = _combineErrors([
      for (final entry in errors.values)
        ManageNoteTypeDeletionError(
          '${entry.row.name} - ${entry.throwable}',
          entry.throwable,
        ),
    ]);

    _updateState(
      (oldState) => oldState.copyWith(
        isLoading: false,
        noteTypes: updatedRows,
        error: combinedError,
      ),
    );
  }
}

/// Captures selected rows and synchronously publishes loading and deselection.
///
/// [remove] is called once per captured row in source list order. The host
/// callback owns `undoableOp`, `safeRemoveNoteType`, and default `OpChanges` for
/// a failed safe removal. [combineErrors] owns CombinedException and
/// ReportableException construction; it receives labels in failure-map order.
ManageNoteTypeDeletionPlan prepareManageNoteTypeDeletion({
  required ManageNoteTypesState initialState,
  required void Function(ManageNoteTypesState Function(ManageNoteTypesState))
  updateState,
  required Future<ManageNoteTypeRemovalResult> Function(NoteTypeItemState)
  remove,
  required Object? Function(List<ManageNoteTypeDeletionError>) combineErrors,
}) {
  final selectedRows = List<NoteTypeItemState>.unmodifiable(
    initialState.selectedNoteTypes,
  );
  updateState(
    (oldState) => oldState.copyWith(
      isLoading: true,
      noteTypes: oldState.noteTypes
          .map((row) => row.copyWith(isSelected: false))
          .toList(),
      isInMultiSelectMode: false,
    ),
  );
  return ManageNoteTypeDeletionPlan._(
    selectedRows: selectedRows,
    updateState: updateState,
    remove: remove,
    combineErrors: combineErrors,
  );
}

typedef _NoteTypeItemKey = ({
  int id,
  String name,
  int useCount,
  bool isSelected,
  bool shouldBeDisplayed,
});

_NoteTypeItemKey _keyFor(NoteTypeItemState row) => (
  id: row.id,
  name: row.name,
  useCount: row.useCount,
  isSelected: row.isSelected,
  shouldBeDisplayed: row.shouldBeDisplayed,
);
