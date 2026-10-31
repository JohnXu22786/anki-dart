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
 * Behavioral reference: TemplatePreviewerViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// One ordered host operation in the Template Previewer's answer toggle.
enum PreviewerTemplateTabEffect {
  showQuestion,
  loadQuestionSounds,
  showAnswer,
  loadAnswerSounds,
}

/// Projects `TemplatePreviewerViewModel.toggleShowAnswer()` into host effects.
///
/// The host executes the display update before loading and playing sounds for
/// that side. Rendering, media work, asynchronous execution, and state-flow
/// publication remain with the host.
List<PreviewerTemplateTabEffect> previewerToggleShowAnswerEffects({
  required bool showingAnswer,
}) => List.unmodifiable(
  showingAnswer
      ? [
          PreviewerTemplateTabEffect.showQuestion,
          PreviewerTemplateTabEffect.loadQuestionSounds,
        ]
      : [
          PreviewerTemplateTabEffect.showAnswer,
          PreviewerTemplateTabEffect.loadAnswerSounds,
        ],
);

/// Projects `TemplatePreviewerViewModel.onTabSelected()` to its card ordinal.
///
/// Cloze notes index the supplied ordered ordinals directly, preserving the
/// source's indexing failure for an invalid position. Non-cloze notes use the
/// position as the ordinal without validation. The host owns async flow updates
/// and card creation.
int previewerSelectedTemplateOrd({
  required bool isCloze,
  required List<int>? clozeOrds,
  required int position,
}) => isCloze ? clozeOrds![position] : position;

/// Projects `TemplatePreviewerViewModel.getCurrentTabIndex()`.
///
/// Cloze notes use list `indexOf`, including its `-1` result when the ordinal
/// is absent. Non-cloze notes return the ordinal unchanged.
int previewerCurrentTemplateTabIndex({
  required bool isCloze,
  required List<int>? clozeOrds,
  required int currentOrd,
}) => isCloze ? clozeOrds!.indexOf(currentOrd) : currentOrd;

/// Projects `TemplatePreviewerViewModel.getSafeClozeOrd()` for recreation.
///
/// A missing or empty cloze-ordinal list returns zero; otherwise the current
/// ordinal is clamped to a valid list index. This result is intentionally an
/// index, matching the source's `ordFlow` and list-size calculation.
int previewerSafeClozeOrd({
  required List<int>? clozeOrds,
  required int currentOrd,
}) {
  if (clozeOrds == null || clozeOrds.isEmpty) return 0;
  return currentOrd.clamp(0, clozeOrds.length - 1);
}
