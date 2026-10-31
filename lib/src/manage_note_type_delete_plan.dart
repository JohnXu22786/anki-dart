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
 * Source-derived from ManageNoteTypesViewModel.delete() in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'manage_note_types_state.dart';

/// Outcome of the host's single `safeRemoveNoteType` call.
sealed class ManageNoteTypeDeleteResult<T> {
  const ManageNoteTypeDeleteResult();
}

/// Successful removal carrying the exact host `OpChanges` value.
final class ManageNoteTypeDeleteSuccess<T>
    extends ManageNoteTypeDeleteResult<T> {
  const ManageNoteTypeDeleteSuccess(this.changes);

  final T changes;
}

/// A failed safe removal carrying the original host throwable.
final class ManageNoteTypeDeleteFailure<T>
    extends ManageNoteTypeDeleteResult<T> {
  const ManageNoteTypeDeleteFailure(this.throwable);

  final Object throwable;
}

/// Host-facing state/effect choreography for deleting one note type.
final class ManageNoteTypeDeletePlan<T> {
  const ManageNoteTypeDeletePlan._({
    required this.noteTypeId,
    required this.noteTypesCount,
    required void Function(ManageNoteTypesState Function(ManageNoteTypesState))
    updateState,
  }) : _updateState = updateState;

  /// The exact ID supplied to the host removal callback.
  final int noteTypeId;

  /// The row count captured immediately after publishing loading.
  final int noteTypesCount;

  final void Function(ManageNoteTypesState Function(ManageNoteTypesState))
  _updateState;

  /// Runs the source's one undoable operation and returns its exact result.
  ///
  /// The host owns undoable-operation and safe-removal behavior, default result
  /// construction, and reportable-error wrapping. Exceptions thrown by those
  /// callbacks propagate at their original stage.
  Future<T> run({
    required Future<T> Function(Future<T> Function()) undoableOp,
    required Future<ManageNoteTypeDeleteResult<T>> Function(int) safeRemove,
    required T Function() defaultResult,
    required Object? Function(Object) reportError,
    required Object? deletingLastMessage,
  }) async => await undoableOp(() async {
    if (noteTypesCount <= 1) {
      _updateState(
        (oldState) =>
            oldState.copyWith(isLoading: false, message: deletingLastMessage),
      );
      return defaultResult();
    }

    final result = await safeRemove(noteTypeId);
    switch (result) {
      case ManageNoteTypeDeleteSuccess<T>(:final changes):
        _updateState((oldState) {
          final updatedNoteTypes = oldState.noteTypes
              .where((noteType) => noteType.id != noteTypeId)
              .toList();
          return oldState.copyWith(
            isLoading: false,
            noteTypes: updatedNoteTypes,
            isInMultiSelectMode: updatedNoteTypes.any(
              (noteType) => noteType.isSelected,
            ),
          );
        });
        return changes;
      case ManageNoteTypeDeleteFailure<T>(:final throwable):
        _updateState(
          (oldState) => oldState.copyWith(
            isLoading: false,
            error: reportError(throwable),
          ),
        );
        return defaultResult();
    }
  });
}

/// Publishes loading, then captures the source's pre-operation row count.
ManageNoteTypeDeletePlan<T> prepareManageNoteTypeDelete<T>({
  required int noteTypeId,
  required ManageNoteTypesState Function() readState,
  required void Function(ManageNoteTypesState Function(ManageNoteTypesState))
  updateState,
}) {
  updateState((oldState) => oldState.copyWith(isLoading: true));
  final noteTypesCount = readState().noteTypes.length;
  return ManageNoteTypeDeletePlan<T>._(
    noteTypeId: noteTypeId,
    noteTypesCount: noteTypesCount,
    updateState: updateState,
  );
}
