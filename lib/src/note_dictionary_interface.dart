/*
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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

/// Returns the field names in the host map's iteration order, matching
/// `Note.keys()`. The Note and its ordered field map remain host-owned.
List<String> libankiNoteKeys({required Map<String, int> Function() fieldMap}) =>
    fieldMap().keys.toList();

/// Returns the exact mutable fields list retained by the host Note, matching
/// `Note.values()`.
List<String> libankiNoteValues({required List<String> fields}) => fields;

/// Adapts `Note.items()` using the host's ordered name-to-ordinal projection.
/// Rows are placed by ordinal, so their final order can differ from map order.
List<List<String>> libankiNoteItems({
  required Map<String, int> Function() fieldMap,
  required List<String> fields,
}) {
  // TODO: Revisit this method. The field order returned differs from Anki.
  // The items here are only used in the note editor, so it's a low priority.
  final map = fieldMap();
  final result = List.generate(map.length, (_) => <String>['', '']);
  for (final fieldName in map.keys) {
    final ordinal = map[fieldName]!;
    result[ordinal][0] = fieldName;
    result[ordinal][1] = fields[ordinal];
  }
  return result;
}

/// Resolves a Note field index, constructing the host's
/// `IllegalArgumentException` only after a missing map lookup.
int libankiNoteFieldIndex(
  String key, {
  required Map<String, int> Function() fieldMap,
  required Object Function(String message) illegalArgumentException,
}) {
  final ordinal = fieldMap()[key];
  if (ordinal == null) {
    throw illegalArgumentException("No field named '$key' found");
  }
  return ordinal;
}

/// Reads a Note field after resolving its index through `fieldIndex()`.
String libankiNoteGetItem(
  String key, {
  required Map<String, int> Function() fieldMap,
  required List<String> fields,
  required Object Function(String message) illegalArgumentException,
}) =>
    fields[libankiNoteFieldIndex(
      key,
      fieldMap: fieldMap,
      illegalArgumentException: illegalArgumentException,
    )];

/// Writes a Note field after resolving its index through `fieldIndex()`.
void libankiNoteSetItem(
  String key,
  String value, {
  required Map<String, int> Function() fieldMap,
  required List<String> fields,
  required Object Function(String message) illegalArgumentException,
}) {
  fields[libankiNoteFieldIndex(
        key,
        fieldMap: fieldMap,
        illegalArgumentException: illegalArgumentException,
      )] =
      value;
}

/// Delegates `Note.contains(key)` directly to the host field map.
bool libankiNoteContains(
  String key, {
  required Map<String, int> Function() fieldMap,
}) => fieldMap().containsKey(key);
