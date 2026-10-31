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

/// One ordered host request from `ReviewerViewModel.opExecuted()`.
enum ReviewerOpExecutedEffect {
  updateUndoAndRedoLabels,
  updateCurrentCard,
  loadCurrentCard,
  loadCardAvTags,
  updateMarkIcon,
  showAnswer,
  showQuestion,
  updateFlagIcon,
}

/// Projects `ReviewerViewModel.opExecuted(changes, handler)` into host requests.
///
/// The host reads [OpChanges] fields and handler identity, then supplies those
/// decisions here. The first label request always precedes the source handler
/// early return and all exclusive change branches. The host executes each
/// returned request in order; a callback failure naturally prevents later
/// requests. Current-card and collection access, card/media loading, Flows,
/// coroutine/error handling, label updates, rendering, and lifecycle remain
/// host-side.
List<ReviewerOpExecutedEffect> planReviewerOpExecutedEffects({
  required bool isSelfHandler,
  required bool hasStudyQueueChanges,
  required bool hasNoteTextChanges,
  required bool hasCardChanges,
  required bool showingAnswer,
}) {
  final effects = <ReviewerOpExecutedEffect>[
    ReviewerOpExecutedEffect.updateUndoAndRedoLabels,
  ];
  if (isSelfHandler) return List.unmodifiable(effects);

  if (hasStudyQueueChanges) {
    effects.add(ReviewerOpExecutedEffect.updateCurrentCard);
  } else if (hasNoteTextChanges) {
    effects.addAll([
      ReviewerOpExecutedEffect.loadCurrentCard,
      ReviewerOpExecutedEffect.loadCardAvTags,
      ReviewerOpExecutedEffect.updateMarkIcon,
      showingAnswer
          ? ReviewerOpExecutedEffect.showAnswer
          : ReviewerOpExecutedEffect.showQuestion,
    ]);
  } else if (hasCardChanges) {
    effects.addAll([
      ReviewerOpExecutedEffect.loadCurrentCard,
      ReviewerOpExecutedEffect.updateFlagIcon,
    ]);
  }

  return List.unmodifiable(effects);
}
