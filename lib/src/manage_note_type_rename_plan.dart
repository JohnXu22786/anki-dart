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
 * SPDX-FileCopyrightText: 2025 lukstbit <52494258+lukstbit@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ManageNoteTypesViewModel.rename() in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'manage_note_types_state.dart';

/// Outcome of the host's safe note-type rename callback.
sealed class ManageNoteTypeRenameResult<T> {
  const ManageNoteTypeRenameResult();
}

/// Successful rename carrying the exact host `OpChanges` value.
final class ManageNoteTypeRenameSuccess<T>
    extends ManageNoteTypeRenameResult<T> {
  const ManageNoteTypeRenameSuccess(this.changes);

  final T changes;
}

/// Failed safe rename carrying its throwable and host-classified backend kind.
final class ManageNoteTypeRenameFailure
    extends ManageNoteTypeRenameResult<Never> {
  const ManageNoteTypeRenameFailure(this.throwable, this.isBackendException);

  final Object throwable;
  final bool isBackendException;
}

/// Host-facing state/effect choreography for renaming one note type.
final class ManageNoteTypeRenamePlan {
  const ManageNoteTypeRenamePlan._({
    required this.noteTypeId,
    required this.name,
    required void Function(ManageNoteTypesState Function(ManageNoteTypesState))
    updateState,
  }) : _updateState = updateState;

  /// The exact ID supplied to the host rename callback.
  final int noteTypeId;

  /// The exact name supplied to the host rename callback.
  final String name;

  final void Function(ManageNoteTypesState Function(ManageNoteTypesState))
  _updateState;

  /// Runs the source's undoable operation and returns its result.
  ///
  /// The host owns `safeRenameNoteType`, undoable execution, the default result,
  /// and reportable-error construction. Exceptions thrown by callbacks
  /// propagate at their original stage.
  Future<T> run<T>({
    required Future<T> Function(Future<T> Function()) undoableOp,
    required Future<ManageNoteTypeRenameResult<T>> Function(int, String)
    safeRename,
    required T Function() defaultResult,
    required Object? Function(Object, {required bool isReportable}) reportError,
  }) async => await undoableOp(() async {
    final result = await safeRename(noteTypeId, name);
    switch (result) {
      case ManageNoteTypeRenameSuccess<T>(:final changes):
        _updateState((oldState) {
          final updatedNoteTypes = oldState.noteTypes
              .map(
                (noteType) => noteType.id == noteTypeId
                    ? noteType.copyWith(name: name)
                    : noteType,
              )
              .toList();
          return oldState.copyWith(
            isLoading: false,
            noteTypes: updatedNoteTypes,
          );
        });
        return changes;
      case ManageNoteTypeRenameFailure(
        :final throwable,
        :final isBackendException,
      ):
        _updateState(
          (oldState) => oldState.copyWith(
            isLoading: false,
            error: reportError(throwable, isReportable: !isBackendException),
          ),
        );
        return defaultResult();
    }
  });
}

/// Publishes loading immediately, before the host schedules the operation.
ManageNoteTypeRenamePlan prepareManageNoteTypeRename({
  required int noteTypeId,
  required String name,
  required void Function(ManageNoteTypesState Function(ManageNoteTypesState))
  updateState,
}) {
  updateState((oldState) => oldState.copyWith(isLoading: true));
  return ManageNoteTypeRenamePlan._(
    noteTypeId: noteTypeId,
    name: name,
    updateState: updateState,
  );
}
