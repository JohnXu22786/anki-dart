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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: SavedSearches.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// A named query saved in the Card Browser.
final class BrowserSavedSearch {
  const BrowserSavedSearch({required this.name, required this.query});

  final String name;
  final String query;

  /// Trims the query with Kotlin/JVM `String.trim()` character semantics.
  BrowserSavedSearch normalize() =>
      BrowserSavedSearch(name: name, query: _trimKotlinWhitespace(query));

  @override
  bool operator ==(Object other) =>
      other is BrowserSavedSearch && other.name == name && other.query == query;

  @override
  int get hashCode => Object.hash(name, query);

  @override
  String toString() => 'BrowserSavedSearch(name: $name, query: $query)';
}

/// Converts a config map to saved searches in case-sensitive name order.
///
/// AnkiDroid's collection config does not preserve list ordering; the
/// SavedSearches tests observe its case-sensitive name ordering.
List<BrowserSavedSearch> browserSavedSearchesFromConfigMap(
  Map<String, String> values,
) {
  final searches = [
    for (final entry in values.entries)
      BrowserSavedSearch(name: entry.key, query: entry.value),
  ];
  searches.sort((left, right) => left.name.compareTo(right.name));
  return searches;
}

/// Converts saved searches using Kotlin `associate` semantics: the last value
/// for a duplicate name wins.
Map<String, String> browserSavedSearchesToConfigMap(
  Iterable<BrowserSavedSearch> searches,
) {
  final values = <String, String>{};
  for (final search in searches) {
    values[search.name] = search.query;
  }
  return values;
}

/// In-memory saved-search behavior over host-supplied collection config values.
///
/// This model does not read or write Anki collection config. The host passes
/// [configValues] and persists [configValues] after a successful mutation.
final class BrowserSavedSearchesModel {
  BrowserSavedSearchesModel({Map<String, String> configValues = const {}})
      : _configValues = Map.of(configValues);

  final Map<String, String> _configValues;

  /// The current config map as an unmodifiable copy.
  Map<String, String> get configValues => Map.unmodifiable(_configValues);

  /// Saved searches sorted by their case-sensitive name.
  List<BrowserSavedSearch> get searches =>
      browserSavedSearchesFromConfigMap(_configValues);

  /// Looks up a name using exact, case-sensitive equality.
  BrowserSavedSearch? byName(String name) {
    final query = _configValues[name];
    if (query == null) return null;
    return BrowserSavedSearch(name: name, query: query);
  }

  /// Adds a normalized query, rejecting an existing exact name unchanged.
  ///
  /// The result contains whether a change occurred and the resulting sorted
  /// list, matching the source's `Pair<Boolean, List<SavedSearch>>` contract.
  (bool, List<BrowserSavedSearch>) add(BrowserSavedSearch savedSearch) {
    if (_configValues.containsKey(savedSearch.name)) return (false, searches);

    final normalized = savedSearch.normalize();
    _configValues[normalized.name] = normalized.query;
    return (true, searches);
  }

  /// Removes one exact name and returns whether the config changed.
  (bool, List<BrowserSavedSearch>) removeByName(String name) {
    if (!_configValues.containsKey(name)) return (false, searches);

    _configValues.remove(name);
    return (true, searches);
  }

  /// Removes all saved searches.
  void clear() => _configValues.clear();
}

String _trimKotlinWhitespace(String value) {
  var start = 0;
  var end = value.length;

  while (start < end && _isKotlinWhitespace(value.codeUnitAt(start))) {
    start++;
  }
  while (start < end && _isKotlinWhitespace(value.codeUnitAt(end - 1))) {
    end--;
  }

  return value.substring(start, end);
}

bool _isKotlinWhitespace(int codeUnit) =>
    (codeUnit >= 0x0009 && codeUnit <= 0x000D) ||
    (codeUnit >= 0x001C && codeUnit <= 0x0020) ||
    codeUnit == 0x00A0 ||
    codeUnit == 0x1680 ||
    (codeUnit >= 0x2000 && codeUnit <= 0x200A) ||
    codeUnit == 0x2028 ||
    codeUnit == 0x2029 ||
    codeUnit == 0x202F ||
    codeUnit == 0x205F ||
    codeUnit == 0x3000;
