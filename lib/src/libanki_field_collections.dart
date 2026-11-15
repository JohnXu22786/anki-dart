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
 * Source-derived from Fields.kt and CardTemplates.kt in AnkiDroid 2.25.3;
 * CardTemplates.kt declares GPL-3.0-or-later without a separate copyright
 * line. See ANKIDROID_UPSTREAM.md.
 */

import 'card_template.dart';
import 'json_container.dart';
import 'libanki_card_template.dart';
import 'libanki_field.dart';

/// Shared forwarding for the source `JSONContainer` value classes.
///
/// Host-owned JSON iteration, wrapping, indexing, writes, and optional array
/// operations stay in [JSONContainer].
abstract class _LibAnkiJsonCollection<TArray, T extends JSONObjectHolder>
    extends Iterable<T> {
  _LibAnkiJsonCollection({
    required this.jsonArray,
    required this.constructor,
    required Iterator<Object> Function(TArray array) jsonObjectIterator,
    required Object Function(TArray array, int index) getJsonObject,
    required void Function(TArray array, int index, Object value) put,
    required int Function(TArray array) length,
    void Function(TArray array, Object value)? append,
    void Function(TArray array, Object value)? remove,
    int? Function(TArray array, Object value)? index,
    void Function(TArray array, int index, Object value)? insert,
  }) : _container = JSONContainer<TArray, T>(
         jsonArray: jsonArray,
         constructor: constructor,
         jsonObjectIterator: jsonObjectIterator,
         getJsonObject: getJsonObject,
         put: put,
         length: length,
         append: append,
         remove: remove,
         index: index,
         insert: insert,
       );

  /// The exact host array passed to the source collection constructor.
  final TArray jsonArray;

  /// Wraps one host JSONObject as the collection's typed item.
  final T Function(Object jsonObject) constructor;

  final JSONContainer<TArray, T> _container;

  @override
  Iterator<T> get iterator => _container.iterator;

  T operator [](int index) => _container[index];

  void operator []=(int index, T item) => _container[index] = item;

  @override
  int get length => _container.length;

  int get size => _container.size;

  Iterable<int> get indices => _container.indices;

  void append(T item) => _container.append(item);

  void remove(T item) => _container.remove(item);

  int? index(T item) => _container.index(item);

  void insert(int index, T item) => _container.insert(index, item);
}

/// A `Fields(JSONArray)` adapter that lazily wraps items as [LibAnkiField].
///
/// The host supplies its JSONArray operations; this wrapper passes them through
/// to [JSONContainer].
final class LibAnkiFields<TArray>
    extends _LibAnkiJsonCollection<TArray, LibAnkiField> {
  LibAnkiFields({
    required super.jsonArray,
    required super.constructor,
    required super.jsonObjectIterator,
    required super.getJsonObject,
    required super.put,
    required super.length,
    super.append,
    super.remove,
    super.index,
    super.insert,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibAnkiFields && identical(jsonArray, other.jsonArray));

  @override
  int get hashCode => identityHashCode(jsonArray);
}

/// A `CardTemplates(JSONArray)` adapter that lazily wraps items as
/// [LibAnkiCardTemplate].
///
/// Source `@NotInPyLib` is source-retained metadata only; it has no Dart runtime
/// behavior. The host supplies JSONArray operations, which pass through to
/// [JSONContainer]. This type is distinct from the rendered [CardTemplate].
final class LibAnkiCardTemplates<TArray>
    extends _LibAnkiJsonCollection<TArray, LibAnkiCardTemplate> {
  LibAnkiCardTemplates({
    required super.jsonArray,
    required super.constructor,
    required super.jsonObjectIterator,
    required super.getJsonObject,
    required super.put,
    required super.length,
    super.append,
    super.remove,
    super.index,
    super.insert,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibAnkiCardTemplates && identical(jsonArray, other.jsonArray));

  @override
  int get hashCode => identityHashCode(jsonArray);
}
