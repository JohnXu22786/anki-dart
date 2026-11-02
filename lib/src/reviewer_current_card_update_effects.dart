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

/// `AbstractFlashcardViewer.RESULT_NO_MORE_CARDS` in the pinned source.
const int reviewerNoMoreCardsResult = 52;

/// Executes the source-ordered host effects of `updateCurrentCard()`.
///
/// The host first resolves `sched.currentQueueState()` and supplies its state,
/// timebox event, card, and study-count source value. This function does not
/// derive any of them. Each callback is awaited before the next; a failure
/// propagates and prevents all later callbacks. The host retains scheduler and
/// collection access, current-card deferreds, timer setup, Auto Advance, Flow
/// publication, rendering, AV-tag/media work, availability/count computation,
/// coroutine scheduling, lifecycle, and UI.
Future<void> executeReviewerCurrentCardUpdate<
  TCard extends Object,
  TState extends Object,
  TTimebox extends Object
>({
  required bool hasQueueState,
  required TTimebox? timeboxReached,
  required TCard? topCard,
  required TState? studyCountsSourceState,
  required Future<void> Function(int result) publishFinishResult,
  required Future<void> Function(TTimebox event) publishTimeboxReached,
  required Future<void> Function(TCard card) setCurrentCard,
  required Future<void> Function(TCard card) setupAnswerTimer,
  required Future<void> Function(TCard card) notifyAutoAdvanceCardChange,
  required Future<void> Function() emitCardUpdated,
  required Future<void> Function() showQuestion,
  required Future<void> Function() loadAndPlayQuestionMedia,
  required Future<void> Function(TCard card) publishCanBuryNote,
  required Future<void> Function(TCard card) publishCanSuspendNote,
  required Future<void> Function(TState state) publishStudyCounts,
}) async {
  if (!hasQueueState) {
    await publishFinishResult(reviewerNoMoreCardsResult);
    return;
  }
  if (timeboxReached != null) {
    await publishTimeboxReached(timeboxReached);
    return;
  }

  final card = topCard as TCard;
  await setCurrentCard(card);
  await setupAnswerTimer(card);
  await notifyAutoAdvanceCardChange(card);
  await emitCardUpdated();
  await showQuestion();
  await loadAndPlayQuestionMedia();
  await publishCanBuryNote(card);
  await publishCanSuspendNote(card);
  await publishStudyCounts(studyCountsSourceState as TState);
}
