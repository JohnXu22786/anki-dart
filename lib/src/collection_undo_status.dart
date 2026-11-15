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
 * Source-derived from Collection.kt and BackendUndo.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'undo_status.dart';

/// Host callbacks for reading an undo-status snapshot without importing protos.
///
/// The host owns the generated status object and provides explicit field
/// getters, keeping serialization and backend types on the host side.
final class CollectionUndoStatusCallbacks<TStatus> {
  const CollectionUndoStatusCallbacks({
    required this.getUndoStatus,
    required this.getUndo,
    required this.getRedo,
    required this.getLastStep,
  });

  final TStatus Function() getUndoStatus;
  final String Function(TStatus status) getUndo;
  final String Function(TStatus status) getRedo;
  final UndoStepCounter Function(TStatus status) getLastStep;
}

/// Projects `Collection.undoStatus()` from one host status snapshot.
///
/// Reads the snapshot and its `undo`, `redo`, and `lastStep` fields once each in
/// source order. Host callback and field getter failures propagate unchanged.
UndoStatus collectionUndoStatus<TStatus>(
  CollectionUndoStatusCallbacks<TStatus> callbacks,
) {
  final status = callbacks.getUndoStatus();
  final undo = callbacks.getUndo(status);
  final redo = callbacks.getRedo(status);
  final lastStep = callbacks.getLastStep(status);
  return undoStatusFromFields(undo: undo, redo: redo, lastStep: lastStep);
}
