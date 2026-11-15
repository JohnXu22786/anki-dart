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

/// The pure result values projected by AnkiDroid's Card Browser bury toggle.
///
/// [wasBuried] is true when the selected operation is to bury; false means
/// unbury. The host should expose this result only after its undoable operation
/// succeeds, matching the source method's return timing.
final class BrowserBulkBuryPlan {
  const BrowserBulkBuryPlan({required this.wasBuried, required this.count});

  final bool wasBuried;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is BrowserBulkBuryPlan &&
      other.wasBuried == wasBuried &&
      other.count == count;

  @override
  int get hashCode => Object.hash(wasBuried, count);
}

/// Queue categories used by `Card.isBuried()` in the pinned source.
///
/// The host maps source queue values to these categories; every other queue
/// maps to [other].
enum BrowserBuryQueueState {
  other,
  manuallyBuried,
  siblingBuried;

  bool get isBuried => this == manuallyBuried || this == siblingBuried;
}

/// Projects the operation and result values for `CardBrowserViewModel.toggleBury`.
///
/// The host first checks whether rows are selected, then supplies the resulting
/// ordered card IDs and a queue-state projection. The host maps source
/// `ManuallyBuried` and `SiblingBuried` to their matching
/// [BrowserBuryQueueState] values and all other queue values to
/// [BrowserBuryQueueState.other]. No selected rows returns null before this
/// function inspects IDs or queue states. Otherwise, all selected cards must be
/// buried to select unbury; any unburied card selects bury. The source `all`
/// behavior means an empty ID list with selected rows selects unbury and
/// returns count 0.
/// If [queueForCard] reads collection state, the host should call this inside
/// its undoable operation before dispatching the matching scheduler action. The
/// host only reports the plan as a result if that operation succeeds.
BrowserBulkBuryPlan? planBrowserBulkBuryToggle<T>({
  required bool hasSelectedRows,
  required List<T> selectedCardIds,
  required BrowserBuryQueueState Function(T cardId) queueForCard,
}) {
  if (!hasSelectedRows) return null;

  final wantUnbury =
      selectedCardIds.every((cardId) => queueForCard(cardId).isBuried);
  return BrowserBulkBuryPlan(
    wasBuried: !wantUnbury,
    count: selectedCardIds.length,
  );
}
