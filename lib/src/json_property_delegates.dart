/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from JSONContainer.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'json_container.dart';

/// Reads and writes a host JSON boolean using the source delegate's key.
final class JsonBooleanDelegate {
  JsonBooleanDelegate({
    required Object jsonObject,
    required String key,
    required bool Function(Object jsonObject, String key) getBoolean,
    required bool Function(Object jsonObject, String key, bool fallback)
    optBoolean,
    required void Function(Object jsonObject, String key, Object? value) put,
    bool? fallback,
  }) : _jsonObject = jsonObject,
       _key = key,
       _getBoolean = getBoolean,
       _optBoolean = optBoolean,
       _put = put,
       _fallback = fallback;

  final Object _jsonObject;
  final String _key;
  final bool Function(Object jsonObject, String key) _getBoolean;
  final bool Function(Object jsonObject, String key, bool fallback) _optBoolean;
  final void Function(Object jsonObject, String key, Object? value) _put;
  final bool? _fallback;

  /// Reads by the source `getBoolean` or non-null `optBoolean` branch.
  bool getValue(Object? thisRef, Object? property) => _fallback != null
      ? _optBoolean(_jsonObject, _key, _fallback)
      : _getBoolean(_jsonObject, _key);

  /// Writes [value] once with the retained object and key.
  void setValue(Object? thisRef, Object? property, bool value) {
    _put(_jsonObject, _key, value);
  }
}

/// Reads and writes a host JSON integer using the source delegate's key.
final class JsonIntDelegate {
  JsonIntDelegate({
    required Object jsonObject,
    required String key,
    required int Function(Object jsonObject, String key) getInt,
    required int Function(Object jsonObject, String key, int fallback) optInt,
    required void Function(Object jsonObject, String key, Object? value) put,
    int? fallback,
  }) : _jsonObject = jsonObject,
       _key = key,
       _getInt = getInt,
       _optInt = optInt,
       _put = put,
       _fallback = fallback;

  final Object _jsonObject;
  final String _key;
  final int Function(Object jsonObject, String key) _getInt;
  final int Function(Object jsonObject, String key, int fallback) _optInt;
  final void Function(Object jsonObject, String key, Object? value) _put;
  final int? _fallback;

  /// Reads by the source `getInt` or non-null `optInt` branch.
  int getValue(Object? thisRef, Object? property) => _fallback != null
      ? _optInt(_jsonObject, _key, _fallback)
      : _getInt(_jsonObject, _key);

  /// Writes [value] once with the retained object and key.
  void setValue(Object? thisRef, Object? property, int value) {
    _put(_jsonObject, _key, value);
  }
}

/// Reads and writes a host JSON integer as a Dart [int].
final class JsonLongDelegate {
  JsonLongDelegate({
    required Object jsonObject,
    required String key,
    required int Function(Object jsonObject, String key) getLong,
    required int Function(Object jsonObject, String key, int fallback) optLong,
    required void Function(Object jsonObject, String key, Object? value) put,
    int? fallback,
  }) : _jsonObject = jsonObject,
       _key = key,
       _getLong = getLong,
       _optLong = optLong,
       _put = put,
       _fallback = fallback;

  final Object _jsonObject;
  final String _key;
  final int Function(Object jsonObject, String key) _getLong;
  final int Function(Object jsonObject, String key, int fallback) _optLong;
  final void Function(Object jsonObject, String key, Object? value) _put;
  final int? _fallback;

  /// Reads by the source `getLong` or non-null `optLong` branch.
  int getValue(Object? thisRef, Object? property) => _fallback != null
      ? _optLong(_jsonObject, _key, _fallback)
      : _getLong(_jsonObject, _key);

  /// Writes [value] once with the retained object and key.
  void setValue(Object? thisRef, Object? property, int value) {
    _put(_jsonObject, _key, value);
  }
}

/// Reads and writes a host JSON number as a Dart [double].
final class JsonDoubleDelegate {
  JsonDoubleDelegate({
    required Object jsonObject,
    required String key,
    required double Function(Object jsonObject, String key) getDouble,
    required double Function(Object jsonObject, String key, double fallback)
    optDouble,
    required void Function(Object jsonObject, String key, Object? value) put,
    double? fallback,
  }) : _jsonObject = jsonObject,
       _key = key,
       _getDouble = getDouble,
       _optDouble = optDouble,
       _put = put,
       _fallback = fallback;

  final Object _jsonObject;
  final String _key;
  final double Function(Object jsonObject, String key) _getDouble;
  final double Function(Object jsonObject, String key, double fallback)
  _optDouble;
  final void Function(Object jsonObject, String key, Object? value) _put;
  final double? _fallback;

  /// Reads by the source `getDouble` or non-null `optDouble` branch.
  double getValue(Object? thisRef, Object? property) => _fallback != null
      ? _optDouble(_jsonObject, _key, _fallback)
      : _getDouble(_jsonObject, _key);

  /// Writes [value] once with the retained object and key.
  void setValue(Object? thisRef, Object? property, double value) {
    _put(_jsonObject, _key, value);
  }
}

/// Reads and writes a host JSON string using the source delegate's key.
final class JsonStringDelegate {
  JsonStringDelegate({
    required Object jsonObject,
    required String key,
    required String Function(Object jsonObject, String key) getString,
    required String Function(Object jsonObject, String key, String fallback)
    optString,
    required void Function(Object jsonObject, String key, Object? value) put,
    String? fallback,
  }) : _jsonObject = jsonObject,
       _key = key,
       _getString = getString,
       _optString = optString,
       _put = put,
       _fallback = fallback;

