/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
 * Copyright (c) 2024 Ashish Yadav <mailtoashish693@gmail.com>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2024 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from JSONObject.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Marker for a host-projected `JSONObject.NULL` value.
final class AnkiJsonNull {
  const AnkiJsonNull._();

  static const instance = AnkiJsonNull._();
}

/// The shared Dart representation of `JSONObject.NULL`.
const ankiJsonNull = AnkiJsonNull.instance;

/// Host implementation of `JSONObject.numberToString(Number)`.
typedef JsonNumberToString = String Function(num value);

/// Recursively compares host-projected JSON values like `JSONObject.contentEquals`.
///
/// Objects are string-keyed maps and arrays are lists. Missing sparse-array
/// slots may be represented by [ankiJsonNull]. Number comparison uses the exact
/// host JSON representation to retain JVM number semantics and precision.
bool jsonContentEquals(
  Object? first,
  Object? second, {
  required JsonNumberToString numberToString,
}) {
  if (identical(first, second)) return true;
  if (_isJsonNull(first) || _isJsonNull(second)) {
    return _isJsonNull(first) && _isJsonNull(second);
  }

  if (first is Map && second is Map) {
    if (first.length != second.length) return false;
    for (final key in first.keys) {
      if (!second.containsKey(key) ||
          !jsonContentEquals(
            first[key],
            second[key],
            numberToString: numberToString,
          )) {
        return false;
      }
    }
    return true;
  }

  if (first is List && second is List) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (!jsonContentEquals(
        first[index],
        second[index],
        numberToString: numberToString,
      )) {
        return false;
      }
    }
    return true;
  }

  if (first is num && second is num) {
    return numberToString(first) == numberToString(second);
  }
  return first == second;
}

bool _isJsonNull(Object? value) =>
    value == null || identical(value, ankiJsonNull);
