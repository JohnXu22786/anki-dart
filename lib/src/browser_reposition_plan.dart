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

/// Host-resolved type and queue state for a selected browser card.
class BrowserRepositionCardState {
  const BrowserRepositionCardState({
    required this.cardId,
    required this.hasNewType,
    required this.hasNewQueue,
  });

  final int cardId;
  final bool hasNewType;
  final bool hasNewQueue;

  /// Matches AnkiDroid's `card.type == New || card.queue == New` predicate.
  bool get isRepositionable => hasNewType || hasNewQueue;
}

/// Pure result of partitioning selected cards for repositioning.
sealed class BrowserRepositionPlan {
  const BrowserRepositionPlan();
}

/// Source `NoRepositionableCardsError` result.
final class BrowserNoRepositionableCards extends BrowserRepositionPlan {
  const BrowserNoRepositionableCards();
}

/// Ordered card groups and the exact count of skipped cards.
final class BrowserRepositionCards extends BrowserRepositionPlan {
  BrowserRepositionCards({
    required List<int> repositionableCardIds,
    required List<int> skippedCardIds,
  }) : repositionableCardIds = List.unmodifiable(repositionableCardIds),
       skippedCardIds = List.unmodifiable(skippedCardIds),
       unsupportedCardCount = skippedCardIds.length;

  final List<int> repositionableCardIds;
  final List<int> skippedCardIds;

  /// Equivalent to AnkiDroid's `UnsupportedCardCount.Count(value)`.
  final int unsupportedCardCount;
}

/// Plans AnkiDroid's selected-card repositionability partition.
///
/// [selectedCards] must be supplied in the source selected-row order, with the
/// card type and queue predicates already resolved by the host. Both output
/// lists retain that order. If none qualify, the source returns its error even
/// though the full scan may have produced skipped IDs.
BrowserRepositionPlan planBrowserRepositionCards({
  required Iterable<BrowserRepositionCardState> selectedCards,
}) {
  final repositionableCardIds = <int>[];
  final skippedCardIds = <int>[];

  for (final card in selectedCards) {
    if (card.isRepositionable) {
      repositionableCardIds.add(card.cardId);
    } else {
      skippedCardIds.add(card.cardId);
    }
  }

  if (repositionableCardIds.isEmpty) {
    return const BrowserNoRepositionableCards();
  }

  return BrowserRepositionCards(
    repositionableCardIds: repositionableCardIds,
    skippedCardIds: skippedCardIds,
  );
}
