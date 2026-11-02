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
 * Behavioral reference: WhiteboardViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

/// Opaque host path and source `DrawingAction` value fields.
///
/// The host path is retained as supplied. This model does not copy or inspect
/// its geometry.
final class WhiteboardDrawingAction<TPath> {
  const WhiteboardDrawingAction({
    required this.path,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });

  final TPath path;
  final int color;
  final double strokeWidth;
  final bool isEraser;
}

/// One path and its original list index in a source remove operation.
final class WhiteboardIndexedDrawingAction<TPath> {
  const WhiteboardIndexedDrawingAction(this.index, this.action);

  final int index;
  final WhiteboardDrawingAction<TPath> action;
}

/// An operation stored in the source undo or redo stack.
sealed class WhiteboardUndoableAction<TPath> {
  const WhiteboardUndoableAction();
}

/// Source `AddAction`.
final class WhiteboardAddAction<TPath> extends WhiteboardUndoableAction<TPath> {
  const WhiteboardAddAction(this.added);

  final WhiteboardDrawingAction<TPath> added;
}

/// Source `RemoveAction`.
final class WhiteboardRemoveAction<TPath>
    extends WhiteboardUndoableAction<TPath> {
  WhiteboardRemoveAction(
    Iterable<WhiteboardIndexedDrawingAction<TPath>> removed,
  ) : removed = List.unmodifiable(removed);

  final List<WhiteboardIndexedDrawingAction<TPath>> removed;
}

/// Source `ClearAction`.
final class WhiteboardClearAction<TPath>
    extends WhiteboardUndoableAction<TPath> {
  WhiteboardClearAction(Iterable<WhiteboardDrawingAction<TPath>> cleared)
    : cleared = List.unmodifiable(cleared);

  final List<WhiteboardDrawingAction<TPath>> cleared;
}

/// An ordered assignment to one published part of drawing history state.
sealed class WhiteboardHistoryEffect<TPath> {
  const WhiteboardHistoryEffect();
}

/// Publishes the current drawing paths.
final class PublishWhiteboardPathsEffect<TPath>
    extends WhiteboardHistoryEffect<TPath> {
  PublishWhiteboardPathsEffect(Iterable<WhiteboardDrawingAction<TPath>> paths)
    : paths = List.unmodifiable(paths);

  final List<WhiteboardDrawingAction<TPath>> paths;
}

/// Publishes the current undo stack.
final class PublishWhiteboardUndoStackEffect<TPath>
    extends WhiteboardHistoryEffect<TPath> {
  PublishWhiteboardUndoStackEffect(
    Iterable<WhiteboardUndoableAction<TPath>> actions,
  ) : actions = List.unmodifiable(actions);

  final List<WhiteboardUndoableAction<TPath>> actions;
}

/// Publishes the current redo stack.
final class PublishWhiteboardRedoStackEffect<TPath>
    extends WhiteboardHistoryEffect<TPath> {
  PublishWhiteboardRedoStackEffect(
    Iterable<WhiteboardUndoableAction<TPath>> actions,
  ) : actions = List.unmodifiable(actions);

  final List<WhiteboardUndoableAction<TPath>> actions;
}

/// Portable drawing paths and undo/redo transitions from `WhiteboardViewModel`.
///
/// Each method returns the same assignments in source publication order. The
/// host applies these effects to its paths and stack flows. Path payloads remain
/// opaque; undoing an add uses action identity, while redo of removals compares
/// DrawingAction values through [drawingActionEquals].
final class WhiteboardDrawingHistory<TPath> {
  WhiteboardDrawingHistory({
    Iterable<WhiteboardDrawingAction<TPath>> paths = const [],
    Iterable<WhiteboardUndoableAction<TPath>> undoStack = const [],
    Iterable<WhiteboardUndoableAction<TPath>> redoStack = const [],
    bool Function(
      WhiteboardDrawingAction<TPath> first,
      WhiteboardDrawingAction<TPath> second,
    )?
    drawingActionEquals,
  }) : _paths = List.unmodifiable(paths),
       _undoStack = List.unmodifiable(undoStack),
       _redoStack = List.unmodifiable(redoStack),
       drawingActionEquals = drawingActionEquals ?? _sameDrawingAction;

  List<WhiteboardDrawingAction<TPath>> _paths;
  List<WhiteboardUndoableAction<TPath>> _undoStack;
  List<WhiteboardUndoableAction<TPath>> _redoStack;

  /// Compares source `DrawingAction` data-class values during redo removal.
  ///
  /// The default compares the opaque path with its host equality operator and
  /// compares color, width, and eraser flag by value. A host can provide its
  /// exact path/action equality when that differs.
  final bool Function(
    WhiteboardDrawingAction<TPath> first,
    WhiteboardDrawingAction<TPath> second,
  )
  drawingActionEquals;

  List<WhiteboardDrawingAction<TPath>> get paths => _paths;
  List<WhiteboardUndoableAction<TPath>> get undoStack => _undoStack;
  List<WhiteboardUndoableAction<TPath>> get redoStack => _redoStack;

