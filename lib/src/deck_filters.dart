/*
 * Copyright (c) 2026 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-FileCopyrightText: 2026 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Dart adaptation of AnkiDroid's DeckFilters.kt from the pinned upstream
 * revision recorded in ANKIDROID_UPSTREAM.md.
 */

import 'dart:io' show Platform;

/// A deck search query with AnkiDroid's token and path matching rules.
class DeckFilters {
  DeckFilters._(this._filters, this._localeName);

  final List<DeckFilter> _filters;
  final String _localeName;

  /// Whether the user supplied at least one non-empty search token.
  bool isActive() => _filters.isNotEmpty;

  /// Whether every token occurs in [name].
  bool deckNamesMatchFilters(String name) => _filters
      .every((filter) => filter.deckNameMatchesFilter(name, _localeName));

  /// Whether at least one token matches the last deck-name component.
  bool deckLastNameMatchesAFilter(String name) => _filters.any(
        (filter) => filter.deckLastNameMatchesFilter(name, _localeName),
      );

  /// Whether a deck should remain visible for this query.
  bool accept(String name) =>
      !isActive() ||
      (deckLastNameMatchesAFilter(name) && deckNamesMatchFilters(name));

  /// Parses a query. [localeName] may be supplied by the host app when it
  /// observes a locale change; the native platform locale is used by default.
  static DeckFilters create(
    String filters, {
    String localeName = '',
  }) {
    final effectiveLocale =
        localeName.isEmpty ? Platform.localeName : localeName;
    final tokens = filters
        .toLowerCase()
        .split(RegExp(r'[ \t\n\x0B\f\r]+'))
        .map((filter) => filter.trim())
        .where((filter) => filter.isNotEmpty)
        .map(DeckFilter.new)
        .toList(growable: false);

    return DeckFilters._(tokens, effectiveLocale);
  }
}

/// A single token in a [DeckFilters] query.
class DeckFilter {
  DeckFilter(this.filter)
      : endsWithSingleColon = filter.endsWith(':') && !filter.endsWith('::'),
        trimmedFilter = filter.endsWith(':') && !filter.endsWith('::')
            ? filter.replaceAll(RegExp(r':+$'), '')
            : filter;

  final String filter;
  final bool endsWithSingleColon;
  final String trimmedFilter;

  /// Whether [name] contains this token or ends with its partial-colon prefix.
  bool deckNameMatchesFilter(String name, [String localeName = '']) {
    final localeLowercase = _lowercaseForLocale(name, localeName);
    final rootLowercase = name.toLowerCase();

    return localeLowercase.contains(filter) ||
        rootLowercase.contains(filter) ||
        localeLowercase.endsWith(trimmedFilter) ||
        rootLowercase.endsWith(trimmedFilter);
  }

  /// Whether this token matches a deck's last path component.
  bool deckLastNameMatchesFilter(String name, [String localeName = '']) {
    final filterSeparator = filter.lastIndexOf('::');
    if (filterSeparator == -1) {
      return deckNameMatchesFilter(name.split('::').last, localeName);
    }

    final nameSeparator = name.lastIndexOf('::');
    if (nameSeparator == -1) {
      return false;
    }

    return containsAtPosition(
      trimmedFilter,
      filterSeparator,
      name,
      nameSeparator,
    );
  }

  /// Compares equal-length path fragments using Java's character-wise
  /// case-insensitive comparison used by the upstream implementation.
  static bool containsAtPosition(
    String contained,
    int positionContained,
    String containing,
    int positionContaining,
  ) {
    final start = positionContaining - positionContained;
    final end = start + contained.length;
    if (start < 0 || end > containing.length) {
      return false;
    }

    return _equalsIgnoreCase(
      containing.substring(start, end),
      contained,
    );
  }
}

String _lowercaseForLocale(String value, String localeName) {
  final language =
      localeName.replaceAll('_', '-').split('-').first.toLowerCase();
  if (language == 'tr' || language == 'az') {
    return value.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
  }
  return value.toLowerCase();
}

bool _equalsIgnoreCase(String left, String right) {
  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index++) {
    final leftUnit = left.codeUnitAt(index);
    final rightUnit = right.codeUnitAt(index);
    if (leftUnit == rightUnit) {
      continue;
    }

    final leftUpper = _upperCaseUnit(leftUnit);
    final rightUpper = _upperCaseUnit(rightUnit);
    if (leftUpper == rightUpper) {
      continue;
    }

    if (_lowerCaseUnit(leftUpper) != _lowerCaseUnit(rightUpper)) {
      return false;
    }
  }

  return true;
}

int _upperCaseUnit(int unit) {
  final uppercase = String.fromCharCode(unit).toUpperCase();
  return uppercase.length == 1 ? uppercase.codeUnitAt(0) : unit;
}

int _lowerCaseUnit(int unit) {
  if (unit == 0x0130) {
    return 0x0069;
  }

  final lowercase = String.fromCharCode(unit).toLowerCase();
  return lowercase.length == 1 ? lowercase.codeUnitAt(0) : unit;
}
