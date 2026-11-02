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

/// One source-ordered host request from `ReviewerViewModel.onPageFinished()`.
enum ReviewerPageFinishedEffect {
  updateCurrentCard,
  showAnswer,
  runStateMutationHook,
  checkMutationSignalThenRunHook,
  showQuestion,
}

/// Projects `ReviewerViewModel.onPageFinished(isAfterRecreation)` into host
/// requests in source order.
///
/// The host owns the page callback and IO scheduling, current-card refresh,
/// rendering, mutation signal and JavaScript, coroutine errors/cancellation,
/// Flow delivery, WebView, and Android lifecycle/UI. The host checks the
/// mutation signal after the show-answer request, as in the source coroutine.
List<ReviewerPageFinishedEffect> planReviewerPageFinishedEffects({
  required bool isAfterRecreation,
  required bool showingAnswer,
}) => List.unmodifiable([
  if (!isAfterRecreation)
    ReviewerPageFinishedEffect.updateCurrentCard
  else if (showingAnswer) ...[
    ReviewerPageFinishedEffect.showAnswer,
    ReviewerPageFinishedEffect.checkMutationSignalThenRunHook,
  ] else
    ReviewerPageFinishedEffect.showQuestion,
]);

/// Awaits each host request in order and propagates its failure before issuing
/// any later request, matching the source coroutine's sequential calls.
Future<void> executeReviewerPageFinishedEffects(
  Iterable<ReviewerPageFinishedEffect> effects, {
  required Future<bool> Function() isMutationSignalCompleted,
  required Future<void> Function(ReviewerPageFinishedEffect effect) request,
}) async {
  for (final effect in effects) {
    if (effect == ReviewerPageFinishedEffect.checkMutationSignalThenRunHook) {
      if (!await isMutationSignalCompleted()) {
        await request(ReviewerPageFinishedEffect.runStateMutationHook);
      }
    } else {
      await request(effect);
    }
  }
}
