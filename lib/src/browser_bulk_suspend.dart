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

/// The bulk operation chosen by AnkiDroid's Card Browser suspend toggle.
enum BrowserBulkSuspendOperation { suspend, unsuspend }

/// The queue-state distinction used by `toggleSuspendCards()`.
///
/// The host maps the source `QueueType.Suspended` to [suspended] and all other
/// queue values to [other].
enum BrowserSuspendQueueState { suspended, other }

/// Projects the suspend or unsuspend operation for `CardBrowserViewModel.toggleSuspendCards`.
///
/// The host checks row selection before resolving the selected card IDs, then
/// supplies those IDs and the queue-state projection. No selected rows returns
/// null without calling [queueForCard]. Otherwise every selected card must be
/// suspended to choose [BrowserBulkSuspendOperation.unsuspend]; a mixed or
/// unsuspended selection chooses [BrowserBulkSuspendOperation.suspend]. The
/// source `all` behavior means selected rows that resolve to no card IDs choose
/// unsuspend. If [queueForCard] reads collection state, call this function
/// inside the host's undoable operation before dispatching the scheduler call.
/// This function does not report a result because the source method does not.
BrowserBulkSuspendOperation? planBrowserBulkSuspendToggle<T>({
  required bool hasSelectedRows,
  required List<T> selectedCardIds,
  required BrowserSuspendQueueState Function(T cardId) queueForCard,
}) {
  if (!hasSelectedRows) return null;

  final wantUnsuspend = selectedCardIds.every(
    (cardId) => queueForCard(cardId) == BrowserSuspendQueueState.suspended,
  );
  return wantUnsuspend
      ? BrowserBulkSuspendOperation.unsuspend
      : BrowserBulkSuspendOperation.suspend;
}
