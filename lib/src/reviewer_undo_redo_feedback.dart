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
 * Behavioral reference: Undo.kt and ReviewerViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'undo_status.dart';

/// Selects Reviewer undo/redo feedback from a host-supplied undo result.
///
/// An empty [operation] returns the matching host-localized no-operation
/// message. Otherwise only the matching operation callback is invoked, with
/// [operation] passed unchanged. Undo execution, message localization, action
/// dispatch, and feedback delivery remain host-side.
String reviewerUndoRedoFeedbackMessage({
  required bool isUndo,
  required String operation,
  required String nothingToUndoMessage,
  required String nothingToRedoMessage,
  required String Function(String operation) undoMessage,
  required String Function(String operation) redoMessage,
}) {
  if (operation.isEmpty) {
    return isUndo ? nothingToUndoMessage : nothingToRedoMessage;
  }
  return isUndo ? undoMessage(operation) : redoMessage(operation);
}

/// Runs the requested Reviewer action and returns its localized feedback.
///
/// The selected host action is called exactly once. The operation name it
/// returns is passed unchanged to the corresponding localized message; an
/// empty name selects the matching no-operation message.
Future<String> performReviewerUndoRedoAction({
  required bool isUndo,
  required Future<String> Function() undo,
  required Future<String> Function() redo,
  required String nothingToUndoMessage,
  required String nothingToRedoMessage,
  required String Function(String operation) undoMessage,
  required String Function(String operation) redoMessage,
}) async {
  final operation = await (isUndo ? undo : redo)();
  return reviewerUndoRedoFeedbackMessage(
    isUndo: isUndo,
    operation: operation,
    nothingToUndoMessage: nothingToUndoMessage,
    nothingToRedoMessage: nothingToRedoMessage,
    undoMessage: undoMessage,
    redoMessage: redoMessage,
  );
}

/// Shared Reviewer undo/redo actions backed by one live status reader.
///
/// Each availability or label read takes one status snapshot. Execution uses
/// the host undo/redo callback and returns localized feedback for its result.
final class ReviewerUndoRedoActions {
  const ReviewerUndoRedoActions({
    required this.readStatus,
    required this.undo,
    required this.redo,
    required this.nothingToUndoMessage,
    required this.nothingToRedoMessage,
    required this.undoMessage,
    required this.redoMessage,
  });

  final UndoStatus Function() readStatus;
  final Future<String> Function() undo;
  final Future<String> Function() redo;
  final String nothingToUndoMessage;
  final String nothingToRedoMessage;
  final String Function(String operation) undoMessage;
  final String Function(String operation) redoMessage;

  String? get undoLabel => readStatus().undo;
  String? get redoLabel => readStatus().redo;
  bool get canUndo => undoLabel != null;
  bool get canRedo => redoLabel != null;

  Future<String> undoWithFeedback() => performReviewerUndoRedoAction(
    isUndo: true,
    undo: undo,
    redo: redo,
    nothingToUndoMessage: nothingToUndoMessage,
    nothingToRedoMessage: nothingToRedoMessage,
    undoMessage: undoMessage,
    redoMessage: redoMessage,
  );

  Future<String> redoWithFeedback() => performReviewerUndoRedoAction(
    isUndo: false,
    undo: undo,
    redo: redo,
    nothingToUndoMessage: nothingToUndoMessage,
    nothingToRedoMessage: nothingToRedoMessage,
    undoMessage: undoMessage,
    redoMessage: redoMessage,
  );
}
