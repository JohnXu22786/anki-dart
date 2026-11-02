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

/// One source-ordered host operation after the Reviewer resolves its queue state.
enum ReviewerAnswerCardEffect {
  lookupCurrentCard,
  computeAnswerWithScheduler,
  persistAnswerUndoably,
  emitAnswerRatingFeedback,
  savePreviouslyAnsweredCardId,
  checkResultingSchedulerStateForLeech,
  reloadCardIfLeech,
  deriveSuspensionFromQueueIfLeech,
  showLocalizedLeechFeedbackIfLeech,
  refreshCurrentCard,
}

/// Projects `ReviewerViewModel.answerCardInternal()` after `queueState.await()`.
///
/// If the host-resolved queue state is absent, the source returns immediately;
/// this therefore yields no current-card lookup or later operation. Otherwise,
/// the returned operations preserve the source order. The host executes them
/// sequentially and stops on failure without retrying or compensating. It
/// checks each `IfLeech` operation against the result of the preceding leech
/// check. Scheduler computation, collection/flow access, undoable persistence,
/// leech lookup, card reload and queue inspection, localization, feedback
/// delivery, saved state, coroutine integration, logging, and UI remain host
/// operations. The host can use `reviewerLeechFeedbackMessage()` when it
/// delivers the localized leech feedback.
List<ReviewerAnswerCardEffect> planReviewerAnswerCardEffects({
  required bool hasQueueState,
}) => hasQueueState
    ? List.unmodifiable([
        ReviewerAnswerCardEffect.lookupCurrentCard,
        ReviewerAnswerCardEffect.computeAnswerWithScheduler,
        ReviewerAnswerCardEffect.persistAnswerUndoably,
        ReviewerAnswerCardEffect.emitAnswerRatingFeedback,
        ReviewerAnswerCardEffect.savePreviouslyAnsweredCardId,
        ReviewerAnswerCardEffect.checkResultingSchedulerStateForLeech,
        ReviewerAnswerCardEffect.reloadCardIfLeech,
        ReviewerAnswerCardEffect.deriveSuspensionFromQueueIfLeech,
        ReviewerAnswerCardEffect.showLocalizedLeechFeedbackIfLeech,
        ReviewerAnswerCardEffect.refreshCurrentCard,
      ])
    : const [];

/// Projects the source `card.queue.code < 0` check for a reloaded leech card.
bool reviewerAnswerCardLeechIsSuspended({required int queueCode}) =>
    queueCode < 0;
