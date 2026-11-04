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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from SortOrder.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The libanki sort-order union passed to collection note/card searches.
///
/// Collection access, browser columns, and actual query execution remain owned
/// by the host.
sealed class LibAnkiSortOrder {
  const LibAnkiSortOrder._();

  /// Returns search results without ordering.
  static const LibAnkiSortOrder noOrdering = _LibAnkiNoOrdering();

  /// Uses the ordering stored in the collection configuration.
  static const LibAnkiSortOrder useCollectionOrdering =
      _LibAnkiUseCollectionOrdering();
}

final class _LibAnkiNoOrdering extends LibAnkiSortOrder {
  const _LibAnkiNoOrdering() : super._();

  @override
  bool operator ==(Object other) => other is _LibAnkiNoOrdering;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'NoOrdering';
}

final class _LibAnkiUseCollectionOrdering extends LibAnkiSortOrder {
  const _LibAnkiUseCollectionOrdering() : super._();

  @override
  bool operator ==(Object other) => other is _LibAnkiUseCollectionOrdering;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'UseCollectionOrdering';
}

/// Adds the exact supplied text after SQL `order by`.
///
/// The collection/backend owns the query and any interaction with collection
/// sort configuration.
final class LibAnkiAfterSqlOrderBy extends LibAnkiSortOrder {
  const LibAnkiAfterSqlOrderBy(this.customOrdering) : super._();

  /// The custom ordering text, retained without parsing or normalization.
  final String customOrdering;

  /// Kotlin data-class `component1()` equivalent.
  String component1() => customOrdering;

  /// Returns a value equal by [customOrdering], like the source data-class
  /// copy.
  LibAnkiAfterSqlOrderBy copy({String? customOrdering}) =>
      LibAnkiAfterSqlOrderBy(customOrdering ?? this.customOrdering);

  @override
  bool operator ==(Object other) =>
      other is LibAnkiAfterSqlOrderBy &&
      other.customOrdering == customOrdering;

  @override
  int get hashCode => customOrdering.hashCode;

  @override
  String toString() => 'AfterSqlOrderBy(customOrdering=$customOrdering)';
}

/// Sorts using a host browser column that supports sorting.
///
/// [column] is kept opaque so the generated BrowserColumns type and its
/// `key` property remain host-side. The host supplies the property read used
/// only for source-compatible string formatting.
final class LibAnkiBuiltinColumnSortKind extends LibAnkiSortOrder {
  LibAnkiBuiltinColumnSortKind({
    required this.column,
    required this.reverse,
    required String Function(Object column) columnKey,
  }) : _columnKey = columnKey,
       super._();

  /// The exact host-owned column object.
  final Object column;

  /// Whether the collection order should be reversed.
  final bool reverse;

  final String Function(Object column) _columnKey;

  @override
  String toString() =>
      'BuiltinColumnSortKind(column=${_columnKey(column)}, reverse=$reverse)';
}
