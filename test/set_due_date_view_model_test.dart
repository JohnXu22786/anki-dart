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
 * Source-derived from SetDueDateViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Set Due Date state', () {
    test('single-day inputs retain zero and reject null or negatives', () {
      final viewModel = SetDueDateViewModel();
      viewModel.init(cardIds: [1], fsrsEnabled: false);

      viewModel.nextSingleDayDueDate = -1;
      expect(viewModel.nextSingleDayDueDate, isNull);
      expect(viewModel.isValid, isFalse);

      viewModel.nextSingleDayDueDate = 0;
      expect(viewModel.isValid, isTrue);
      expect(viewModel.calculateDaysParameter(), '0');

      viewModel.nextSingleDayDueDate = null;
      expect(viewModel.isValid, isFalse);
      expect(viewModel.calculateDaysParameter(), isNull);
    });

    test('submission waits for scheduler initialization and selected tab', () {
      final viewModel = SetDueDateViewModel()..nextSingleDayDueDate = 3;
      expect(viewModel.isValid, isFalse);
      expect(viewModel.calculateDaysParameter(), isNull);

      viewModel.init(cardIds: [1], fsrsEnabled: true);
      expect(viewModel.isValid, isTrue);
      expect(viewModel.calculateDaysParameter(), '3!');

      viewModel.currentTab = SetDueDateTab.dateRange;
      expect(viewModel.isValid, isFalse);
      expect(viewModel.calculateDaysParameter(), isNull);
    });

    test('date ranges reject absent, negative, and descending endpoints', () {
      final range = SetDueDateRange();
      expect(range.isValid(), isFalse);
      expect(range.toDaysParameter(), isNull);

      range.start = -1;
      range.end = 0;
      expect(range.isValid(), isFalse);

      range.start = 2;
      range.end = 1;
      expect(range.isValid(), isFalse);

      range.start = 1;
      range.end = 2;
      expect(range.isValid(), isTrue);
      expect(range.toDaysParameter(), '1-2');
    });

    test('range formatting collapses equal endpoints and keeps the suffix', () {
      final viewModel = SetDueDateViewModel()
        ..init(cardIds: [1], fsrsEnabled: false);
      viewModel.currentTab = SetDueDateTab.dateRange;
      viewModel.setNextDateRangeStart(0);
      viewModel.setNextDateRangeEnd(0);
      expect(viewModel.calculateDaysParameter(), '0');

      viewModel.updateIntervalToMatchDueDate = true;
      expect(viewModel.calculateDaysParameter(), '0!');

      viewModel.setNextDateRangeEnd(1);
      expect(viewModel.calculateDaysParameter(), '0-1!');
    });

    test(
      'FSRS loading and interval-matching setter preserve source behavior',
      () {
        final loading = SetDueDateViewModel();
        expect(loading.fsrsEnabled, isNull);
        expect(loading.canSetUpdateIntervalToMatchDueDate, isFalse);

        final fsrs = SetDueDateViewModel()
          ..init(cardIds: [1], fsrsEnabled: true);
        expect(fsrs.updateIntervalToMatchDueDate, isTrue);
        expect(fsrs.canSetUpdateIntervalToMatchDueDate, isFalse);
        expect(
          () => fsrs.updateIntervalToMatchDueDate = false,
          throwsA(
            isA<UnsupportedError>().having(
              (error) => error.message,
              'message',
              'due date must match interval if using FSRS',
            ),
          ),
        );

        final sm2 = SetDueDateViewModel()
          ..init(cardIds: [1], fsrsEnabled: false);
        expect(sm2.updateIntervalToMatchDueDate, isFalse);
        expect(sm2.canSetUpdateIntervalToMatchDueDate, isTrue);
        sm2.updateIntervalToMatchDueDate = true;
        expect(sm2.calculateDaysParameter(), isNull);
      },
    );

    test(
      'card count and current interval follow the one-card review-only rule',
      () {
        final viewModel = SetDueDateViewModel()
          ..init(cardIds: [1, 2], fsrsEnabled: false);
        expect(viewModel.cardCount, 2);
        expect(
          projectSetDueDateCurrentInterval(
            cardCount: viewModel.cardCount,
            isReviewCard: true,
            intervalDays: 8,
          ),
          isNull,
        );

        expect(
          projectSetDueDateCurrentInterval(
            cardCount: 0,
            isReviewCard: true,
            intervalDays: 8,
          ),
          isNull,
        );
        expect(
          projectSetDueDateCurrentInterval(
            cardCount: 1,
            isReviewCard: false,
            intervalDays: 0,
          ),
          isNull,
        );
        expect(
          projectSetDueDateCurrentInterval(
            cardCount: 1,
            isReviewCard: true,
            intervalDays: 8,
          ),
          8,
        );
      },
    );
  });
}
