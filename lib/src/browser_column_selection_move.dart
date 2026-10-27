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
 * Behavioral reference: BrowserColumnSelectionAdapter.kt and MutableList.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Movement capability assigned to a Browser Column Selection row.
///
/// AnkiDroid disables dragging its usage-heading rows and allows other rows to
/// move vertically. The host maps its Android view type to [isUsageItem] and
/// supplies the actual RecyclerView movement flags.
enum BrowserColumnSelectionDragMode { disabled, vertical }

/// Returns the source-equivalent movement capability for a row.
BrowserColumnSelectionDragMode browserColumnSelectionDragMode({
  required bool isUsageItem,
}) =>
    isUsageItem
        ? BrowserColumnSelectionDragMode.disabled
        : BrowserColumnSelectionDragMode.vertical;

/// One adjacent pair passed to Kotlin's `Collections.swap` by `swapPositions`.
final class BrowserColumnPositionSwap {
  const BrowserColumnPositionSwap(this.firstPosition, this.secondPosition);

  final int firstPosition;
  final int secondPosition;

  @override
  bool operator ==(Object other) =>
      other is BrowserColumnPositionSwap &&
      other.firstPosition == firstPosition &&
      other.secondPosition == secondPosition;

  @override
  int get hashCode => Object.hash(firstPosition, secondPosition);
}

/// The host-facing decision and ordered swaps for one `onMove` callback.
///
/// Apply [adjacentSwaps] to the host's mutable list in order when [accepted] is
/// true, then send the RecyclerView move notification if an adapter is present.
/// This plan deliberately does not validate the supplied adapter positions.
final class BrowserColumnSelectionMovePlan {
  const BrowserColumnSelectionMovePlan({
    required this.accepted,
    required this.fromPosition,
    required this.toPosition,
  });

  final bool accepted;
  final int fromPosition;
  final int toPosition;

  /// Lazily enumerates the exact swap calls made by source `swapPositions`.
  ///
  /// Keeping this sequence lazy also leaves invalid-position failures to the
  /// host as it applies swaps, rather than validating or normalizing them here.
  Iterable<BrowserColumnPositionSwap> get adjacentSwaps sync* {
    if (!accepted) return;

    if (fromPosition < toPosition) {
      for (var position = fromPosition; position < toPosition; position++) {
        yield BrowserColumnPositionSwap(position, position + 1);
      }
    } else {
      for (var position = fromPosition; position > toPosition; position--) {
        yield BrowserColumnPositionSwap(position, position - 1);
      }
    }
  }
}

/// Projects `BrowserColumnSelectionTouchHelperCallback.onMove` without Android.
///
/// The source rejects only a target position of zero. For every other target it
/// reports success and invokes `swapPositions`, which crosses the interval via
/// ordered adjacent swaps; moving an item to itself is therefore accepted with
/// no swaps. The host applies the plan and owns UI notifications and lifecycle.
BrowserColumnSelectionMovePlan planBrowserColumnSelectionMove({
  required int fromPosition,
  required int toPosition,
}) {
  if (toPosition == 0) {
    return BrowserColumnSelectionMovePlan(
      accepted: false,
      fromPosition: fromPosition,
      toPosition: toPosition,
    );
  }

  return BrowserColumnSelectionMovePlan(
    accepted: true,
    fromPosition: fromPosition,
    toPosition: toPosition,
  );
}
