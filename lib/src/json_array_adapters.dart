/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from JSONArray.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Host operations needed to adapt AnkiDroid's JSONArray extension helpers.
///
/// The host retains its `JSONArray` and `JSONObject` representations, typed
/// accessors, and object cloning behavior. This adapter preserves the source
/// helper control flow around those operations.
final class JsonArrayHostAdapter<TArray, TObject> {
  const JsonArrayHostAdapter({
    required int Function(TArray array) length,
    required TArray Function() createArray,
    required Object? Function(TArray array, int index) get,
    required bool Function(Object? value) isJsonObject,
    required bool Function(Object? value) isJsonArray,
    required TObject Function(TArray array, int index) getJsonObject,
    required TArray Function(TArray array, int index) getJsonArray,
    required TObject Function(TObject object) deepCloneJsonObject,
    required void Function(TArray array, Object? value) put,
    required String Function(TArray array, int index) getString,
    required String Function(TObject object, String key) getObjectString,
  }) : _length = length,
       _createArray = createArray,
       _get = get,
       _isJsonObject = isJsonObject,
       _isJsonArray = isJsonArray,
       _getJsonObject = getJsonObject,
       _getJsonArray = getJsonArray,
       _deepCloneJsonObject = deepCloneJsonObject,
       _put = put,
       _getString = getString,
       _getObjectString = getObjectString;

  final int Function(TArray array) _length;
  final TArray Function() _createArray;
  final Object? Function(TArray array, int index) _get;
  final bool Function(Object? value) _isJsonObject;
  final bool Function(Object? value) _isJsonArray;
  final TObject Function(TArray array, int index) _getJsonObject;
  final TArray Function(TArray array, int index) _getJsonArray;
  final TObject Function(TObject object) _deepCloneJsonObject;
  final void Function(TArray array, Object? value) _put;
  final String Function(TArray array, int index) _getString;
  final String Function(TObject object, String key) _getObjectString;

  /// Adapts `JSONArray.deepClone()` while leaving host JSON values opaque.
  TArray deepClone(TArray array) {
    final clone = _createArray();
    final length = _length(array);
    for (var index = 0; index < length; index++) {
      final value = _get(array, index);
      final clonedValue = switch (value) {
        _ when _isJsonObject(value) => _deepCloneJsonObject(
          _getJsonObject(array, index),
        ),
        _ when _isJsonArray(value) => deepClone(_getJsonArray(array, index)),
        _ => _get(array, index),
      };
      _put(clone, clonedValue);
    }
    return clone;
  }

  /// Returns a lazy, re-iterable view of typed JSONObject reads.
  Iterable<TObject> jsonObjectIterable(TArray array) =>
      _JsonArrayIterable<TObject>(() => jsonObjectIterator(array));

  /// Returns a source-shaped iterator whose reads occur only in [next].
  JsonArrayIterator<TObject> jsonObjectIterator(TArray array) =>
      JsonArrayIterator<TObject>(
        length: () => _length(array),
        get: (index) => _getJsonObject(array, index),
      );

  /// Returns a lazy, re-iterable view of typed String reads.
  Iterable<String> stringIterable(TArray array) =>
      _JsonArrayIterable<String>(() => stringIterator(array));

  /// Returns a source-shaped iterator whose reads occur only in [next].
  JsonArrayIterator<String> stringIterator(TArray array) =>
      JsonArrayIterator<String>(
        length: () => _length(array),
        get: (index) => _getString(array, index),
      );

  /// Adapts `JSONArray.toStringList(key)` and materializes the result eagerly.
  List<String> toStringList(TArray array, String key) => jsonObjectIterable(
    array,
  ).map((object) => _getObjectString(object, key)).toList();
}

final class _JsonArrayIterable<T> extends Iterable<T> {
  const _JsonArrayIterable(this._createIterator);

  final Iterator<T> Function() _createIterator;

  @override
  Iterator<T> get iterator => _createIterator();
}

/// Iterator with the source's explicit `hasNext()` / `next()` operations.
///
/// It also implements Dart's [Iterator] contract so it can back a Dart
/// [Iterable]. Calling [next] directly does not first consult [hasNext].
final class JsonArrayIterator<T> implements Iterator<T> {
  JsonArrayIterator({
    required int Function() length,
    required T Function(int) get,
  }) : _length = length,
       _get = get;

  final int Function() _length;
  final T Function(int index) _get;
  int _index = 0;
  T? _current;
  bool _hasCurrent = false;
  bool _done = false;

  /// Mirrors the source iterator's fresh length check on every call.
  bool hasNext() => _index < _length();

  /// Reads the current index and advances only after the read succeeds.
  T next() {
    final value = _get(_index);
    _index++;
    return value;
  }

  @override
  T get current {
    if (!_hasCurrent) throw StateError('No current value');
    return _current as T;
  }

  @override
  bool moveNext() {
    _hasCurrent = false;
    if (_done) return false;
    if (!hasNext()) {
      _done = true;
      return false;
    }
    _current = next();
    _hasCurrent = true;
    return true;
  }
}
