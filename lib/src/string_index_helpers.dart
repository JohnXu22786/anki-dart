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
 * Source-derived from StringUtils.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Host implementation of Kotlin/JVM `Char.equals(ignoreCase = true)`.
///
/// Arguments are UTF-16 code units. This is needed only when a match compares
/// unequal code units with `ignoreCase: true`.
typedef KotlinCharEqualsIgnoreCase = bool Function(int left, int right);

/// Returns the first UTF-16 index of [codeUnit] at or after [startIndex].
int? stringIndexOfOrNull(
  String value,
  int codeUnit, {
  int startIndex = 0,
  bool ignoreCase = false,
  KotlinCharEqualsIgnoreCase? charEqualsIgnoreCase,
}) {
  _checkCodeUnit(codeUnit);
  final units = value.codeUnits;
  final start = startIndex < 0 ? 0 : startIndex;
  if (start >= units.length) return null;

  for (var index = start; index < units.length; index++) {
    if (_matches(units[index], codeUnit, ignoreCase, charEqualsIgnoreCase)) {
      return index;
    }
  }
  return null;
}

/// Returns the last UTF-16 index of [codeUnit] at or before [startIndex].
int? stringLastIndexOfCharOrNull(
  String value,
  int codeUnit, {
  int? startIndex,
  bool ignoreCase = false,
  KotlinCharEqualsIgnoreCase? charEqualsIgnoreCase,
}) {
  _checkCodeUnit(codeUnit);
  final units = value.codeUnits;
  var index = startIndex ?? units.length - 1;
  if (index >= units.length) index = units.length - 1;
  if (index < 0) return null;

  for (; index >= 0; index--) {
    if (_matches(units[index], codeUnit, ignoreCase, charEqualsIgnoreCase)) {
      return index;
    }
  }
  return null;
}

/// Returns the last UTF-16 start index of [needle] at or before [startIndex].
int? stringLastIndexOfOrNull(
  String value,
  String needle, {
  int? startIndex,
  bool ignoreCase = false,
  KotlinCharEqualsIgnoreCase? charEqualsIgnoreCase,
}) {
  final units = value.codeUnits;
  final search = needle.codeUnits;
  final start = startIndex ?? units.length - 1;
  if (start < 0) return null;
  if (search.isEmpty) {
    return start + 1 < units.length ? start + 1 : units.length;
  }
  if (search.length > units.length) return null;

  var index = start;
  final lastPossibleStart = units.length - search.length;
  if (index > lastPossibleStart) index = lastPossibleStart;
  for (; index >= 0; index--) {
    var matches = true;
    for (var offset = 0; offset < search.length; offset++) {
      if (!_matches(
        units[index + offset],
        search[offset],
        ignoreCase,
        charEqualsIgnoreCase,
      )) {
        matches = false;
        break;
      }
    }
    if (matches) return index;
  }
  return null;
}

bool _matches(
  int left,
  int right,
  bool ignoreCase,
  KotlinCharEqualsIgnoreCase? charEqualsIgnoreCase,
) {
  if (left == right) return true;
  if (!ignoreCase) return false;
  final compare = charEqualsIgnoreCase;
  if (compare == null) {
    throw ArgumentError(
      'charEqualsIgnoreCase is required when unequal code units are compared ignoring case',
    );
  }
  return compare(left, right);
}

void _checkCodeUnit(int codeUnit) {
  if (codeUnit < 0 || codeUnit > 0xffff) {
    throw RangeError.range(codeUnit, 0, 0xffff, 'codeUnit');
  }
}
