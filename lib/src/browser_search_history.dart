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
 * Behavioral reference: SearchHistory.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// One Card Browser search and its selected filters.
///
/// The host supplies stable IDs/codes for filters. JSON conversion lives in
/// `browser_search_history_json.dart`; collection-backed query reconstruction
/// remains outside this headless history model.
final class BrowserSearchHistoryEntry {
  const BrowserSearchHistoryEntry({
    required this.query,
    this.deckIds = const [],
    this.flags = const [],
    this.tags = const [],
    this.noteTypeIds = const [],
    this.cardStateCodes = const [],
  });

  final String query;
  final List<int> deckIds;
  final List<int> flags;
  final List<String> tags;
  final List<int> noteTypeIds;
  final List<int> cardStateCodes;

  /// Whether this is the default search (blank query and no selected filters).
  bool get isSearchEmpty =>
      _isKotlinBlank(query) &&
      deckIds.isEmpty &&
      flags.isEmpty &&
      tags.isEmpty &&
      noteTypeIds.isEmpty &&
      cardStateCodes.isEmpty;

  @override
  String toString() => query;

  @override
  bool operator ==(Object other) =>
      other is BrowserSearchHistoryEntry &&
      other.query == query &&
      _listEquals(other.deckIds, deckIds) &&
      _listEquals(other.flags, flags) &&
      _listEquals(other.tags, tags) &&
      _listEquals(other.noteTypeIds, noteTypeIds) &&
      _listEquals(other.cardStateCodes, cardStateCodes);

  @override
  int get hashCode => Object.hash(
        query,
        Object.hashAll(deckIds),
        Object.hashAll(flags),
        Object.hashAll(tags),
        Object.hashAll(noteTypeIds),
        Object.hashAll(cardStateCodes),
      );
}

/// Headless Card Browser history ordering and eviction behavior.
///
/// Supply entries loaded by the host. Persist [entries] after a state change;
/// this model does not access Android preferences.
final class BrowserSearchHistoryModel {
  BrowserSearchHistoryModel({
    List<BrowserSearchHistoryEntry> entries = const [],
    this.maxEntries = defaultMaxEntries,
  }) : _entries = List.of(entries);

  static const int defaultMaxEntries = 30;

  final int maxEntries;
  List<BrowserSearchHistoryEntry> _entries;

  /// Current entries in most-recently-used order.
  List<BrowserSearchHistoryEntry> get entries => List.unmodifiable(_entries);

  /// Adds a non-empty search at the front, moving an equal entry if present.
  ///
  /// A blank query without filters is skipped. As in the source, a negative
  /// [maxEntries] fails only when a non-empty search reaches the truncation.
  List<BrowserSearchHistoryEntry> addRecent(
    BrowserSearchHistoryEntry entry,
  ) {
    final updatedEntries = List<BrowserSearchHistoryEntry>.of(_entries);
    if (entry.isSearchEmpty) return List.unmodifiable(updatedEntries);

    updatedEntries.remove(entry);
    updatedEntries.insert(0, entry);
    if (maxEntries < 0) {
      throw ArgumentError.value(maxEntries, 'maxEntries');
    }
    _entries = updatedEntries.take(maxEntries).toList();
    return entries;
  }

  /// Removes an equal entry and reports whether it existed.
  bool removeEntry(BrowserSearchHistoryEntry entry) {
    final index = _entries.indexOf(entry);
    if (index == -1) return false;
    _entries.removeAt(index);
    return true;
  }

  /// Removes every history entry.
  void clear() => _entries = [];
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _isKotlinBlank(String value) {
  for (final codeUnit in value.codeUnits) {
    if (!_isKotlinWhitespace(codeUnit)) return false;
  }
  return true;
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
