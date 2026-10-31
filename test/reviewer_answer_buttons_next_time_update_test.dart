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

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('projectReviewerAnswerButtonsNextTimeUpdate', () {
    const nextTimes = AnswerButtonsNextTime(
      again: '1m',
      hard: '2m',
      good: '3m',
      easy: '4m',
    );

    test('suppresses a computed value when next times are hidden', () {
      final result = projectReviewerAnswerButtonsNextTimeUpdate(
        shouldShowNextTimes: false,
        nextTimes: nextTimes,
      );

      expect(result, isA<NoReviewerAnswerButtonsNextTimeUpdate>());
    });

    test(
      'suppresses publication when visible times have no computed value',
      () {
        final result = projectReviewerAnswerButtonsNextTimeUpdate(
          shouldShowNextTimes: true,
          nextTimes: null,
        );

        expect(result, isA<NoReviewerAnswerButtonsNextTimeUpdate>());
      },
    );

    test('publishes the exact computed value when visible', () {
      final result = projectReviewerAnswerButtonsNextTimeUpdate(
        shouldShowNextTimes: true,
        nextTimes: nextTimes,
      );

      expect(result, isA<PublishReviewerAnswerButtonsNextTime>());
      expect(
        (result as PublishReviewerAnswerButtonsNextTime).nextTimes,
        same(nextTimes),
      );
    });
  });
}
