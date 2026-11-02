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
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Reviewer navigation to the browser, positioned at a card in a deck.
class ReviewerBrowseToCardDirective {
  const ReviewerBrowseToCardDirective({
    required this.deckId,
    required this.cardId,
  });

  final int deckId;
  final int cardId;
}

/// Projects host-resolved IDs to the Reviewer's browse-to-card directive.
///
/// Collection/current-card access, Android destination construction, and
/// navigation remain the host's responsibility.
ReviewerBrowseToCardDirective reviewerBrowseToCardDirective({
  required int deckId,
  required int cardId,
}) => ReviewerBrowseToCardDirective(deckId: deckId, cardId: cardId);
