/*
 * Copyright © 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from LinearLayoutManager.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The inclusive adapter-position range reported by a host layout manager.
///
/// An empty range contains no positions. [empty] represents Kotlin's
/// `IntRange.EMPTY`; [inclusive] retains the supplied endpoints, including a
/// reversed range, whose membership is empty just like Kotlin's `first..last`.
class VisibleItemPositionRange {
  const VisibleItemPositionRange._(this.first, this.last);

  /// Kotlin's `IntRange.EMPTY` value (`1..0`).
  static const empty = VisibleItemPositionRange._(1, 0);

  /// Creates the range produced by Kotlin's inclusive `first..last` operator.
  factory VisibleItemPositionRange.inclusive(int first, int last) =>
      VisibleItemPositionRange._(first, last);

  /// The first endpoint, or `1` for [empty].
  final int first;

  /// The last endpoint, or `0` for [empty].
  final int last;

  /// Whether the range has no values.
  bool get isEmpty => first > last;

  /// Whether [position] is inside this inclusive range.
  bool contains(int position) =>
      !isEmpty && position >= first && position <= last;
}

/// Reads the host layout manager's visible adapter positions in source order.
///
/// The callbacks adapt `findFirstVisibleItemPosition()` and
/// `findLastVisibleItemPosition()`; Android layout state stays host-side. Each
/// callback runs once, first then last. Either `NO_POSITION` value (`-1`) maps
/// to Kotlin's `IntRange.EMPTY`.
VisibleItemPositionRange visibleItemPositions({
  required int Function() findFirstVisibleItemPosition,
  required int Function() findLastVisibleItemPosition,
}) {
  final first = findFirstVisibleItemPosition();
  final last = findLastVisibleItemPosition();
  if (first == -1 || last == -1) return VisibleItemPositionRange.empty;
  return VisibleItemPositionRange.inclusive(first, last);
}

/// Returns whether [position] belongs to the host-reported visible range.
///
/// The two callbacks are evaluated once each, in first-position then
/// last-position order, through [visibleItemPositions].
bool positionIsVisible(
  int position, {
  required int Function() findFirstVisibleItemPosition,
  required int Function() findLastVisibleItemPosition,
}) => visibleItemPositions(
  findFirstVisibleItemPosition: findFirstVisibleItemPosition,
  findLastVisibleItemPosition: findLastVisibleItemPosition,
).contains(position);
