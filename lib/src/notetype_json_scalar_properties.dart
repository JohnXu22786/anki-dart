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

import 'libanki_consts.dart';

/// Adapts the remaining scalar and raw-array `NotetypeJson` properties.
///
/// The host retains the JSON object and supplies its source-compatible typed
/// reads and `put` behavior. Values, arrays, and callback failures pass through
/// unchanged.
final class NotetypeJsonScalarProperties<
  TJson extends Object,
  TArray extends Object
> {
  const NotetypeJsonScalarProperties({
    required TJson jsonObject,
    required int originalStockKindUnknownValue,
    required String Function(TJson jsonObject, String key) getString,
    required int Function(TJson jsonObject, String key) getLong,
    required int Function(TJson jsonObject, String key) getInt,
    required int Function(TJson jsonObject, String key, int fallback) optInt,
    required bool Function(TJson jsonObject, String key, bool fallback)
    optBoolean,
    required TArray Function(TJson jsonObject, String key) getJSONArray,
    required void Function(TJson jsonObject, String key, Object? value) put,
  }) : _jsonObject = jsonObject,
       _originalStockKindUnknownValue = originalStockKindUnknownValue,
       _getString = getString,
       _getLong = getLong,
       _getInt = getInt,
       _optInt = optInt,
       _optBoolean = optBoolean,
       _getJSONArray = getJSONArray,
       _put = put;

  final TJson _jsonObject;
  final int _originalStockKindUnknownValue;
  final String Function(TJson jsonObject, String key) _getString;
  final int Function(TJson jsonObject, String key) _getLong;
  final int Function(TJson jsonObject, String key) _getInt;
  final int Function(TJson jsonObject, String key, int fallback) _optInt;
  final bool Function(TJson jsonObject, String key, bool fallback) _optBoolean;
  final TArray Function(TJson jsonObject, String key) _getJSONArray;
  final void Function(TJson jsonObject, String key, Object? value) _put;

  /// The name of the note type.
  String get name => _getString(_jsonObject, 'name');

  set name(String value) => _put(_jsonObject, 'name', value);

  /// The CSS shared by all card types of this note type.
  String get css => _getString(_jsonObject, 'css');

  set css(String value) => _put(_jsonObject, 'css', value);

  /// The preamble for LaTeX code used by this note type.
  String get latexPre => _getString(_jsonObject, 'latexPre');

  set latexPre(String value) => _put(_jsonObject, 'latexPre', value);

  /// The trailer for LaTeX code used by this note type.
  String get latexPost => _getString(_jsonObject, 'latexPost');

  set latexPost(String value) => _put(_jsonObject, 'latexPost', value);

  /// The unique identifier for this note type.
  int get id => _getLong(_jsonObject, 'id');

  set id(int value) => _put(_jsonObject, 'id', value);

  /// The timestamp when this note type was last modified.
  int get mod => _getLong(_jsonObject, 'mod');

  set mod(int value) => _put(_jsonObject, 'mod', value);

  /// The sort-field ordinal.
  int get sortf => _getInt(_jsonObject, 'sortf');

  set sortf(int value) => _put(_jsonObject, 'sortf', value);

  /// The sync USN for this note type.
  int get usn => _getInt(_jsonObject, 'usn');

  set usn(int value) => _put(_jsonObject, 'usn', value);

  /// The recorded original stock kind, or the host's unknown-kind value.
  int get originalStockKind =>
      _optInt(_jsonObject, 'originalStockKind', _originalStockKindUnknownValue);

  /// The note type kind represented by its integer `type` code.
  LibAnkiNoteTypeKind get type =>
      LibAnkiNoteTypeKind.fromCode(_getInt(_jsonObject, 'type'));

  set type(LibAnkiNoteTypeKind value) => _put(_jsonObject, 'type', value.code);

  /// Whether LaTeX should be generated as SVG.
  bool get latexsvg => _optBoolean(_jsonObject, 'latexsvg', false);

  /// Legacy card-generation requirements retained for backwards compatibility.
  @Deprecated('req is no longer used. Exists for backwards compatibility.')
  TArray get req => _getJSONArray(_jsonObject, 'req');

  /// Writes the legacy card-generation requirements array unchanged.
  @Deprecated('req is no longer used. Exists for backwards compatibility.')
  set req(TArray value) => _put(_jsonObject, 'req', value);
}
