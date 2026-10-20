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

/// One ordered effect in the Card Browser selected-card flag update plan.
sealed class BrowserSelectedCardsFlagEffect<TCardId, TFlag> {
  const BrowserSelectedCardsFlagEffect();
}

/// Applies [flag] to [cardIds] inside the host's undoable collection operation.
final class BrowserSetSelectedCardsFlagEffect<TCardId, TFlag>
    extends BrowserSelectedCardsFlagEffect<TCardId, TFlag> {
  const BrowserSetSelectedCardsFlagEffect({
    required this.cardIds,
    required this.flag,
  });

  final List<TCardId> cardIds;
  final TFlag flag;
}

/// Emits the source card-state-changed event after the flag write succeeds.
final class BrowserPublishCardStateChangedEffect<TCardId, TFlag>
    extends BrowserSelectedCardsFlagEffect<TCardId, TFlag> {
  const BrowserPublishCardStateChangedEffect();
}

/// Ordered host effects and eventual return value for the source method.
///
/// [selectedCardIds] is retained as supplied and shared with the write effect,
/// matching the source's use and return of the same `idsToChange` list. The
/// host executes [effects] in order, publishes the second effect only after the
/// undoable flag write succeeds, then returns [returnedCardIds]. On write or
/// event-delivery failure, the source method does not reach its return.
final class BrowserSelectedCardsFlagPlan<TCardId, TFlag> {
  BrowserSelectedCardsFlagPlan({
    required this.selectedCardIds,
    required this.flag,
  }) : effects = List.unmodifiable([
          BrowserSetSelectedCardsFlagEffect<TCardId, TFlag>(
            cardIds: selectedCardIds,
            flag: flag,
          ),
          BrowserPublishCardStateChangedEffect<TCardId, TFlag>(),
        ]);

  final List<TCardId> selectedCardIds;
  final TFlag flag;
  final List<BrowserSelectedCardsFlagEffect<TCardId, TFlag>> effects;

  /// The IDs returned by the source method after its effects complete.
  List<TCardId> get returnedCardIds => selectedCardIds;
}

/// Projects `CardBrowserViewModel.updateSelectedCardsFlag(flag)` for a host.
///
/// The host supplies the ordered IDs resolved from the selected rows and the
/// source Flag value. No IDs are filtered, sorted, deduplicated, or special
/// cased: the pinned method still performs the write and emits its change event
/// when the list is empty. Card selection/lookup, the undoable collection write
/// and event delivery remain host-side.
BrowserSelectedCardsFlagPlan<TCardId, TFlag>
    planBrowserSelectedCardsFlagUpdate<TCardId, TFlag>({
  required List<TCardId> selectedCardIds,
  required TFlag flag,
}) =>
        BrowserSelectedCardsFlagPlan<TCardId, TFlag>(
          selectedCardIds: selectedCardIds,
          flag: flag,
        );
