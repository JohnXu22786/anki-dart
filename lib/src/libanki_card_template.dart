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
 * Source-derived from CardTemplate.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Host-owned operations needed to adapt AnkiDroid's `CardTemplate` JSON model.
///
/// The host retains JSONObject typed getters, `put`, its null sentinel,
/// `deepClone`, equality/hash, and string conversion behavior.
final class LibAnkiCardTemplateJsonCallbacks {
  const LibAnkiCardTemplateJsonCallbacks({
    required this.getString,
    required this.getInt,
    required this.put,
    required this.nullSentinel,
    required this.deepCloneJsonObject,
    required this.jsonObjectEquals,
    required this.jsonObjectHashCode,
    required this.jsonObjectToString,
  });

  final String Function(Object jsonObject, String key) getString;
  final int Function(Object jsonObject, String key) getInt;
  final void Function(Object jsonObject, String key, Object? value) put;
  final Object nullSentinel;
  final Object Function(Object jsonObject) deepCloneJsonObject;
  final bool Function(Object left, Object right) jsonObjectEquals;
  final int Function(Object jsonObject) jsonObjectHashCode;
  final String Function(Object jsonObject) jsonObjectToString;
}

/// Portable wrapper for the libanki card template's host JSON object.
///
/// This is distinct from [CardTemplate], which parses and renders template
/// HTML. The host keeps JSON access, representation, and failure semantics.
final class LibAnkiCardTemplate {
  const LibAnkiCardTemplate({
    required this.jsonObject,
    required this.callbacks,
  });

  /// The exact host JSON object retained by this template.
  final Object jsonObject;

  /// Host JSON behavior used by the source property accessors and value hooks.
  final LibAnkiCardTemplateJsonCallbacks callbacks;

  /// User-facing template name, stored at key `name`.
  String get name => callbacks.getString(jsonObject, 'name');

  set name(String value) => callbacks.put(jsonObject, 'name', value);

  /// Zero-based template ordinal, read from key `ord`.
  int get ord => callbacks.getInt(jsonObject, 'ord');

  /// Review question format, stored at key `qfmt`.
  String get qfmt => callbacks.getString(jsonObject, 'qfmt');

  set qfmt(String value) => callbacks.put(jsonObject, 'qfmt', value);

  /// Review answer format, stored at key `afmt`.
  String get afmt => callbacks.getString(jsonObject, 'afmt');

  set afmt(String value) => callbacks.put(jsonObject, 'afmt', value);

  /// Browser question format, stored at key `bqfmt`.
  String get bqfmt => callbacks.getString(jsonObject, 'bqfmt');

  set bqfmt(String value) => callbacks.put(jsonObject, 'bqfmt', value);

  /// Browser answer format, stored at key `bafmt`.
  String get bafmt => callbacks.getString(jsonObject, 'bafmt');

  set bafmt(String value) => callbacks.put(jsonObject, 'bafmt', value);

  /// Writes the ordinal, passing the exact host null sentinel for null values.
  void setOrd(int? value) =>
      callbacks.put(jsonObject, 'ord', value ?? callbacks.nullSentinel);

  /// Returns a wrapper around one host deep clone of this exact JSON object.
  LibAnkiCardTemplate deepClone() => LibAnkiCardTemplate(
    jsonObject: callbacks.deepCloneJsonObject(jsonObject),
    callbacks: callbacks,
  );

  /// Kotlin data-class component for its sole constructor property.
  Object component1() => jsonObject;

  /// Kotlin data-class copy for its sole constructor property.
  LibAnkiCardTemplate copy({
    Object jsonObject = _unspecifiedCardTemplateJsonObject,
  }) => LibAnkiCardTemplate(
    jsonObject: identical(jsonObject, _unspecifiedCardTemplateJsonObject)
        ? this.jsonObject
        : jsonObject,
    callbacks: callbacks,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibAnkiCardTemplate &&
          callbacks.jsonObjectEquals(jsonObject, other.jsonObject));

  @override
  int get hashCode => callbacks.jsonObjectHashCode(jsonObject);

  @override
  String toString() => callbacks.jsonObjectToString(jsonObject);
}

const _unspecifiedCardTemplateJsonObject = _UnspecifiedCardTemplateJsonObject();

final class _UnspecifiedCardTemplateJsonObject {
  const _UnspecifiedCardTemplateJsonObject();
}
