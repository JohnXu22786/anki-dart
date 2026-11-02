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
 * Source-derived from NonLeadingZeroInputFilter.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Returns the filter replacement for the source range, or `null` to accept it.
///
/// The destination range is replaced with the selected source range before the
/// resulting text is checked, matching Android's `InputFilter` decision. Dart
/// string offsets and lengths use UTF-16 code units, as does the Kotlin source.
String? nonLeadingZeroInputFilter({
  required String source,
  required int start,
  required int end,
  required String destination,
  required int destinationStart,
  required int destinationEnd,
}) {
  final result = destination.replaceRange(
    destinationStart,
    destinationEnd,
    source.substring(start, end),
  );
  return result.length > 1 && result.startsWith('0') ? '' : null;
}
