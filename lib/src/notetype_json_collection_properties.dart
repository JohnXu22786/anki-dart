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

import 'libanki_field_collections.dart';

/// Adapts `NotetypeJson.fields` and `NotetypeJson.templates` collection access.
///
/// The host retains the JSON object and supplies JSON reads, writes, and
/// collection construction. The exact host array and callback failures pass
/// through unchanged.
final class NotetypeJsonCollectionProperties<
  TJson extends Object,
  TArray extends Object
> {
  const NotetypeJsonCollectionProperties({
    required TJson jsonObject,
    required TArray Function(TJson jsonObject, String key) getJSONArray,
    required LibAnkiFields<TArray> Function(TArray array) fieldsFromJsonArray,
    required LibAnkiCardTemplates<TArray> Function(TArray array)
    templatesFromJsonArray,
    required void Function(TJson jsonObject, String key, Object? value) put,
  }) : _jsonObject = jsonObject,
       _getJSONArray = getJSONArray,
       _fieldsFromJsonArray = fieldsFromJsonArray,
       _templatesFromJsonArray = templatesFromJsonArray,
       _put = put;

  final TJson _jsonObject;
  final TArray Function(TJson jsonObject, String key) _getJSONArray;
  final LibAnkiFields<TArray> Function(TArray array) _fieldsFromJsonArray;
  final LibAnkiCardTemplates<TArray> Function(TArray array)
  _templatesFromJsonArray;
  final void Function(TJson jsonObject, String key, Object? value) _put;

  /// The note type's fields, backed by the exact host `flds` array.
  LibAnkiFields<TArray> get fields =>
      _fieldsFromJsonArray(_getJSONArray(_jsonObject, 'flds'));

  set fields(LibAnkiFields<TArray> value) =>
      _put(_jsonObject, 'flds', value.jsonArray);

  /// The note type's card templates, backed by the exact host `tmpls` array.
  LibAnkiCardTemplates<TArray> get templates =>
      _templatesFromJsonArray(_getJSONArray(_jsonObject, 'tmpls'));

  set templates(LibAnkiCardTemplates<TArray> value) =>
      _put(_jsonObject, 'tmpls', value.jsonArray);
}
