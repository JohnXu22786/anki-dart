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
    final state = ReviewQueueState<int>(
      card: const ReviewCard(id: 1, questionHtml: 'q', answerHtml: 'a'),
      schedulingSnapshot: 7,
      counts: const ReviewQueueCounts(
        newCount: 1,
        learnCount: 2,
        reviewCount: 3,
      ),
      activeQueue: ReviewQueueKind.learning,
    );
    final nextTimes = AnswerButtonsNextTime(
      again: '1m',
      hard: '2m',
      good: '3m',
      easy: '4m',
    );

    test('false visibility skips queue and next-time callbacks', () async {
      final calls = <String>[];

      final result = await projectReviewerAnswerButtonsNextTimeUpdate<int>(
        shouldShowNextTimes: () async {
          calls.add('visibility');
          await Future<void>.delayed(Duration.zero);
          return false;
        },
        currentQueueState: () {
          calls.add('queue');
          return state;
        },
        computeNextTimes: (_) {
          calls.add('next-times');
          return nextTimes;
        },
      );

      expect(result, isA<NoReviewerAnswerButtonsNextTimeUpdate>());
      expect(calls, ['visibility']);
    });

    test('null queue state skips next-time computation', () async {
      final calls = <String>[];

      final result = await projectReviewerAnswerButtonsNextTimeUpdate<int>(
        shouldShowNextTimes: () async {
          calls.add('visibility');
          await Future<void>.delayed(Duration.zero);
          return true;
        },
        currentQueueState: () async {
          calls.add('queue');
          await Future<void>.delayed(Duration.zero);
          return null;
        },
        computeNextTimes: (_) {
          calls.add('next-times');
          return nextTimes;
        },
      );

      expect(result, isA<NoReviewerAnswerButtonsNextTimeUpdate>());
      expect(calls, ['visibility', 'queue']);
    });

    test(
      'awaits callbacks in order and publishes the identical value',
      () async {
        final calls = <String>[];
        ReviewQueueState<int>? receivedState;
        final result = await projectReviewerAnswerButtonsNextTimeUpdate<int>(
          shouldShowNextTimes: () async {
            calls.add('visibility');
            await Future<void>.delayed(Duration.zero);
            return true;
          },
          currentQueueState: () async {
            calls.add('queue');
            await Future<void>.delayed(Duration.zero);
            return state;
          },
          computeNextTimes: (actualState) async {
            calls.add('next-times');
            receivedState = actualState;
            await Future<void>.delayed(Duration.zero);
            return nextTimes;
          },
        );

        expect(calls, ['visibility', 'queue', 'next-times']);
        expect(receivedState, same(state));
        expect(result, isA<PublishReviewerAnswerButtonsNextTime>());
        expect(
          (result as PublishReviewerAnswerButtonsNextTime).nextTimes,
          same(nextTimes),
        );
      },
    );

    test('visibility failure propagates and stops later callbacks', () async {
      final error = StateError('preference failed');
      final calls = <String>[];

      final result = projectReviewerAnswerButtonsNextTimeUpdate<int>(
        shouldShowNextTimes: () async {
          calls.add('visibility');
          throw error;
        },
        currentQueueState: () {
          calls.add('queue');
          return state;
        },
        computeNextTimes: (_) {
          calls.add('next-times');
          return nextTimes;
        },
      );

      await expectLater(result, throwsA(same(error)));
      expect(calls, ['visibility']);
    });

    test(
      'queue-state failure propagates and skips next-time computation',
      () async {
        final error = StateError('queue read failed');
        final calls = <String>[];

        final result = projectReviewerAnswerButtonsNextTimeUpdate<int>(
          shouldShowNextTimes: () {
            calls.add('visibility');
            return true;
          },
          currentQueueState: () async {
            calls.add('queue');
            throw error;
          },
          computeNextTimes: (_) {
            calls.add('next-times');
            return nextTimes;
          },
        );

        await expectLater(result, throwsA(same(error)));
        expect(calls, ['visibility', 'queue']);
      },
    );

    test('next-time failure propagates unchanged', () async {
      final error = StateError('scheduler failed');
      final calls = <String>[];

      final result = projectReviewerAnswerButtonsNextTimeUpdate<int>(
        shouldShowNextTimes: () {
          calls.add('visibility');
          return true;
        },
        currentQueueState: () async {
          calls.add('queue');
          return state;
        },
        computeNextTimes: (actualState) async {
          calls.add('next-times');
          expect(actualState, same(state));
          throw error;
        },
      );

      await expectLater(result, throwsA(same(error)));
      expect(calls, ['visibility', 'queue', 'next-times']);
    });
  });
}
