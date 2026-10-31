/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: `deleteDeck` in DeckPickerViewModel.kt,
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// One ordered host effect in the `deleteDeck` coroutine.
sealed class DeckPickerDeleteDeckEffect {
  const DeckPickerDeleteDeckEffect();
}

/// Removes exactly [deckIds] in the host's undoable operation.
final class DeckPickerRemoveDecks extends DeckPickerDeleteDeckEffect {
  DeckPickerRemoveDecks(Iterable<int> deckIds)
    : deckIds = List.unmodifiable(deckIds);

  final List<int> deckIds;
}

/// Resets focused-deck state to AnkiDroid's default deck ID (1).
final class DeckPickerSetDefaultFocusedDeck extends DeckPickerDeleteDeckEffect {
  const DeckPickerSetDefaultFocusedDeck();
}

/// Publishes the completed deletion result on the host's notification flow.
final class DeckPickerPublishDeckDeletionResult
    extends DeckPickerDeleteDeckEffect {
  const DeckPickerPublishDeckDeletionResult({
    required this.deckName,
    required this.cardsDeleted,
  });

  final String deckName;
  final int cardsDeleted;
}

/// Ordered effects after the host has resolved the deck's non-null name.
///
/// The host must first evaluate `decks.getLegacy(deckId)!!.name` and pass that
/// required name here. This keeps the source's failure before deletion when the
/// deck lookup is absent. The host then runs removal in `undoableOp`, applies
/// the default-focus effect only after removal succeeds, and publishes the
/// result last. A failure stops the coroutine before subsequent effects.
/// Collection access, the source non-null assertion, undo handling, coroutine
/// scheduling, and Flow publication remain host-side.
final class DeckPickerDeleteDeckPlan {
  DeckPickerDeleteDeckPlan(Iterable<DeckPickerDeleteDeckEffect> effects)
    : effects = List.unmodifiable(effects);

  final List<DeckPickerDeleteDeckEffect> effects;
}

/// Projects the successful tail of `deleteDeck` after name resolution.
DeckPickerDeleteDeckPlan planDeckPickerDeleteDeck({
  required int deckId,
  required String deckName,
  required int cardsDeleted,
}) => DeckPickerDeleteDeckPlan([
  DeckPickerRemoveDecks([deckId]),
  const DeckPickerSetDefaultFocusedDeck(),
  DeckPickerPublishDeckDeletionResult(
    deckName: deckName,
    cardsDeleted: cardsDeleted,
  ),
]);
