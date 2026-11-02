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
 * SPDX-FileCopyrightText: 2025 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ImageOcclusionViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Arguments for adding or editing an Image Occlusion note.
sealed class ImageOcclusionArgs {
  const ImageOcclusionArgs();

  /// Builds the exact mode values consumed by Anki's Image Occlusion page.
  Map<String, Object> toImageOcclusionMode();
}

/// Source `ImageOcclusionArgs.Add`, retaining its original path and IDs.
final class ImageOcclusionAddArgs extends ImageOcclusionArgs {
  const ImageOcclusionAddArgs({
    required this.imagePath,
    required this.noteTypeId,
    required this.originalDeckId,
  });

  final String imagePath;
  final int noteTypeId;
  final int originalDeckId;

  @override
  Map<String, Object> toImageOcclusionMode() => {
    'kind': 'add',
    'imagePath': imagePath,
    'notetypeId': noteTypeId,
  };

  @override
  bool operator ==(Object other) =>
      other is ImageOcclusionAddArgs &&
      other.imagePath == imagePath &&
      other.noteTypeId == noteTypeId &&
      other.originalDeckId == originalDeckId;

  @override
  int get hashCode => Object.hash(imagePath, noteTypeId, originalDeckId);
}

/// Source `ImageOcclusionArgs.Edit`, retaining its note ID.
final class ImageOcclusionEditArgs extends ImageOcclusionArgs {
  const ImageOcclusionEditArgs({required this.noteId});

  final int noteId;

  @override
  Map<String, Object> toImageOcclusionMode() => {
    'kind': 'edit',
    'noteId': noteId,
  };

  @override
  bool operator ==(Object other) =>
      other is ImageOcclusionEditArgs && other.noteId == noteId;

  @override
  int get hashCode => noteId.hashCode;
}

/// Portable state from AnkiDroid's `ImageOcclusionViewModel`.
///
/// Only Add mode has a selected deck ID. The host resolves deck names, applies
/// current-deck changes, and performs an asynchronous restore when
/// [onSaveOperationCompleted] returns a deck ID.
final class ImageOcclusionViewModelState {
  ImageOcclusionViewModelState(this.args)
    : _selectedDeckId = switch (args) {
        ImageOcclusionAddArgs(:final originalDeckId) => originalDeckId,
        ImageOcclusionEditArgs() => null,
      };

  final ImageOcclusionArgs args;
  int? _selectedDeckId;

  /// The selected deck in Add mode; null in Edit mode.
  int? get selectedDeckId => _selectedDeckId;

  /// Stores the supplied deck ID only in Add mode.
  void handleDeckSelection(int deckId) {
    if (args is ImageOcclusionAddArgs) {
      _selectedDeckId = deckId;
    }
  }

  /// Returns the original deck ID when the host should restore it after save.
  ///
  /// The source leaves the selected-ID flow unchanged and asynchronously resets
  /// the collection's current deck only when the ID differs from the original.
  /// This method performs no collection access or asynchronous work.
  int? onSaveOperationCompleted() {
    final currentArgs = args;
    if (currentArgs is! ImageOcclusionAddArgs ||
        currentArgs.originalDeckId == _selectedDeckId) {
      return null;
    }
    return currentArgs.originalDeckId;
  }
}
