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
 * Behavioral reference: DeckPickerViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// A collection operation in one of the filtered-deck plans.
sealed class DeckPickerFilteredDeckCollectionOperation {
  const DeckPickerFilteredDeckCollectionOperation();
}

/// Selects the supplied deck inside the host's collection operation.
final class DeckPickerSelectFilteredDeck
    extends DeckPickerFilteredDeckCollectionOperation {
  const DeckPickerSelectFilteredDeck(this.deckId);

  final int deckId;
}

/// Empties the deck currently selected by the host inside its scheduler call.
final class DeckPickerEmptySelectedFilteredDeck
    extends DeckPickerFilteredDeckCollectionOperation {
  const DeckPickerEmptySelectedFilteredDeck();
}

/// Rebuilds the deck currently selected by the host inside its scheduler call.
final class DeckPickerRebuildSelectedFilteredDeck
    extends DeckPickerFilteredDeckCollectionOperation {
  const DeckPickerRebuildSelectedFilteredDeck();
}

/// One ordered host action in a filtered-deck operation plan.
sealed class DeckPickerFilteredDeckPlanStep {
  const DeckPickerFilteredDeckPlanStep();
}

/// Runs [operations] sequentially in one host `withCol` collection block.
final class DeckPickerWithCollection extends DeckPickerFilteredDeckPlanStep {
  DeckPickerWithCollection(
    Iterable<DeckPickerFilteredDeckCollectionOperation> operations,
  ) : operations = List.unmodifiable(operations);

  final List<DeckPickerFilteredDeckCollectionOperation> operations;
}

/// Runs the selected-deck operation in a distinct host undoable operation.
final class DeckPickerUndoableOperation extends DeckPickerFilteredDeckPlanStep {
  const DeckPickerUndoableOperation(this.operation);

  final DeckPickerFilteredDeckCollectionOperation operation;
}

/// Publishes the host's deck-counts-changed signal after the operation succeeds.
final class DeckPickerPublishDeckCountsChanged
    extends DeckPickerFilteredDeckPlanStep {
  const DeckPickerPublishDeckCountsChanged();
}

/// Immutable ordered operations for one filtered-deck action.
final class DeckPickerFilteredDeckOperationPlan {
  DeckPickerFilteredDeckOperationPlan(
    Iterable<DeckPickerFilteredDeckPlanStep> steps,
  ) : steps = List.unmodifiable(steps);

  final List<DeckPickerFilteredDeckPlanStep> steps;
}

/// Projects `emptyFilteredDeck`: select in `withCol`, then empty undoably.
///
/// The host passes its collection's currently selected deck ID to the scheduler
/// operation, then publishes the counts-changed signal only after it succeeds.
/// Collection, undo, scheduler, flow, and coroutine behavior remain host-side.
DeckPickerFilteredDeckOperationPlan planDeckPickerEmptyFilteredDeck(
  int deckId,
) => DeckPickerFilteredDeckOperationPlan([
  DeckPickerWithCollection([DeckPickerSelectFilteredDeck(deckId)]),
  const DeckPickerUndoableOperation(DeckPickerEmptySelectedFilteredDeck()),
  const DeckPickerPublishDeckCountsChanged(),
]);

/// Projects `rebuildFilteredDeck`: select and rebuild in one `withCol` block.
///
/// The host passes its collection's currently selected deck ID to the scheduler
/// call, then publishes the counts-changed signal only after the block succeeds.
/// Collection, scheduler, flow, and coroutine behavior remain host-side.
DeckPickerFilteredDeckOperationPlan planDeckPickerRebuildFilteredDeck(
  int deckId,
) => DeckPickerFilteredDeckOperationPlan([
  DeckPickerWithCollection([
    DeckPickerSelectFilteredDeck(deckId),
    const DeckPickerRebuildSelectedFilteredDeck(),
  ]),
  const DeckPickerPublishDeckCountsChanged(),
]);
