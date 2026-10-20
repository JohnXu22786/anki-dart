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
 * Behavioral reference: PreviewerViewModel.kt and CardViewerViewModel.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// The card-view operation requested by a preview navigation action.
///
/// Card loading, rendering, media playback, and Android lifecycle handling stay
/// with the caller.
enum PreviewerNavigationEffect { none, showQuestion, showAnswer, loadCard }

/// Headless state and action decisions for AnkiDroid's card previewer.
///
/// The model preserves the source button formulas and transition behavior. The
/// host supplies the selected-card count and initial state, then handles the
/// returned effect using its own collection, renderer, and media adapters.
final class PreviewerNavigationModel {
  PreviewerNavigationModel({
    required this.cardsCount,
    int initialIndex = 0,
    bool initialShowingAnswer = false,
    bool initialBackSideOnly = false,
  })  : currentIndex = initialIndex,
        showingAnswer = initialShowingAnswer,
        backSideOnly = initialBackSideOnly;

  final int cardsCount;

  int currentIndex;
  bool showingAnswer;
  bool backSideOnly;

  /// Matches `isBackButtonEnabled` in `PreviewerViewModel`.
  bool get isBackButtonEnabled =>
      currentIndex != 0 || (showingAnswer && !backSideOnly);

  /// Matches `isNextButtonEnabled` in `PreviewerViewModel`.
  bool get isNextButtonEnabled =>
      currentIndex != cardsCount - 1 || !showingAnswer;

  /// Shows the answer first, then advances and reloads the next card.
  ///
  /// As in the source method, this action itself has no last-card boundary
  /// guard; the UI normally gates it through [isNextButtonEnabled].
  PreviewerNavigationEffect onNextButtonClick() {
    if (!showingAnswer && !backSideOnly) {
      showingAnswer = true;
      return PreviewerNavigationEffect.showAnswer;
    }
    return _selectCard(currentIndex + 1);
  }

  /// Moves to the preceding card, or hides the first answer in standard mode.
  PreviewerNavigationEffect onPreviousButtonClick() {
    if (currentIndex > 0) return _selectCard(currentIndex - 1);
    if (showingAnswer && !backSideOnly) {
      showingAnswer = false;
      return PreviewerNavigationEffect.showQuestion;
    }
    return PreviewerNavigationEffect.none;
  }

  /// Applies the source's one-based slider position after its bounds check.
  ///
  /// Every valid release reloads the card, even when it selects the current
  /// index, matching `onSliderChange()` and `updateCurrentIndex()`.
  PreviewerNavigationEffect onSliderChange(int sliderPosition) {
    final index = sliderPosition - 1;
    if (index < 0 || index >= cardsCount) {
      return PreviewerNavigationEffect.none;
    }
    return _selectCard(index);
  }

  /// Toggles back-side-only mode and flips the visible side when required.
  PreviewerNavigationEffect toggleBackSideOnly() {
    backSideOnly = !backSideOnly;
    if (!backSideOnly && showingAnswer) {
      showingAnswer = false;
      return PreviewerNavigationEffect.showQuestion;
    }
    if (backSideOnly && !showingAnswer) {
      showingAnswer = true;
      return PreviewerNavigationEffect.showAnswer;
    }
    return PreviewerNavigationEffect.none;
  }

  PreviewerNavigationEffect _selectCard(int index) {
    currentIndex = index;
    showingAnswer = backSideOnly;
    return PreviewerNavigationEffect.loadCard;
  }
}
