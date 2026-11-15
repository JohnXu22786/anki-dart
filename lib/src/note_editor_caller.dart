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
 * Source-derived from NoteEditorFragment.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Identifies the source that launched AnkiDroid's Note Editor.
///
/// The declaration order and [value] codes match the upstream enum. In
/// particular, the codes are not in numeric order after [DECKPICKER].
enum NoteEditorCaller {
  NO_CALLER(0),
  EDIT(1),
  STUDYOPTIONS(2),
  DECKPICKER(3),
  REVIEWER_ADD(11),
  CARDBROWSER_ADD(7),
  NOTEEDITOR(8),
  PREVIEWER_EDIT(9),
  NOTEEDITOR_INTENT_ADD(10),
  IMG_OCCLUSION(12),
  ADD_IMAGE(13),
  INSTANT_NOTE_EDITOR(14);

  const NoteEditorCaller(this.value);

  /// The integer code stored in Note Editor launch arguments.
  final int value;

  /// Returns the first caller whose [value] exactly matches [value].
  ///
  /// Unknown values throw [StateError], matching Kotlin's `first` behavior.
  static NoteEditorCaller fromValue(int value) =>
      values.firstWhere((caller) => caller.value == value);
}
