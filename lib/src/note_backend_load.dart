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

/// Adapts `Note.load(col)` and forwards its exact backend Note to the projection.
/// Callback failures propagate unchanged and prevent later calls.
void libankiNoteLoad<TBackendNote>({
  required int Function() currentId,
  required TBackendNote Function(int id) getNote,
  required void Function(TBackendNote note) loadFromBackendNote,
}) {
  final id = currentId();
  final note = getNote(id);
  loadFromBackendNote(note);
}

/// Adapts the ordered `Note.loadFromBackendNote(col, note)` assignments.
///
/// Note, Collection/backend, protobuf, Notetype, and Field objects remain
/// host-owned. Each getter, setter, host lookup, list copy, and field-map
/// construction is invoked at its source position; a failure stops subsequent
/// operations while retaining earlier target mutations.
void libankiNoteLoadFromBackendNote<TBackendNote, TNotetype, TFieldMap>({
  required TBackendNote note,
  required int Function(TBackendNote note) readId,
  required void Function(int id) setId,
  required String? Function(TBackendNote note) readGuid,
  required void Function(String? guid) setGuid,
  required int Function(TBackendNote note) readNotetypeId,
  required void Function(int noteTypeId) setNoteTypeId,
  required int Function() currentNoteTypeId,
  required TNotetype Function(int noteTypeId) getRequiredNotetype,
  required void Function(TNotetype notetype) setNotetype,
  required int Function(TBackendNote note) readMtimeSecs,
  required void Function(int mod) setMod,
  required int Function(TBackendNote note) readUsn,
  required void Function(int usn) setUsn,
  required Iterable<String> Function(TBackendNote note) readTagsList,
  required Iterable<String> Function(TBackendNote note) readFieldsList,
  required List<String> Function(Iterable<String> values) copyMutableList,
  required void Function(List<String> tags) setTags,
  required void Function(List<String> fields) setFields,
  required TNotetype Function() readNotetype,
  required TFieldMap Function(TNotetype notetype) createFieldMap,
  required void Function(TFieldMap fieldMap) setFieldMap,
}) {
  final id = readId(note);
  setId(id);

  final guid = readGuid(note);
  setGuid(guid);

  final noteTypeId = readNotetypeId(note);
  setNoteTypeId(noteTypeId);
  final currentTypeId = currentNoteTypeId();
  final notetype = getRequiredNotetype(currentTypeId);
  setNotetype(notetype);

  final mod = readMtimeSecs(note);
  setMod(mod);

  final usn = readUsn(note);
  setUsn(usn);

  final tags = copyMutableList(readTagsList(note));
  setTags(tags);

  final fields = copyMutableList(readFieldsList(note));
  setFields(fields);

  final fieldMap = createFieldMap(readNotetype());
  setFieldMap(fieldMap);
}
