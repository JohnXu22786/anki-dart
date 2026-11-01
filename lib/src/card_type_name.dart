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
 * Source-derived from CardTypeName.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'kotlin_string_hash_code.dart';
import 'kotlin_whitespace.dart';
import 'locale_lowercase.dart';
import 'unicode_15_simple_case_mappings.dart';

/// A card type name with AnkiDroid's source-defined string behavior.
///
/// This value wrapper does not validate names or resolve duplicate names.
final class CardTypeName {
  CardTypeName._(this.value);

  /// The value after the source's Kotlin `String.trim()` operation.
  final String value;

  /// Creates a name using Kotlin `String.trim()` semantics.
  factory CardTypeName.fromString(String value) =>
      CardTypeName._(trimKotlinWhitespace(value));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CardTypeName) return false;
    return _equalsKotlinIgnoreCase(value, other.value);
  }

  @override
  int get hashCode => kotlinStringHashCode(unicodeLowercase(value));

  @override
  String toString() => value;
}

bool _equalsKotlinIgnoreCase(String left, String right) {
  if (left.length != right.length) return false;

  for (var index = 0; index < left.length; index++) {
    final leftUnit = left.codeUnitAt(index);
    final rightUnit = right.codeUnitAt(index);
    if (leftUnit == rightUnit) continue;

    final leftUpper = _upperCaseUnit(leftUnit);
    final rightUpper = _upperCaseUnit(rightUnit);
    if (leftUpper == rightUpper) continue;

    if (_lowerCaseUnit(leftUpper) != _lowerCaseUnit(rightUpper)) return false;
  }

  return true;
}

int _upperCaseUnit(int unit) => unicode15SimpleUppercaseMappings[unit] ?? unit;

int _lowerCaseUnit(int unit) => unicode15SimpleLowercaseMappings[unit] ?? unit;
