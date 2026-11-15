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
 * Source-derived from Note.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Adapts `Note.fieldsCheck(col)` while keeping Note and backend types host-side.
///
/// Calls [toBackendNote] once, passes that exact object to [noteFieldsCheck],
/// then returns [responseState] for the exact returned response. Callback
/// failures propagate unchanged and stop subsequent calls.
TState libankiNoteFieldsCheck<TBackendNote, TResponse, TState>({
  required TBackendNote Function() toBackendNote,
  required TResponse Function(TBackendNote note) noteFieldsCheck,
  required TState Function(TResponse response) responseState,
}) {
  final backendNote = toBackendNote();
  final response = noteFieldsCheck(backendNote);
  return responseState(response);
}
