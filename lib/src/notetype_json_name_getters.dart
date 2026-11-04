/*
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from NotetypeJson.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Adapts the pinned `NotetypeJson.fieldsNames` and `templatesNames` getters.
///
/// The host owns `NotetypeJson`, `JSONObject`, `JSONArray`, and `Field`
/// representations and behavior. This adapter keeps those values opaque and
/// invokes the supplied host operations in source order.
final class NotetypeJsonNameGetters<TField, TArray extends Object> {
  const NotetypeJsonNameGetters({
    required Object notetypeJson,
    required Iterable<TField> Function(Object notetypeJson) getFields,
    required String Function(TField field) getFieldName,
    required TArray Function(Object notetypeJson, String key) getJSONArray,
    required List<String> Function(TArray array, String key) toStringList,
  }) : _notetypeJson = notetypeJson,
       _getFields = getFields,
       _getFieldName = getFieldName,
       _getJSONArray = getJSONArray,
       _toStringList = toStringList;

  final Object _notetypeJson;
  final Iterable<TField> Function(Object notetypeJson) _getFields;
  final String Function(TField field) _getFieldName;
  final TArray Function(Object notetypeJson, String key) _getJSONArray;
  final List<String> Function(TArray array, String key) _toStringList;

  /// Reads the source `fields` collection once and materializes field names.
  List<String> get fieldsNames {
    final fields = _getFields(_notetypeJson);
    return [for (final field in fields) _getFieldName(field)];
  }

  /// Returns the host `toStringList("name")` result for the `tmpls` array.
  List<String> get templatesNames =>
      _toStringList(_getJSONArray(_notetypeJson, 'tmpls'), 'name');
}
