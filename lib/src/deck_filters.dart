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

import 'locale_lowercase.dart';

/// A deck search query with AnkiDroid's token and path matching rules.
class DeckFilters {
  DeckFilters._(this._filters, this._localeName, this._localeNameProvider);

  final List<DeckFilter> _filters;
  final String? _localeName;
  final String Function() _localeNameProvider;

  String get _localeNameForMatching => _localeName ?? _localeNameProvider();

  /// Whether the user supplied at least one non-empty search token.
  bool isActive() => _filters.isNotEmpty;

  /// Whether every token occurs in [name].
  bool deckNamesMatchFilters(String name) => _filters.every(
      (filter) => filter.deckNameMatchesFilter(name, _localeNameForMatching));

  /// Whether at least one token matches the last deck-name component.
  bool deckLastNameMatchesAFilter(String name) => _filters.any(
        (filter) =>
            filter.deckLastNameMatchesFilter(name, _localeNameForMatching),
      );

  /// Whether a deck should remain visible for this query.
  bool accept(String name) =>
      !isActive() ||
      (deckLastNameMatchesAFilter(name) && deckNamesMatchFilters(name));

  /// Parses query tokens with locale-invariant lowercase casing. A non-empty
  /// [localeName] pins deck-name casing to that locale; otherwise, the current
  /// platform locale is read when matching. Supply [localeNameProvider] when
  /// the host application has its own changing locale.
  static DeckFilters create(
    String filters, {
    String localeName = '',
    String Function()? localeNameProvider,
  }) {
    final tokens = unicodeLowercase(filters)
        .split(RegExp(r'[ \t\n\x0B\f\r]+'))
        .map(_trimKotlinWhitespace)
        .where((filter) => filter.isNotEmpty)
        .map(DeckFilter.new)
        .toList(growable: false);

    return DeckFilters._(
      tokens,
      localeName.isEmpty ? null : localeName,
      localeNameProvider ?? (() => Platform.localeName),
    );
  }
}

String _trimKotlinWhitespace(String value) {
  // Kotlin/JVM Char.isWhitespace includes separator and C0 whitespace
  // characters, but excludes U+0085 NEXT LINE unlike Dart's String.trim().
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
    final localeLoweredName = localeLowercase(name, localeName);
    final rootLowercase = unicodeLowercase(name);

    return localeLoweredName.contains(filter) ||
        rootLowercase.contains(filter) ||
        localeLoweredName.endsWith(trimmedFilter) ||
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
