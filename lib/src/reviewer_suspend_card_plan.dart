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

/// One ordered host effect from the Reviewer's suspend-card action.
sealed class ReviewerSuspendCardEffect {
  const ReviewerSuspendCardEffect();
}

/// Requests suspending the single current card with [cardId].
final class SuspendReviewerCardEffect extends ReviewerSuspendCardEffect {
  const SuspendReviewerCardEffect(this.cardId);

  final int cardId;
}

/// Delivers the host-localized suspension feedback [message].
final class ShowReviewerSuspendFeedbackEffect
    extends ReviewerSuspendCardEffect {
  const ShowReviewerSuspendFeedbackEffect(this.message);

  final String message;
}

/// Requests reloading the Reviewer's current card after suspension succeeds.
final class ReloadReviewerCurrentCardEffect extends ReviewerSuspendCardEffect {
  const ReloadReviewerCurrentCardEffect();
}

/// Projects `ReviewerViewModel.suspendCard()` into its ordered host effects.
///
/// The host performs each effect in order and stops if suspending the card
/// fails, so feedback and the current-card reload occur only after success.
/// The host supplies the current card ID and localized message; scheduler and
/// collection access, localization, flow delivery, and reloading stay host-side.
/// The source discards the scheduler's suspend count, so the plan carries none.
List<ReviewerSuspendCardEffect> planReviewerSuspendCard({
  required int cardId,
  required String suspendedMessage,
}) => List.unmodifiable([
  SuspendReviewerCardEffect(cardId),
  ShowReviewerSuspendFeedbackEffect(suspendedMessage),
  const ReloadReviewerCurrentCardEffect(),
]);
