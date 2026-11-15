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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Reads the host selection and asks the host to insert [fieldToInsert].
///
/// Selection reads are lazy callbacks so they occur in the source order.
/// Android `EditText`/`Editable`, text access, and the replacement stay host-side;
/// the host replacement callback receives the normalized bounds and the source
/// field range. Callback failures propagate without later work.
void cardTemplateFragmentInsertField({
  required String fieldToInsert,
  required int Function() readSelectionStart,
  required int Function() readSelectionEnd,
  required void Function(
    int replaceStart,
    int replaceEnd,
    String fieldToInsert,
    int fieldStart,
    int fieldEnd,
  )
  replaceText,
}) {
  final selectionStart = readSelectionStart();
  final start = selectionStart < 0 ? 0 : selectionStart;
  final selectionEnd = readSelectionEnd();
  final end = selectionEnd < 0 ? 0 : selectionEnd;
  final replaceStart = start < end ? start : end;
  final replaceEnd = start > end ? start : end;
  replaceText(replaceStart, replaceEnd, fieldToInsert, 0, fieldToInsert.length);
}
