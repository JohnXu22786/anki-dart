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
 * Source-derived Reviewer action acceptance cases.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer action guard', () {
    test('accepts a question binding while the question is shown', () {
      expect(
        shouldProcessReviewerAction(
          ReviewerBindingValue.forGesture(
            Gesture.tapCenter,
            side: ReviewerCardSide.question,
          ),
          showingAnswer: false,
          isInputFocused: false,
        ),
        isTrue,
      );
    });

    test('rejects a question binding while the answer is shown', () {
      expect(
        shouldProcessReviewerAction(
          ReviewerBindingValue.forGesture(
            Gesture.tapCenter,
            side: ReviewerCardSide.question,
          ),
          showingAnswer: true,
          isInputFocused: false,
        ),
        isFalse,
      );
    });

    test('accepts an answer binding while the answer is shown', () {
      expect(
        shouldProcessReviewerAction(
          ReviewerBindingValue.forGesture(
            Gesture.tapCenter,
            side: ReviewerCardSide.answer,
          ),
          showingAnswer: true,
          isInputFocused: false,
        ),
        isTrue,
      );
    });

    test('rejects an answer binding while the question is shown', () {
      expect(
        shouldProcessReviewerAction(
          ReviewerBindingValue.forGesture(
            Gesture.tapCenter,
            side: ReviewerCardSide.answer,
          ),
          showingAnswer: false,
          isInputFocused: false,
        ),
        isFalse,
      );
    });

    test('accepts BOTH bindings on question and answer sides', () {
      for (final showingAnswer in [false, true]) {
        expect(
          shouldProcessReviewerAction(
            ReviewerBindingValue.forGesture(
              Gesture.tapCenter,
              side: ReviewerCardSide.both,
            ),
            showingAnswer: showingAnswer,
            isInputFocused: false,
          ),
          isTrue,
        );
      }
    });

    test(
      'suppresses focused key bindings but accepts unfocused key bindings',
      () {
        final binding = ReviewerBindingValue.forKeyCode(
          13,
          side: ReviewerCardSide.question,
        );

        expect(
          shouldProcessReviewerAction(
            binding,
            showingAnswer: false,
            isInputFocused: true,
          ),
          isFalse,
        );
        expect(
          shouldProcessReviewerAction(
            binding,
            showingAnswer: false,
            isInputFocused: false,
          ),
          isTrue,
        );
      },
    );

    test('accepts gesture bindings while input is focused', () {
      expect(
        shouldProcessReviewerAction(
          ReviewerBindingValue.forGesture(
            Gesture.tapCenter,
            side: ReviewerCardSide.question,
          ),
          showingAnswer: false,
          isInputFocused: true,
        ),
        isTrue,
      );
    });
  });
}
