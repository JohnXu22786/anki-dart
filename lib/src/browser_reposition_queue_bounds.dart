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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Queue bounds normalized by AnkiDroid's `RepositionData` constructor.
class BrowserRepositionQueueBounds {
  const BrowserRepositionQueueBounds({
    required this.queueTop,
    required this.queueBottom,
  });

  final int? queueTop;
  final int? queueBottom;
}

/// Projects the source constructor's nullable min/max normalization.
///
/// When both values are present, the lower value becomes [queueTop] and the
/// higher becomes [queueBottom]. If either is absent, both output bounds are
/// null. Values are preserved without validation or clamping.
BrowserRepositionQueueBounds projectBrowserRepositionQueueBounds({
  required int? min,
  required int? max,
}) {
  if (min == null || max == null) {
    return const BrowserRepositionQueueBounds(
      queueTop: null,
      queueBottom: null,
    );
  }

  return BrowserRepositionQueueBounds(
    queueTop: min <= max ? min : max,
    queueBottom: min <= max ? max : min,
  );
}
