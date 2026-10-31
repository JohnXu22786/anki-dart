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
 * Source-derived from ManageNoteTypesViewModel.refreshNoteTypes() in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'manage_note_types_state.dart';

/// Successful host safe-query result with its exact ordered row list.
final class ManageNoteTypeRefreshSuccess extends ManageNoteTypeRefreshResult {
  const ManageNoteTypeRefreshSuccess(this.noteTypes);

  final List<NoteTypeItemState> noteTypes;
}

/// Failed host safe-query result carrying the original exception.
final class ManageNoteTypeRefreshFailure extends ManageNoteTypeRefreshResult {
  const ManageNoteTypeRefreshFailure(this.throwable);

  final Object throwable;
}

/// Outcome of the host's safe note-type name/ID/use-count query.
sealed class ManageNoteTypeRefreshResult {
  const ManageNoteTypeRefreshResult();
}

/// Host-facing state/effect choreography for refreshing note types.
final class ManageNoteTypeRefreshPlan {
  const ManageNoteTypeRefreshPlan._({
    required void Function(ManageNoteTypesState Function(ManageNoteTypesState))
    updateState,
  }) : _updateState = updateState;

  final void Function(ManageNoteTypesState Function(ManageNoteTypesState))
  _updateState;

  /// Publishes the host safe-query outcome into the latest state.
  ///
  /// The host owns the query and its `Exception` capture, scheduling, and
  /// `ReportableException` construction. An exception thrown by [safeQuery],
  /// [reportError], or a later state publication propagates at that boundary.
  Future<void> run({
    required Future<ManageNoteTypeRefreshResult> Function() safeQuery,
    required Object Function(Object) reportError,
  }) async {
    final result = await safeQuery();
    switch (result) {
      case ManageNoteTypeRefreshSuccess(:final noteTypes):
        _updateState(
          (oldState) =>
              oldState.copyWith(isLoading: false, noteTypes: noteTypes),
        );
      case ManageNoteTypeRefreshFailure(:final throwable):
        _updateState(
          (oldState) => oldState.copyWith(
            isLoading: false,
            error: reportError(throwable),
          ),
        );
    }
  }
}

/// Publishes loading immediately, before the host schedules its query.
ManageNoteTypeRefreshPlan prepareManageNoteTypeRefresh({
  required void Function(ManageNoteTypesState Function(ManageNoteTypesState))
  updateState,
}) {
  updateState((oldState) => oldState.copyWith(isLoading: true));
  return ManageNoteTypeRefreshPlan._(updateState: updateState);
}
