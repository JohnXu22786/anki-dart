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
 * Source-derived from SavedSearches.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'browser_saved_searches.dart';

/// Loads saved searches from the host's collection-config boundary.
typedef BrowserSavedSearchesLoad = List<BrowserSavedSearch> Function();

/// Saves saved searches through the host's collection-config boundary.
typedef BrowserSavedSearchesSave =
    void Function(List<BrowserSavedSearch> values);

/// Coordinates saved-search reads and writes through host config callbacks.
///
/// The host owns collection config access and serialization. Callback failures
/// propagate unchanged, and each operation stops when a callback throws.
final class BrowserSavedSearchesConfig {
  const BrowserSavedSearchesConfig({required this.load, required this.save});

  final BrowserSavedSearchesLoad load;
  final BrowserSavedSearchesSave save;

  /// Returns the exact list provided by one host load callback.
  List<BrowserSavedSearch> loadFromConfig() => load();

  /// Passes [values] unchanged to one host save callback.
  void saveToConfig(List<BrowserSavedSearch> values) => save(values);

  /// Loads once and returns the first exact, case-sensitive name match.
  BrowserSavedSearch? byName(String name) {
    for (final value in loadFromConfig()) {
      if (value.name == name) return value;
    }
    return null;
  }

  /// Adds a normalized search unless an exact name already exists.
  ///
  /// On a duplicate, returns the original loaded list without writing or
  /// reloading. Otherwise, saves the appended list once and returns one reload.
  (bool, List<BrowserSavedSearch>) add(BrowserSavedSearch savedSearch) {
    final values = loadFromConfig();
    if (values.any((value) => value.name == savedSearch.name)) {
      return (false, values);
    }

    saveToConfig([...values, savedSearch.normalize()]);
    return (true, loadFromConfig());
  }

  /// Removes every exact name match, saving only when the list changes.
  ///
  /// A missing name returns the original list; a changed list is saved once
  /// and returned without a reload.
  (bool, List<BrowserSavedSearch>) removeByName(String name) {
    final originalValues = loadFromConfig();
    final updatedValues = originalValues
        .where((value) => value.name != name)
        .toList();
    if (updatedValues.length == originalValues.length) {
      return (false, originalValues);
    }

    saveToConfig(updatedValues);
    return (true, updatedValues);
  }

  /// Saves one empty list through the host callback.
  void clear() => saveToConfig(const []);
}
