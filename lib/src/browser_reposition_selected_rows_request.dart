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

/// Scheduler arguments for repositioning the selected Card Browser rows.
final class BrowserRepositionSelectedRowsRequest {
  const BrowserRepositionSelectedRowsRequest({
    required this.selectedCardIds,
    required this.position,
    required this.step,
    required this.shuffle,
    required this.shift,
  });

  /// Host-resolved card IDs in the order supplied to `sched.sortCards`.
  final List<int> selectedCardIds;

  /// Exact `position` argument supplied by the host.
  final int position;

  /// Exact `step` argument supplied by the host.
  final int step;

  /// Exact `shuffle` argument supplied by the host.
  final bool shuffle;

  /// Exact `shift` argument supplied by the host.
  final bool shift;
}

/// Projects `CardBrowserViewModel.repositionSelectedRows` scheduler arguments.
///
/// The host supplies IDs already resolved from selected rows and owns selection,
/// coroutine and undo/backend execution. This request preserves the ID list and
/// each argument as supplied; it does not run or model scheduler behavior.
BrowserRepositionSelectedRowsRequest planBrowserRepositionSelectedRows({
  required List<int> selectedCardIds,
  required int position,
  required int step,
  required bool shuffle,
  required bool shift,
}) => BrowserRepositionSelectedRowsRequest(
  selectedCardIds: selectedCardIds,
  position: position,
  step: step,
  shuffle: shuffle,
  shift: shift,
);

/// Returns the host scheduler's reposition count unchanged.
TResult completeBrowserRepositionSelectedRows<TResult>(
  TResult schedulerResult,
) => schedulerResult;
