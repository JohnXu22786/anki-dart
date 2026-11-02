/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
 * Copyright (c) 2024 Ashish Yadav <mailtoashish693@gmail.com>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2024 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from JSONObject.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Adapts `JSONObject.getStringOrNull(key)` while retaining host JSON behavior.
String? jsonObjectGetStringOrNull({
  required String key,
  required bool Function(String key) has,
  required bool Function(String key) isNull,
  required String Function(String key) getString,
}) {
  if (!has(key)) return null;
  if (isNull(key)) return null;
  try {
    return getString(key);
  } on Exception {
    return null;
  }
}

/// Host operations needed to adapt AnkiDroid's JSONObject copy helpers.
///
/// The host retains its JSON representations, typed accessors, conversions,
/// and JSONArray cloning behavior. This adapter preserves the source helper's
/// key iteration, read, and write order around those operations.
final class JsonObjectHostAdapter<TObject, TArray> {
  const JsonObjectHostAdapter({
    required Iterable<String> Function(TObject object) keys,
    required Object? Function(TObject object, String key) get,
    required bool Function(Object? value) isJsonObject,
    required bool Function(Object? value) isJsonArray,
    required TObject Function(TObject object, String key) getJsonObject,
    required TArray Function(TObject object, String key) getJsonArray,
    required TArray Function(TArray array) deepCloneJsonArray,
    required TObject Function() createObject,
    required void Function(TObject object, String key, Object? value) put,
  }) : _keys = keys,
       _get = get,
       _isJsonObject = isJsonObject,
       _isJsonArray = isJsonArray,
       _getJsonObject = getJsonObject,
       _getJsonArray = getJsonArray,
       _deepCloneJsonArray = deepCloneJsonArray,
       _createObject = createObject,
       _put = put;

  final Iterable<String> Function(TObject object) _keys;
  final Object? Function(TObject object, String key) _get;
  final bool Function(Object? value) _isJsonObject;
  final bool Function(Object? value) _isJsonArray;
  final TObject Function(TObject object, String key) _getJsonObject;
  final TArray Function(TObject object, String key) _getJsonArray;
  final TArray Function(TArray array) _deepCloneJsonArray;
  final TObject Function() _createObject;
  final void Function(TObject object, String key, Object? value) _put;

  /// Adapts `JSONObject.deepClone()` by creating one host object first.
  TObject deepClone(TObject object) => deepClonedInto(object, _createObject());

  /// Copies [object] into [clone], preserving [clone]'s identity.
  ///
  /// Nested objects and arrays use the host's typed reads. Scalar values are
  /// read again after type probing, matching the source callback sequence.
  TClone deepClonedInto<TClone extends TObject>(TObject object, TClone clone) {
    for (final key in _keys(object)) {
      final value = _get(object, key);
      final clonedValue = _isJsonObject(value)
          ? deepClone(_getJsonObject(object, key))
          : _isJsonArray(value)
          ? _deepCloneJsonArray(_getJsonArray(object, key))
          : _get(object, key);
      _put(clone, key, clonedValue);
    }
    return clone;
  }

  /// Adapts top-level `fromMap(map)` using one host object and one put per entry.
  TObject fromMap(Map<String, Object> map) {
    final object = _createObject();
    for (final entry in map.entries) {
      _put(object, entry.key, entry.value);
    }
    return object;
  }
}

/// Lazily projects `JSONObject.jsonObjectIterable()` as a re-iterable sequence.
///
/// The host supplies fresh object keys and typed object reads on each iteration.
Iterable<TObject> jsonObjectIterable<TObject>({
  required Iterable<String> Function() keys,
  required TObject Function(String key) getJSONObject,
}) sync* {
  for (final key in keys()) {
    yield getJSONObject(key);
  }
}
