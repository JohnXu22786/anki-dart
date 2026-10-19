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
 * Behavioral reference: CardBrowserSearchViewModel.kt, SearchFilters.kt, and
 * SearchRequest.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'browser_search_history.dart';

/// A host-supplied deck name and its stable collection ID.
final class BrowserDeckNameId {
  const BrowserDeckNameId({required this.name, required this.id});

  final String name;
  final int id;
}

/// A host-supplied note type name and its stable collection ID.
final class BrowserNoteTypeNameId {
  const BrowserNoteTypeNameId({required this.name, required this.id});

  final String name;
  final int id;
}

/// Structured Card Browser filters independent of query-string generation.
final class BrowserSearchFilters {
  const BrowserSearchFilters({
    this.decks = const [],
    this.flags = const [],
    this.tags = const [],
    this.noteTypes = const [],
    this.cardStateCodes = const [],
  });

  final List<BrowserDeckNameId> decks;
  final List<int> flags;
  final List<String> tags;
  final List<BrowserNoteTypeNameId> noteTypes;
  final List<int> cardStateCodes;

  /// Resolves stored IDs against host-provided mappings.
  ///
  /// The source resolves each ID with the first equal mapping, preserving entry
  /// order and duplicates. It returns null if any ID is absent.
  static BrowserSearchFilters? fromHistoryEntry(
    BrowserSearchHistoryEntry entry, {
    required List<BrowserDeckNameId> deckNameMap,
    required List<BrowserNoteTypeNameId> noteTypeMap,
  }) {
    final decks = <BrowserDeckNameId>[];
    for (final id in entry.deckIds) {
      BrowserDeckNameId? match;
      for (final deck in deckNameMap) {
        if (deck.id == id) {
          match = deck;
          break;
        }
      }
      if (match == null) return null;
      decks.add(match);
    }

    final noteTypes = <BrowserNoteTypeNameId>[];
    for (final id in entry.noteTypeIds) {
      BrowserNoteTypeNameId? match;
      for (final noteType in noteTypeMap) {
        if (noteType.id == id) {
          match = noteType;
          break;
        }
      }
      if (match == null) return null;
      noteTypes.add(match);
    }

    return BrowserSearchFilters(
      decks: decks,
      flags: entry.flags,
      tags: entry.tags,
      noteTypes: noteTypes,
      cardStateCodes: entry.cardStateCodes,
    );
  }
}

/// A query and structured Card Browser filters, without backend execution.
final class BrowserSearchRequest {
  const BrowserSearchRequest({
    required this.query,
    this.filters = const BrowserSearchFilters(),
  });

  final String query;
  final BrowserSearchFilters filters;

  /// Restores a request from history using current host-supplied name maps.
  ///
  /// The stored query is carried through unchanged. Query validation and
  /// backend SearchNode/string generation remain with the host.
  static BrowserSearchRequest? fromHistoryEntry(
    BrowserSearchHistoryEntry entry, {
    required List<BrowserDeckNameId> deckNameMap,
    required List<BrowserNoteTypeNameId> noteTypeMap,
  }) {
    final filters = BrowserSearchFilters.fromHistoryEntry(
      entry,
      deckNameMap: deckNameMap,
      noteTypeMap: noteTypeMap,
    );
    if (filters == null) return null;
    return BrowserSearchRequest(query: entry.query, filters: filters);
  }

  /// Converts a request to the stable ID-based history format.
  BrowserSearchHistoryEntry toHistoryEntry() => BrowserSearchHistoryEntry(
        query: _trimKotlinWhitespace(query),
        deckIds: filters.decks.map((deck) => deck.id).toList(growable: false),
        flags: filters.flags,
        tags: filters.tags,
        noteTypeIds: filters.noteTypes
            .map((noteType) => noteType.id)
            .toList(growable: false),
        cardStateCodes: filters.cardStateCodes,
      );
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
