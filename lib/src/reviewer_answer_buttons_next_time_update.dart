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

import 'dart:async';

import 'review_presentation.dart';
import 'review_session.dart';

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

/// Runs the source-ordered host lookups for `ReviewerViewModel.updateNextTimes`.
///
/// Awaits [shouldShowNextTimes] first. A false result skips both remaining
/// callbacks; a null [currentQueueState] skips [computeNextTimes]. Otherwise,
/// it passes the identical queue state to [computeNextTimes] exactly once and
/// publishes that callback's exact result. Callback failures propagate
/// unchanged and stop later work.
///
/// The host supplies preference, queue-state, and `AnswerButtonsNextTime.from`
/// callbacks. It retains preference/backend access, Flow emission, coroutine
/// scheduling, and answer-button presentation.
Future<ReviewerAnswerButtonsNextTimeUpdate>
projectReviewerAnswerButtonsNextTimeUpdate<TSchedulingSnapshot>({
  required FutureOr<bool> Function() shouldShowNextTimes,
  required FutureOr<ReviewQueueState<TSchedulingSnapshot>?> Function()
  currentQueueState,
  required FutureOr<AnswerButtonsNextTime> Function(
    ReviewQueueState<TSchedulingSnapshot> state,
  )
  computeNextTimes,
}) async {
  if (!await shouldShowNextTimes()) {
    return const NoReviewerAnswerButtonsNextTimeUpdate();
  }

  final state = await currentQueueState();
  if (state == null) {
    return const NoReviewerAnswerButtonsNextTimeUpdate();
  }

  final nextTimes = await computeNextTimes(state);
  return PublishReviewerAnswerButtonsNextTime(nextTimes: nextTimes);
}
