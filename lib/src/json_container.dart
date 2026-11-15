/*
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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from JSONContainer.kt and PythonExtensions.kt in AnkiDroid
 * 2.25.3; PythonExtensions.kt declares GPL-3.0-or-later without a separate
 * copyright line. See ANKIDROID_UPSTREAM.md.
 */

/// Holds an opaque host JSON object used by [JSONContainer].
abstract interface class JSONObjectHolder {
  Object get jsonObject;
}

/// Adapts the AnkiDroid `JSONContainer<T>` around host-owned JSON operations.
///
/// The backing array, JSON object iterator, typed object read, and indexed put
/// remain owned by the host. Iteration converts each object only when the host
/// iterator advances. [indices] intentionally materializes every item first,
/// matching the source's `this.toList().indices` behavior.
final class JSONContainer<TArray, T extends JSONObjectHolder>
    extends Iterable<T> {
  JSONContainer({
    required TArray jsonArray,
    required T Function(Object jsonObject) constructor,
    required Iterator<Object> Function(TArray array) jsonObjectIterator,
    required Object Function(TArray array, int index) getJsonObject,
    required void Function(TArray array, int index, Object value) put,
    required int Function(TArray array) length,
    void Function(TArray array, Object value)? append,
    void Function(TArray array, Object value)? remove,
    int? Function(TArray array, Object value)? index,
    void Function(TArray array, int index, Object value)? insert,
  }) : _jsonArray = jsonArray,
       _constructor = constructor,
       _jsonObjectIterator = jsonObjectIterator,
       _getJsonObject = getJsonObject,
       _put = put,
       _length = length,
       _append = append,
       _remove = remove,
       _index = index,
       _insert = insert;

  final TArray _jsonArray;
  final T Function(Object jsonObject) _constructor;
  final Iterator<Object> Function(TArray array) _jsonObjectIterator;
  final Object Function(TArray array, int index) _getJsonObject;
  final void Function(TArray array, int index, Object value) _put;
  final int Function(TArray array) _length;
  final void Function(TArray array, Object value)? _append;
  final void Function(TArray array, Object value)? _remove;
  final int? Function(TArray array, Object value)? _index;
  final void Function(TArray array, int index, Object value)? _insert;

  /// Returns the host object's iterator, mapping values only when advanced.
  @override
  Iterator<T> get iterator =>
      _JSONContainerIterator<T>(_jsonObjectIterator(_jsonArray), _constructor);

  /// Reads one host JSON object at [index] and wraps it with the constructor.
  T operator [](int index) => _constructor(_getJsonObject(_jsonArray, index));

  /// Writes the holder's opaque JSON object at the exact [index].
  void operator []=(int index, T field) =>
      _put(_jsonArray, index, field.jsonObject);

  /// Returns the host array length with one host call.
  ///
  /// Dart's [Iterable.length] getter is the equivalent of the source's
  /// `length()` method.
  @override
  int get length => _length(_jsonArray);

  /// Returns the host array length.
  int get size => length;

  /// Materializes all elements before returning their list indices.
  Iterable<int> get indices => toList().asMap().keys;

  /// Appends [template]'s host JSON object through the host array callback.
  ///
  /// Throws a [StateError] if this container has no append callback.
  void append(T template) {
    final operation = _append;
    if (operation == null) throw StateError('No append callback configured');
    final jsonObject = template.jsonObject;
    operation(_jsonArray, jsonObject);
  }

  /// Removes [template]'s host JSON object through the host array callback.
  ///
  /// Throws a [StateError] if this container has no remove callback.
  void remove(T template) {
    final operation = _remove;
    if (operation == null) throw StateError('No remove callback configured');
    final jsonObject = template.jsonObject;
    operation(_jsonArray, jsonObject);
  }

  /// Returns the host index, or `null` when its Kotlin `Optional<Int>` is empty.
  ///
  /// A present Kotlin value maps to the same Dart [int]; absence maps to null.
  /// Throws a [StateError] if this container has no index callback.
  int? index(T template) {
    final operation = _index;
    if (operation == null) throw StateError('No index callback configured');
    final jsonObject = template.jsonObject;
    return operation(_jsonArray, jsonObject);
  }

  /// Inserts [template]'s host JSON object at [idx] through the host callback.
  ///
  /// Throws a [StateError] if this container has no insert callback.
  void insert(int idx, T template) {
    final operation = _insert;
    if (operation == null) throw StateError('No insert callback configured');
    final jsonObject = template.jsonObject;
    operation(_jsonArray, idx, jsonObject);
  }
}

final class _JSONContainerIterator<T extends JSONObjectHolder>
    implements Iterator<T> {
  _JSONContainerIterator(this._objects, this._constructor);

  final Iterator<Object> _objects;
  final T Function(Object jsonObject) _constructor;
  T? _current;
  bool _hasCurrent = false;

  @override
  T get current {
    if (!_hasCurrent) throw StateError('No current value');
    return _current as T;
  }

  @override
  bool moveNext() {
    _hasCurrent = false;
    if (!_objects.moveNext()) return false;
    _current = _constructor(_objects.current);
    _hasCurrent = true;
    return true;
  }
}
