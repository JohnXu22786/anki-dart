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
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The source entry point supplied when opening current-card information.
enum ReviewerCardInfoEntryPoint { CURRENT_CARD_STUDY }

/// Source-mapped arguments for the Reviewer's current-card info destination.
class ReviewerCurrentCardInfoDestination {
  const ReviewerCurrentCardInfoDestination({
    required this.cardId,
    required this.entryPoint,
  });

  /// The host-resolved card ID, retained exactly as supplied.
  final int cardId;

  /// The source `EntryPoint.CURRENT_CARD_STUDY` value.
  final ReviewerCardInfoEntryPoint entryPoint;
}

/// Pairs the host-resolved current card ID with the source study entry point.
///
/// The host resolves the current card and constructs/navigates to its concrete
/// `CardInfoDestination`; Android and lifecycle handling remain host-side.
ReviewerCurrentCardInfoDestination reviewerCurrentCardInfoDestination({
  required int cardId,
}) => ReviewerCurrentCardInfoDestination(
  cardId: cardId,
  entryPoint: ReviewerCardInfoEntryPoint.CURRENT_CARD_STUDY,
);
