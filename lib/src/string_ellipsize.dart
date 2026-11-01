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

/// Host BreakIterator calculation used by `StringUtils.ellipsize()`.
///
/// Return the last grapheme boundary at or before [maxChars], using the pinned
/// `BreakIterator.getCharacterInstance(Locale.ROOT)` behavior.
typedef LastSafeGraphemeBoundary = int Function(String value, int maxChars);

/// Truncates [value] at the last host grapheme boundary at or below [threshold].
String ellipsize(
  String value, {
  required int threshold,
  required LastSafeGraphemeBoundary lastSafeBoundary,
}) {
  if (threshold <= 0) {
    throw ArgumentError('invalid length: $threshold');
  }
  if (value.length <= threshold) return value;

  final boundary = lastSafeBoundary(value, threshold);
  return '${value.substring(0, boundary)}…';
}
