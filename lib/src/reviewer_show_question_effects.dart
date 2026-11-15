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

/// One source-ordered host operation during `ReviewerViewModel.showQuestion()`.
enum ReviewerShowQuestionEffect {
  replaceCompletedMutationSignal,
  showQuestion,
  runStateMutationHook,
  updateMarkIcon,
  updateFlagIcon,
  autoAdvanceOnShowQuestion,
}

/// Projects `ReviewerViewModel.showQuestion()` into ordered host requests.
///
/// Execute each returned effect sequentially and stop if a host request fails.
/// The host owns the mutation-signal lifecycle and replaces the signal only
/// when requested. It also owns rendering, hook execution, icon reads and flow
/// publication, Auto Advance, coroutine/error boundaries, and media callbacks.
/// When waiting for audio, the host continues to call Auto Advance from its
/// existing media-group-completed path.
List<ReviewerShowQuestionEffect> planReviewerShowQuestionEffects({
  required bool mutationSignalCompleted,
  required bool shouldWaitForAudio,
}) => List.unmodifiable([
  if (mutationSignalCompleted)
    ReviewerShowQuestionEffect.replaceCompletedMutationSignal,
  ReviewerShowQuestionEffect.showQuestion,
  ReviewerShowQuestionEffect.runStateMutationHook,
  ReviewerShowQuestionEffect.updateMarkIcon,
  ReviewerShowQuestionEffect.updateFlagIcon,
  if (!shouldWaitForAudio) ReviewerShowQuestionEffect.autoAdvanceOnShowQuestion,
]);
