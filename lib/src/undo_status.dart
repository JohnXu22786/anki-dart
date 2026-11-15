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
 * Source-derived from BackendUndo.kt and Collection.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'kotlin_string_hash_code.dart';

/// The action labels and undo-step index currently reported by the backend.
final class UndoStatus {
  const UndoStatus({
    required this.undo,
    required this.redo,
    required this.lastStep,
  });

  /// The undo action, or null when no undo action is available.
  final String? undo;

  /// The redo action, or null when no redo action is available.
  final String? redo;

  /// The backend's last undo step, preserved as a signed 32-bit integer value.
  final int lastStep;

  @override
  bool operator ==(Object other) =>
      other is UndoStatus &&
      other.undo == undo &&
      other.redo == redo &&
      other.lastStep == lastStep;

  @override
  int get hashCode => _int32(
    31 *
            _int32(
              31 * (undo == null ? 0 : kotlinStringHashCode(undo!)) +
                  (redo == null ? 0 : kotlinStringHashCode(redo!)),
            ) +
        _int32(lastStep),
  );
}

/// The source's `UndoStepCounter` typealias.
typedef UndoStepCounter = int;

/// Adapts host-supplied backend status fields without importing generated protos.
///
/// As in `UndoStatus.from()`, only empty strings are normalized to null;
/// whitespace and the backend's step value are retained unchanged.
UndoStatus undoStatusFromFields({
  required String undo,
  required String redo,
  required UndoStepCounter lastStep,
}) => UndoStatus(
  undo: undo.isEmpty ? null : undo,
  redo: redo.isEmpty ? null : redo,
  lastStep: lastStep,
);

/// Reads one status snapshot and reports whether it contains an undo action.
bool undoAvailable({required UndoStatus Function() readStatus}) =>
    readStatus().undo != null;

/// Reads one status snapshot and reports whether it contains a redo action.
bool redoAvailable({required UndoStatus Function() readStatus}) =>
    readStatus().redo != null;

/// Returns the localized undo label, requesting localization only if available.
String? undoLabel({
  required UndoStatus Function() readStatus,
  required String Function(String action) localize,
}) {
  final action = readStatus().undo;
  return action == null ? null : localize(action);
}

/// Returns the localized redo label, requesting localization only if available.
String? redoLabel({
  required UndoStatus Function() readStatus,
  required String Function(String action) localize,
}) {
  final action = readStatus().redo;
  return action == null ? null : localize(action);
}

int _int32(int value) {
  final unsigned = value & 0xFFFFFFFF;
  return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
}
