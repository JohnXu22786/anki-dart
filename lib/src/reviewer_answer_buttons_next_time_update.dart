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
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'review_presentation.dart';

/// The pure outcome of Reviewer `updateNextTimes()` after host lookups finish.
sealed class ReviewerAnswerButtonsNextTimeUpdate {
  const ReviewerAnswerButtonsNextTimeUpdate();
}

/// The Reviewer should leave its published answer-button times unchanged.
final class NoReviewerAnswerButtonsNextTimeUpdate
    extends ReviewerAnswerButtonsNextTimeUpdate {
  const NoReviewerAnswerButtonsNextTimeUpdate();
}

/// The Reviewer should publish [nextTimes] without recalculating it.
final class PublishReviewerAnswerButtonsNextTime
    extends ReviewerAnswerButtonsNextTimeUpdate {
  const PublishReviewerAnswerButtonsNextTime({required this.nextTimes});

  final AnswerButtonsNextTime nextTimes;
}

/// Projects the source's visibility and nullable queue-state gates.
///
/// The host resolves `shouldShowNextTimes`, reads the queue state, and computes
/// [nextTimes] with `AnswerButtonsNextTime.from`. This helper only decides
/// whether that already-computed value should be published. In the source,
/// `updateNextTimes()` returns when times are hidden or the queue state is null,
/// then emits the calculated value to `answerButtonsNextTimeFlow`.
ReviewerAnswerButtonsNextTimeUpdate projectReviewerAnswerButtonsNextTimeUpdate({
  required bool shouldShowNextTimes,
  required AnswerButtonsNextTime? nextTimes,
}) {
  if (!shouldShowNextTimes || nextTimes == null) {
    return const NoReviewerAnswerButtonsNextTimeUpdate();
  }

  return PublishReviewerAnswerButtonsNextTime(nextTimes: nextTimes);
}
