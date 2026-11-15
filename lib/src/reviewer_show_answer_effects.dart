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

/// The source `withTimeoutOrNull(1000L)` duration, in milliseconds.
const reviewerShowAnswerTypedAnswerTimeoutMilliseconds = 1000;

/// One source-ordered host operation during `showAnswerInternal()`.
enum ReviewerShowAnswerEffect {
  awaitMutationSignal,
  publishTypedAnswerResult,
  completeTypedAnswerResultWithEmptyString,
  awaitTypedAnswerResult,
  setTypedAnswer,
  updateNextTimes,
  showAnswer,
  loadAndPlayAnswerMedia,
  autoAdvanceOnShowAnswer,
  readAnswerTimerHiddenState,
}

/// Resolves the value assigned after `withTimeoutOrNull(...) ?: ""`.
String reviewerShowAnswerTypedAnswer(String? result) => result ?? '';

/// Projects `ReviewerViewModel.showAnswerInternal()` through its timer-state
/// read. Execute returned requests sequentially and stop when a request fails.
///
/// The host creates and completes the deferred result, awaits it using
/// [reviewerShowAnswerTypedAnswerTimeoutMilliseconds], and supplies its nullable
/// outcome. It executes the returned requests in order, using
/// [reviewerShowAnswerTypedAnswer] for the mutable typed-answer assignment. If
/// Auto Advance waits for audio, the source skips `onShowAnswer()` and awaits
/// media-group completion on the host as before. The hidden-state read is last
/// so timer/configuration work cannot precede answer-side effects.
List<ReviewerShowAnswerEffect> planReviewerShowAnswerEffects({
  required bool typeAnswerEnabled,
  required bool shouldWaitForAudio,
}) => List.unmodifiable([
  ReviewerShowAnswerEffect.awaitMutationSignal,
  typeAnswerEnabled
      ? ReviewerShowAnswerEffect.publishTypedAnswerResult
      : ReviewerShowAnswerEffect.completeTypedAnswerResultWithEmptyString,
  ReviewerShowAnswerEffect.awaitTypedAnswerResult,
  ReviewerShowAnswerEffect.setTypedAnswer,
  ReviewerShowAnswerEffect.updateNextTimes,
  ReviewerShowAnswerEffect.showAnswer,
  ReviewerShowAnswerEffect.loadAndPlayAnswerMedia,
  if (!shouldWaitForAudio) ReviewerShowAnswerEffect.autoAdvanceOnShowAnswer,
  ReviewerShowAnswerEffect.readAnswerTimerHiddenState,
]);

/// One source-ordered host operation after the timer's hidden-state check.
enum ReviewerShowAnswerTimerEffect {
  readCurrentCardDeckId,
  readDeckConfigForCurrentDeck,
  stopAnswerTimer,
}

/// Returns no deck/config work when the timer is hidden; otherwise requests the
/// current deck ID and its configuration in source order. The host supplies the
/// hidden-state fact only after executing [planReviewerShowAnswerEffects].
List<ReviewerShowAnswerTimerEffect> planReviewerShowAnswerTimerEffects({
  required bool answerTimerIsHidden,
}) => answerTimerIsHidden
    ? const []
    : const [
        ReviewerShowAnswerTimerEffect.readCurrentCardDeckId,
        ReviewerShowAnswerTimerEffect.readDeckConfigForCurrentDeck,
      ];

/// Applies the host-read `stopTimerOnAnswer` configuration value.
List<ReviewerShowAnswerTimerEffect> planReviewerShowAnswerTimerStopEffects({
  required bool stopTimerOnAnswer,
}) => stopTimerOnAnswer
    ? const [ReviewerShowAnswerTimerEffect.stopAnswerTimer]
    : const [];
