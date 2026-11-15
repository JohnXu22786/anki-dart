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
 * Source-derived Reviewer show-answer cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer show-answer effects', () {
    test('keeps answer-result and display requests in source order', () {
      expect(
        planReviewerShowAnswerEffects(
          typeAnswerEnabled: true,
          shouldWaitForAudio: false,
        ),
        [
          ReviewerShowAnswerEffect.awaitMutationSignal,
          ReviewerShowAnswerEffect.publishTypedAnswerResult,
          ReviewerShowAnswerEffect.awaitTypedAnswerResult,
          ReviewerShowAnswerEffect.setTypedAnswer,
          ReviewerShowAnswerEffect.updateNextTimes,
          ReviewerShowAnswerEffect.showAnswer,
          ReviewerShowAnswerEffect.loadAndPlayAnswerMedia,
          ReviewerShowAnswerEffect.autoAdvanceOnShowAnswer,
          ReviewerShowAnswerEffect.readAnswerTimerHiddenState,
        ],
      );
    });

    test('uses empty result on disabled mode or timed-out/null result', () {
      expect(reviewerShowAnswerTypedAnswerTimeoutMilliseconds, 1000);
      expect(
        planReviewerShowAnswerEffects(
          typeAnswerEnabled: false,
          shouldWaitForAudio: true,
        ),
        [
          ReviewerShowAnswerEffect.awaitMutationSignal,
          ReviewerShowAnswerEffect.completeTypedAnswerResultWithEmptyString,
          ReviewerShowAnswerEffect.awaitTypedAnswerResult,
          ReviewerShowAnswerEffect.setTypedAnswer,
          ReviewerShowAnswerEffect.updateNextTimes,
          ReviewerShowAnswerEffect.showAnswer,
          ReviewerShowAnswerEffect.loadAndPlayAnswerMedia,
          ReviewerShowAnswerEffect.readAnswerTimerHiddenState,
        ],
      );
      expect(reviewerShowAnswerTypedAnswer(null), '');
      expect(reviewerShowAnswerTypedAnswer(''), '');
      expect(reviewerShowAnswerTypedAnswer('answer'), 'answer');
    });

    test('timer state gates deck/config reads and stop handling', () {
      expect(
        planReviewerShowAnswerTimerEffects(answerTimerIsHidden: true),
        isEmpty,
      );
      expect(planReviewerShowAnswerTimerEffects(answerTimerIsHidden: false), [
        ReviewerShowAnswerTimerEffect.readCurrentCardDeckId,
        ReviewerShowAnswerTimerEffect.readDeckConfigForCurrentDeck,
      ]);
      expect(planReviewerShowAnswerTimerStopEffects(stopTimerOnAnswer: true), [
        ReviewerShowAnswerTimerEffect.stopAnswerTimer,
      ]);
      expect(
        planReviewerShowAnswerTimerStopEffects(stopTimerOnAnswer: false),
        isEmpty,
      );
    });
  });
}
