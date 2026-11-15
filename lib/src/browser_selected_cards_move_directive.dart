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
 * Behavioral reference: CardBrowserViewModel.moveSelectedCardsToDeck() in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// One host operation from `CardBrowserViewModel.moveSelectedCardsToDeck`.
final class BrowserSetCardsDeckEffect<TCardId, TDeckId> {
  const BrowserSetCardsDeckEffect({
    required this.cardIds,
    required this.deckId,
  });

  /// The exact ordered IDs resolved by the host from the selected rows.
  final List<TCardId> cardIds;

  /// The exact destination deck ID supplied to the source method.
  final TDeckId deckId;
}

/// The source operation directive for moving selected cards to one deck.
final class BrowserSelectedCardsMoveDirective<TCardId, TDeckId> {
  BrowserSelectedCardsMoveDirective({
    required this.selectedCardIds,
    required this.deckId,
  }) : effects = List.unmodifiable([
         BrowserSetCardsDeckEffect<TCardId, TDeckId>(
           cardIds: selectedCardIds,
           deckId: deckId,
         ),
       ]);

  /// The host-resolved card IDs, retained by reference and in supplied order.
  final List<TCardId> selectedCardIds;

  /// The exact target deck ID.
  final TDeckId deckId;

  /// The single undoable `setDeck(selectedCardIds, deckId)` host operation.
  final List<BrowserSetCardsDeckEffect<TCardId, TDeckId>> effects;
}

/// Projects `CardBrowserViewModel.moveSelectedCardsToDeck(deckId)`.
///
/// The host supplies card IDs resolved from selected rows. The source performs
/// one undoable `setDeck` operation with those IDs and the exact target deck ID,
/// then returns its result. This directive neither looks up selection nor
/// executes the collection operation.
BrowserSelectedCardsMoveDirective<TCardId, TDeckId>
planBrowserSelectedCardsMove<TCardId, TDeckId>({
  required List<TCardId> selectedCardIds,
  required TDeckId deckId,
}) => BrowserSelectedCardsMoveDirective<TCardId, TDeckId>(
  selectedCardIds: selectedCardIds,
  deckId: deckId,
);

/// Returns the host's `setDeck` result unchanged, matching the source return.
TResult completeBrowserSelectedCardsMove<TResult>(TResult operationResult) =>
    operationResult;