  /// Appends a completed path and its undo action, then clears redo history.
  List<WhiteboardHistoryEffect<TPath>> addCompletedAction(
    WhiteboardDrawingAction<TPath> action,
  ) {
    final effects = <WhiteboardHistoryEffect<TPath>>[];
    _publishPaths([..._paths, action], effects);
    _publishUndoStack([..._undoStack, WhiteboardAddAction(action)], effects);
    _publishRedoStack(const [], effects);
    return List.unmodifiable(effects);
  }

  /// Clears paths, recording their source order; an empty canvas is unchanged.
  List<WhiteboardHistoryEffect<TPath>> clearCanvas() {
    if (_paths.isEmpty) return const [];

    final effects = <WhiteboardHistoryEffect<TPath>>[];
    _publishUndoStack([..._undoStack, WhiteboardClearAction(_paths)], effects);
    _publishRedoStack(const [], effects);
    _publishPaths(const [], effects);
    return List.unmodifiable(effects);
  }

  /// Reverts the last operation, or returns no effects when undo is empty.
  List<WhiteboardHistoryEffect<TPath>> undo() {
    if (_undoStack.isEmpty) return const [];

    final action = _undoStack.last;
    final effects = <WhiteboardHistoryEffect<TPath>>[];
    _publishUndoStack(_undoStack.sublist(0, _undoStack.length - 1), effects);
    _publishRedoStack([..._redoStack, action], effects);

    final updatedPaths = [..._paths];
    switch (action) {
      case WhiteboardAddAction<TPath>(:final added):
        updatedPaths.removeWhere((current) => identical(current, added));
      case WhiteboardRemoveAction<TPath>(:final removed):
        final ordered =
            [for (var i = 0; i < removed.length; i++) (i, removed[i])]
              ..sort((first, second) {
                final byIndex = first.$2.index.compareTo(second.$2.index);
                return byIndex == 0 ? first.$1.compareTo(second.$1) : byIndex;
              });
        for (final (_, indexedAction) in ordered) {
          final index = indexedAction.index > updatedPaths.length
              ? updatedPaths.length
              : indexedAction.index;
          updatedPaths.insert(index, indexedAction.action);
        }
      case WhiteboardClearAction<TPath>(:final cleared):
        updatedPaths.addAll(cleared);
    }
    _publishPaths(updatedPaths, effects);
    return List.unmodifiable(effects);
  }

  /// Restores the last undone operation, or returns no effects when redo is empty.
  List<WhiteboardHistoryEffect<TPath>> redo() {
    if (_redoStack.isEmpty) return const [];

    final action = _redoStack.last;
    final effects = <WhiteboardHistoryEffect<TPath>>[];
    _publishRedoStack(_redoStack.sublist(0, _redoStack.length - 1), effects);
    _publishUndoStack([..._undoStack, action], effects);

    final updatedPaths = [..._paths];
    switch (action) {
      case WhiteboardAddAction<TPath>(:final added):
        updatedPaths.add(added);
      case WhiteboardRemoveAction<TPath>(:final removed):
        updatedPaths.removeWhere((current) {
          return removed.any(
            (entry) => drawingActionEquals(current, entry.action),
          );
        });
      case WhiteboardClearAction<TPath>():
        updatedPaths.clear();
    }
    _publishPaths(updatedPaths, effects);
    return List.unmodifiable(effects);
  }

  /// Clears the canvas first, then clears both history stacks.
  List<WhiteboardHistoryEffect<TPath>> reset() {
    final effects = <WhiteboardHistoryEffect<TPath>>[...clearCanvas()];
    _publishUndoStack(const [], effects);
    _publishRedoStack(const [], effects);
    return List.unmodifiable(effects);
  }

  void _publishPaths(
    Iterable<WhiteboardDrawingAction<TPath>> paths,
    List<WhiteboardHistoryEffect<TPath>> effects,
  ) {
    _paths = List.unmodifiable(paths);
    effects.add(PublishWhiteboardPathsEffect(_paths));
  }

  void _publishUndoStack(
    Iterable<WhiteboardUndoableAction<TPath>> actions,
    List<WhiteboardHistoryEffect<TPath>> effects,
  ) {
    _undoStack = List.unmodifiable(actions);
    effects.add(PublishWhiteboardUndoStackEffect(_undoStack));
  }

  void _publishRedoStack(
    Iterable<WhiteboardUndoableAction<TPath>> actions,
    List<WhiteboardHistoryEffect<TPath>> effects,
  ) {
    _redoStack = List.unmodifiable(actions);
    effects.add(PublishWhiteboardRedoStackEffect(_redoStack));
  }
}

bool _sameDrawingAction<TPath>(
  WhiteboardDrawingAction<TPath> first,
  WhiteboardDrawingAction<TPath> second,
) =>
    first.path == second.path &&
    first.color == second.color &&
    _sameFloat(first.strokeWidth, second.strokeWidth) &&
    first.isEraser == second.isEraser;

bool _sameFloat(double first, double second) {
  final values = ByteData(8)
    ..setFloat32(0, first)
    ..setFloat32(4, second);
  final firstFloat = values.getFloat32(0);
  final secondFloat = values.getFloat32(4);
  if (firstFloat.isNaN || secondFloat.isNaN) {
    return firstFloat.isNaN && secondFloat.isNaN;
  }
  return values.getUint32(0) == values.getUint32(4);
}
