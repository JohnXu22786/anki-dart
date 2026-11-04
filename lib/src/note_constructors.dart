/*
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Note.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Adapts `Note(col, id)` while leaving Note, Collection, and loading host-side.
///
/// Assigns [id] before invoking [load] once with [collection]. Callback errors
/// propagate unchanged and stop the sequence.
void libankiNoteConstructFromId<TCollection>({
  required TCollection collection,
  required int id,
  required void Function(int id) setId,
  required void Function(TCollection collection) load,
}) {
  setId(id);
  load(collection);
}

/// Adapts `Note(col, backendNote)` with the exact supplied backend object.
///
/// The host retains Note, Collection, and backend-note implementations. This
/// constructor delegates once to the existing projection operation and adds no
/// reads, copies, or other work.
void libankiNoteConstructFromBackendNote<TCollection, TBackendNote>({
  required TCollection collection,
  required TBackendNote backendNote,
  required void Function(TCollection collection, TBackendNote backendNote)
  loadFromBackendNote,
}) {
  loadFromBackendNote(collection, backendNote);
}

/// Adapts `Note.fromNotetypeId(col, ntid)` while keeping host objects host-side.
///
/// Calls [newNote] once, passes its exact result to [constructFromBackendNote]
/// once, and returns that exact constructed Note. Callback errors propagate
/// unchanged and prevent later calls.
TNote libankiNoteFromNotetypeId<TCollection, TBackendNote, TNote>({
  required TCollection collection,
  required int noteTypeId,
  required TBackendNote Function(int noteTypeId) newNote,
  required TNote Function(TCollection collection, TBackendNote backendNote)
  constructFromBackendNote,
}) {
  final backendNote = newNote(noteTypeId);
  return constructFromBackendNote(collection, backendNote);
}
