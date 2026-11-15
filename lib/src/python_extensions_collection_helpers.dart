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
 * Source-derived from PythonExtensions.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:collection';

import 'json_container.dart';

/// Appends [value] to [values].
void appendToList<T>(List<T> values, T value) => values.add(value);

/// Appends each [value] in iteration order.
///
/// Iteration is incremental, so earlier additions remain if the source iterator
/// throws, matching Kotlin's MutableList.addAll behavior.
void extendList<T>(List<T> values, Iterable<T> elements) {
  final source = identical(values, elements) ? List<T>.of(values) : elements;
  for (final element in source) {
    values.add(element);
  }
}

/// Counts [values] once and widens the resulting Kotlin Int count to Dart int.
///
/// Kotlin's Sequence.count() uses an unchecked signed 32-bit counter, so this
/// wraps after Int.MAX_VALUE before the result is widened to Long.
int sequenceLength<T>(Iterable<T> values) {
  var count = 0;
  for (final _ in values) {
    count = _wrapKotlinInt(count + 1);
  }
  return count;
}

/// Applies Kotlin signed-Int wrapping before widening the count to Long.
int kotlinCountToLong(int count) => _wrapKotlinInt(count);

int _wrapKotlinInt(int value) {
  final unsigned = value & 0xffffffff;
  return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
}

/// Returns a list's size.
int listLength<T>(List<T> values) => values.length;

/// Returns the host JSONArray's length.
int jsonArrayLength<TArray>(
  TArray array, {
  required int Function(TArray array) length,
}) => length(array);

/// Returns the JSONContainer backing JSONArray's length.
///
/// [JSONContainer.length] delegates to the host array length callback.
int jsonContainerLength<TArray, T extends JSONObjectHolder>(
  JSONContainer<TArray, T> container,
) => container.length;

/// Removes and returns the element at [index].
///
/// A host can provide its own removal callback to preserve the platform's
/// collection and index-error behavior.
T popFromList<T>(
  List<T> values,
  int index, {
  T Function(List<T> values, int index)? removeAt,
}) => (removeAt ?? (list, position) => list.removeAt(position))(values, index);

/// Materializes key/value pairs in the map's host iteration order.
List<(K, V)> hashMapItems<K, V>(
  Map<K, V> values, {
  Iterable<MapEntry<K, V>> Function(Map<K, V> values)? entries,
}) => (entries?.call(values) ?? values.entries)
    .map((entry) => (entry.key, entry.value))
    .toList();

/// Returns whether [values] is null or empty.
bool listIsNullOrEmpty<T>(List<T>? values) => values == null || values.isEmpty;

/// Mirrors the Kotlin vararg overload.
///
/// The vararg array is one item in the returned mutable list; this deliberately
/// preserves the source's nested-array result.
List<List<T>> listFromVarargs<T>(List<T> elements) => [elements];

/// Copies a collection into a new growable list.
List<T> listFromCollection<T>(Iterable<T> values) => List<T>.of(values);

/// Copies list values into a HashSet, discarding duplicates.
Set<T> setFromList<T>(List<T> values) => HashSet<T>.of(values);

/// Joins [values] with this string as the separator.
String joinStrings(String separator, Iterable<String> values) =>
    values.join(separator);

/// Creates a host JSON array and puts each list value in source order.
///
/// Host construction and insertion remain injectable. If a put throws, the
/// created array and any earlier puts remain observable to the host.
TArray listToJsonArray<T, TArray>(
  List<T> values, {
  required TArray Function() createArray,
  required void Function(TArray array, Object? value) put,
}) {
  final array = createArray();
  for (final value in values) {
    put(array, value);
  }
  return array;
}
