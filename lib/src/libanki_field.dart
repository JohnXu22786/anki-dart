/*
 * Copyright (c) 2024 David Allison <davidallisongithub@gmail.com>
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
 * SPDX-FileCopyrightText: 2024 David Allison <davidallisongithub@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Field.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'field_set_ord.dart';
import 'json_container.dart';

/// Host-owned operations needed to adapt AnkiDroid's `Field` JSON holder.
///
/// The host retains its JSONObject representation, typed getters, `put`, null
/// sentinel, string conversion, and equality/hash behavior.
final class LibAnkiFieldJsonCallbacks {
  const LibAnkiFieldJsonCallbacks({
    required this.getString,
    required this.getInt,
    required this.getBoolean,
    required this.getStringOrNull,
    required this.put,
    required this.nullSentinel,
    required this.jsonObjectEquals,
    required this.jsonObjectHashCode,
    required this.jsonObjectToString,
  });

  final String Function(Object jsonObject, String key) getString;
  final int Function(Object jsonObject, String key) getInt;
  final bool Function(Object jsonObject, String key) getBoolean;
  final String? Function(Object jsonObject, String key) getStringOrNull;
  final void Function(Object jsonObject, String key, Object? value) put;
  final Object nullSentinel;
  final bool Function(Object left, Object right) jsonObjectEquals;
  final int Function(Object jsonObject) jsonObjectHashCode;
  final String Function(Object jsonObject) jsonObjectToString;
}

/// Portable wrapper for a note type field's host JSON object.
///
/// Property keys, mutability, and wrapper value behavior match AnkiDroid's
/// `Field`. The host keeps JSON access and representation semantics.
final class LibAnkiField implements JSONObjectHolder {
  const LibAnkiField({required this.jsonObject, required this.callbacks});

  /// The exact host JSON object retained by this field.
  final Object jsonObject;

  /// Host JSON behavior used by the source property accessors.
  final LibAnkiFieldJsonCallbacks callbacks;

  /// User-facing field name, stored at key `name`.
  String get name => callbacks.getString(jsonObject, 'name');

  set name(String value) => callbacks.put(jsonObject, 'name', value);

  /// Zero-based field ordinal, read from key `ord`.
  int get ord => callbacks.getInt(jsonObject, 'ord');

  /// Whether the note editor retains this field's content, stored at `sticky`.
  bool get sticky => callbacks.getBoolean(jsonObject, 'sticky');

  set sticky(bool value) => callbacks.put(jsonObject, 'sticky', value);

  /// Note-editor font, stored at key `font`.
  String get font => callbacks.getString(jsonObject, 'font');

  set font(String value) => callbacks.put(jsonObject, 'font', value);

  /// Note-editor font size, stored at key `size`.
  int get fontSize => callbacks.getInt(jsonObject, 'size');

  set fontSize(int value) => callbacks.put(jsonObject, 'size', value);

  /// Nullable image-occlusion tag using the host's `getStringOrNull` behavior.
  String? get imageOcclusionTag => callbacks.getStringOrNull(jsonObject, 'tag');

  /// Writes the ordinal, passing the exact host null sentinel for null values.
  void setOrd(int? value) => setLibAnkiFieldOrd(
    value: value,
    nullSentinel: callbacks.nullSentinel,
    put: (key, value) => callbacks.put(jsonObject, key, value),
  );

  /// Kotlin data-class component for its sole constructor property.
  Object component1() => jsonObject;

  /// Kotlin data-class copy for its sole constructor property.
  LibAnkiField copy({Object jsonObject = _unspecifiedFieldJsonObject}) =>
      LibAnkiField(
        jsonObject: identical(jsonObject, _unspecifiedFieldJsonObject)
            ? this.jsonObject
            : jsonObject,
        callbacks: callbacks,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibAnkiField &&
          callbacks.jsonObjectEquals(jsonObject, other.jsonObject));

  @override
  int get hashCode => callbacks.jsonObjectHashCode(jsonObject);

  @override
  String toString() => callbacks.jsonObjectToString(jsonObject);
}

const _unspecifiedFieldJsonObject = _UnspecifiedFieldJsonObject();

final class _UnspecifiedFieldJsonObject {
  const _UnspecifiedFieldJsonObject();
}
