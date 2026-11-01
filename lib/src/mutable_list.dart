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
 * Behavioral reference: AnkiDroid's MutableList.kt, pinned at 2.25.3 commit
 * d9bf072f814a0c37d30a694192593b31ff2df875; see ANKIIDROID_UPSTREAM.md.
 */

/// Mutable-list operations adapted from AnkiDroid.
extension MutableListSwapPositions<T> on List<T> {
  /// Moves the item at [fromPosition] to [toPosition] by swapping neighbors.
  ///
  /// Positions are not validated or normalized. An invalid position fails
  /// naturally when an adjacent swap accesses it. Equal positions ordinarily
  /// do nothing; `Int.MAX_VALUE` preserves Kotlin's range-overflow behavior.
  void swapPositions(int fromPosition, int toPosition) {
    if (fromPosition < toPosition) {
      for (var position = fromPosition; position < toPosition; position++) {
        _swapPositions(position, position + 1);
      }
    } else {
      // Kotlin evaluates `toPosition + 1` as a signed 32-bit Int before
      // constructing its descending range, so Int.MAX_VALUE wraps to MIN_VALUE.
      final endPosition = toPosition == 0x7fffffff
          ? -0x80000000
          : toPosition + 1;
      for (var position = fromPosition; position >= endPosition; position--) {
        _swapPositions(position, position - 1);
      }
    }
  }

  void _swapPositions(int firstPosition, int secondPosition) {
    final first = this[firstPosition];
    final second = this[secondPosition];
    // java.util.Collections.swap sets the second position before the first.
    this[secondPosition] = first;
    this[firstPosition] = second;
  }
}
