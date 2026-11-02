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

/// The host feedback or navigation choice for previous-card info.
sealed class ReviewerPreviousCardInfoDirective {
  const ReviewerPreviousCardInfoDirective();
}

/// Host-localized feedback shown when no previous card ID is available.
final class ReviewerPreviousCardInfoFeedback
    extends ReviewerPreviousCardInfoDirective {
  const ReviewerPreviousCardInfoFeedback(this.message);

  final String message;
}

/// Navigation to card info for the supplied previous card ID.
final class ReviewerPreviousCardInfoNavigation
    extends ReviewerPreviousCardInfoDirective {
  const ReviewerPreviousCardInfoNavigation(this.cardId);

  final int cardId;
}

/// Selects feedback for a missing previous card ID or navigation for any ID.
///
/// The host supplies the saved-state value and localized message and remains
/// responsible for destination construction, navigation, and feedback delivery.
ReviewerPreviousCardInfoDirective reviewerPreviousCardInfoDirective({
  required int? previousCardId,
  required String noCardMessage,
}) => switch (previousCardId) {
  null => ReviewerPreviousCardInfoFeedback(noCardMessage),
  final cardId => ReviewerPreviousCardInfoNavigation(cardId),
};
