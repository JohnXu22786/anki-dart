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

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('PreviewerNavigationModel', () {
    test('next reveals the answer before advancing to the next card', () {
      final model = PreviewerNavigationModel(cardsCount: 4);

      expect(model.onNextButtonClick(), PreviewerNavigationEffect.showAnswer);
      expect(model.currentIndex, 0);
      expect(model.showingAnswer, isTrue);

      expect(model.onNextButtonClick(), PreviewerNavigationEffect.loadCard);
      expect(model.currentIndex, 1);
      expect(model.showingAnswer, isFalse);
    });

    test('previous moves back and only hides the first answer in standard mode',
        () {
      final model = PreviewerNavigationModel(
        cardsCount: 4,
        initialIndex: 2,
        initialShowingAnswer: true,
      );

      expect(model.onPreviousButtonClick(), PreviewerNavigationEffect.loadCard);
      expect(model.currentIndex, 1);
      expect(model.showingAnswer, isFalse);

      expect(model.onPreviousButtonClick(), PreviewerNavigationEffect.loadCard);
      expect(model.currentIndex, 0);
      expect(model.onPreviousButtonClick(), PreviewerNavigationEffect.none);
      expect(model.currentIndex, 0);

      final backOnly = PreviewerNavigationModel(
        cardsCount: 4,
        initialShowingAnswer: true,
        initialBackSideOnly: true,
      );
      expect(backOnly.onPreviousButtonClick(), PreviewerNavigationEffect.none);
      expect(backOnly.showingAnswer, isTrue);
    });

    test('slider uses one-based positions and ignores out-of-range values', () {
      final model = PreviewerNavigationModel(cardsCount: 4);

      expect(model.onSliderChange(3), PreviewerNavigationEffect.loadCard);
      expect(model.currentIndex, 2);
      expect(model.onSliderChange(0), PreviewerNavigationEffect.none);
      expect(model.onSliderChange(5), PreviewerNavigationEffect.none);
      expect(model.currentIndex, 2);

      // The source reloads the current card for any valid slider release.
      expect(model.onSliderChange(3), PreviewerNavigationEffect.loadCard);
      expect(model.currentIndex, 2);
    });

    test('back-side-only mode affects toggles and subsequent card navigation',
        () {
      final model = PreviewerNavigationModel(cardsCount: 4);

      expect(model.toggleBackSideOnly(), PreviewerNavigationEffect.showAnswer);
      expect(model.backSideOnly, isTrue);
      expect(model.showingAnswer, isTrue);

      expect(model.onNextButtonClick(), PreviewerNavigationEffect.loadCard);
      expect(model.currentIndex, 1);
      expect(model.showingAnswer, isTrue);
      expect(model.onPreviousButtonClick(), PreviewerNavigationEffect.loadCard);
      expect(model.currentIndex, 0);
      expect(model.showingAnswer, isTrue);

      expect(
          model.toggleBackSideOnly(), PreviewerNavigationEffect.showQuestion);
      expect(model.backSideOnly, isFalse);
      expect(model.showingAnswer, isFalse);
      expect(model.onNextButtonClick(), PreviewerNavigationEffect.showAnswer);
      expect(model.currentIndex, 0);

      final alreadyShowingAnswer = PreviewerNavigationModel(
        cardsCount: 4,
        initialShowingAnswer: true,
      );
      expect(
        alreadyShowingAnswer.toggleBackSideOnly(),
        PreviewerNavigationEffect.none,
      );
      expect(alreadyShowingAnswer.backSideOnly, isTrue);
      expect(alreadyShowingAnswer.showingAnswer, isTrue);
    });

    test('button enablement follows the source index and side expressions', () {
      final firstQuestion = PreviewerNavigationModel(cardsCount: 4);
      expect(firstQuestion.isBackButtonEnabled, isFalse);
      expect(firstQuestion.isNextButtonEnabled, isTrue);

      final lastAnswer = PreviewerNavigationModel(
        cardsCount: 4,
        initialIndex: 3,
        initialShowingAnswer: true,
      );
      expect(lastAnswer.isBackButtonEnabled, isTrue);
      expect(lastAnswer.isNextButtonEnabled, isFalse);

      final firstBackOnlyAnswer = PreviewerNavigationModel(
        cardsCount: 4,
        initialShowingAnswer: true,
        initialBackSideOnly: true,
      );
      expect(firstBackOnlyAnswer.isBackButtonEnabled, isFalse);
    });

    test('direct next call retains the source method boundary behavior', () {
      final model = PreviewerNavigationModel(
        cardsCount: 1,
        initialShowingAnswer: true,
      );
      expect(model.isNextButtonEnabled, isFalse);

      expect(model.onNextButtonClick(), PreviewerNavigationEffect.loadCard);
      expect(model.currentIndex, 1);
      expect(model.showingAnswer, isFalse);
    });
  });
}