  final Object _jsonObject;
  final String _key;
  final String Function(Object jsonObject, String key) _getString;
  final String Function(Object jsonObject, String key, String fallback)
  _optString;
  final void Function(Object jsonObject, String key, Object? value) _put;
  final String? _fallback;

  /// Reads by the source `getString` or non-null `optString` branch.
  String getValue(Object? thisRef, Object? property) => _fallback != null
      ? _optString(_jsonObject, _key, _fallback)
      : _getString(_jsonObject, _key);

  /// Writes [value] once with the retained object and key.
  void setValue(Object? thisRef, Object? property, String value) {
    _put(_jsonObject, _key, value);
  }
}

/// Reads and writes a host JSON array using the source delegate's key.
final class JsonArrayDelegate<TArray extends Object> {
  JsonArrayDelegate({
    required Object jsonObject,
    required String key,
    required TArray Function(Object jsonObject, String key) getJSONArray,
    required void Function(Object jsonObject, String key, Object? value) put,
  }) : _jsonObject = jsonObject,
       _key = key,
       _getJSONArray = getJSONArray,
       _put = put;

  final Object _jsonObject;
  final String _key;
  final TArray Function(Object jsonObject, String key) _getJSONArray;
  final void Function(Object jsonObject, String key, Object? value) _put;

  /// Reads with the source `getJSONArray` operation.
  TArray getValue(Object? thisRef, Object? property) =>
      _getJSONArray(_jsonObject, _key);

  /// Writes [value] once with the retained object and key.
  void setValue(Object? thisRef, Object? property, TArray value) {
    _put(_jsonObject, _key, value);
  }
}

/// Creates typed JSON delegates around this holder's exact JSON object.
extension JSONObjectHolderPropertyDelegates on JSONObjectHolder {
  /// Creates a boolean delegate, using the opt read only for non-null fallback.
  JsonBooleanDelegate jsonBoolean({
    required String key,
    required bool Function(Object jsonObject, String key) getBoolean,
    required bool Function(Object jsonObject, String key, bool fallback)
    optBoolean,
    required void Function(Object jsonObject, String key, Object? value) put,
    bool? fallback,
  }) {
    final jsonObject = this.jsonObject;
    return JsonBooleanDelegate(
      jsonObject: jsonObject,
      key: key,
      getBoolean: getBoolean,
      optBoolean: optBoolean,
      put: put,
      fallback: fallback,
    );
  }

  /// Creates an integer delegate, using the opt read only for non-null fallback.
  JsonIntDelegate jsonInt({
    required String key,
    required int Function(Object jsonObject, String key) getInt,
    required int Function(Object jsonObject, String key, int fallback) optInt,
    required void Function(Object jsonObject, String key, Object? value) put,
    int? fallback,
  }) {
    final jsonObject = this.jsonObject;
    return JsonIntDelegate(
      jsonObject: jsonObject,
      key: key,
      getInt: getInt,
      optInt: optInt,
      put: put,
      fallback: fallback,
    );
  }

  /// Creates a long delegate, using the opt read only for non-null fallback.
  JsonLongDelegate jsonLong({
    required String key,
    required int Function(Object jsonObject, String key) getLong,
    required int Function(Object jsonObject, String key, int fallback) optLong,
    required void Function(Object jsonObject, String key, Object? value) put,
    int? fallback,
  }) {
    final jsonObject = this.jsonObject;
    return JsonLongDelegate(
      jsonObject: jsonObject,
      key: key,
      getLong: getLong,
      optLong: optLong,
      put: put,
      fallback: fallback,
    );
  }

  /// Creates a double delegate, using the opt read only for non-null fallback.
  JsonDoubleDelegate jsonDouble({
    required String key,
    required double Function(Object jsonObject, String key) getDouble,
    required double Function(Object jsonObject, String key, double fallback)
    optDouble,
    required void Function(Object jsonObject, String key, Object? value) put,
    double? fallback,
  }) {
    final jsonObject = this.jsonObject;
    return JsonDoubleDelegate(
      jsonObject: jsonObject,
      key: key,
      getDouble: getDouble,
      optDouble: optDouble,
      put: put,
      fallback: fallback,
    );
  }

  /// Creates a string delegate, using the opt read only for non-null fallback.
  JsonStringDelegate jsonString({
    required String key,
    required String Function(Object jsonObject, String key) getString,
    required String Function(Object jsonObject, String key, String fallback)
    optString,
    required void Function(Object jsonObject, String key, Object? value) put,
    String? fallback,
  }) {
    final jsonObject = this.jsonObject;
    return JsonStringDelegate(
      jsonObject: jsonObject,
      key: key,
      getString: getString,
      optString: optString,
      put: put,
      fallback: fallback,
    );
  }

  /// Creates an array delegate using the host's typed `getJSONArray` read.
  JsonArrayDelegate<TArray> jsonArray<TArray extends Object>({
    required String key,
    required TArray Function(Object jsonObject, String key) getJSONArray,
    required void Function(Object jsonObject, String key, Object? value) put,
  }) {
    final jsonObject = this.jsonObject;
    return JsonArrayDelegate<TArray>(
      jsonObject: jsonObject,
      key: key,
      getJSONArray: getJSONArray,
      put: put,
    );
  }
}
