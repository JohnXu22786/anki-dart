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
 * Behavioral reference: Kotlin String.trim() semantics used by
 * CardBrowserSearchViewModel.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Trims the UTF-16 code units Kotlin/JVM `String.trim()` treats as whitespace.
String trimKotlinWhitespace(String value) {
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
