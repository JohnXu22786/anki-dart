/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Reads the fragment note ID and looks up its host note unless it is the sentinel.
///
/// [readEditorNoteId] represents one host read of `EDITOR_NOTE_ID` (including
/// the source default of `-1` when arguments are absent). The ID is read once
/// before collection access. Exactly `-1` returns null without calling
/// [getNote]; every other value is passed unchanged to that callback exactly
/// once, and its nullable result is returned unchanged. Argument reading,
/// collection lookup, and Note types remain host-side. Callback failures
/// propagate immediately.
T? cardTemplateFragmentGetNote<T>({
  required int Function() readEditorNoteId,
  required T? Function(int noteId) getNote,
}) {
  final noteId = readEditorNoteId();
  if (noteId == -1) {
    return null;
  }
  return getNote(noteId);
}
