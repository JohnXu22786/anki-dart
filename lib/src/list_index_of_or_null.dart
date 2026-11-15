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
 * Source-derived from List.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// List search operations adapted from AnkiDroid.
extension ListIndexOfOrNull<T> on List<T> {
  /// Returns the index of the first value matched by [predicate], or `null`.
  ///
  /// Values are visited in list order until the first match. [predicate] is
  /// called once per visited value and is not called after a match. Exceptions
  /// from [predicate] propagate unchanged.
  int? indexOfOrNull(bool Function(T) predicate) {
    var index = 0;
    for (final value in this) {
      if (predicate(value)) return index;
      index++;
    }
    return null;
  }
}
