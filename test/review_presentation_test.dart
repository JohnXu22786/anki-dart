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
 * Behavioral reference: StudyCounts.kt, StudyCountsView.kt, and
 * AnswerButtonsNextTime.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('StudyCounts', () {
    test('uses structural value equality and hashing', () {
      final first = StudyCounts(
        newCount: 1,
        learnCount: 2,
        reviewCount: 3,
        activeQueue: ReviewQueueKind.learning,
      );
      final equal = StudyCounts(
        newCount: 1,
        learnCount: 2,
        reviewCount: 3,
        activeQueue: ReviewQueueKind.learning,
      );
      final different = StudyCounts(
        newCount: 1,
        learnCount: 2,
        reviewCount: 3,
        activeQueue: ReviewQueueKind.review,
      );

      expect(equal, first);
      expect(equal.hashCode, first.hashCode);
      expect(different, isNot(first));
    });

    test('renders backend counts and marks only the active queue', () {
      for (final activeQueue in ReviewQueueKind.values) {
        final state = _queueState(activeQueue: activeQueue);

        final counts = StudyCounts.fromQueueState(state);

        expect(counts.newCount, '0');
        expect(counts.learnCount, '8');
        expect(counts.reviewCount, '17');
        expect(counts.activeQueue, activeQueue);
        for (final queue in ReviewQueueKind.values) {
          expect(counts.isActive(queue), queue == activeQueue);
        }
      }
    });
  });

  group('AnswerButtonsNextTime', () {
    test('uses structural value equality and hashing', () {
      final first = AnswerButtonsNextTime(
        again: '1m',
        hard: '2m',
        good: '3m',
        easy: '4m',
      );
      final equal = AnswerButtonsNextTime(
        again: '1m',
        hard: '2m',
        good: '3m',
        easy: '4m',
      );
      final different = AnswerButtonsNextTime(
        again: '1m',
        hard: '2m',
        good: '3m',
        easy: '5m',
      );

      expect(equal, first);
      expect(equal.hashCode, first.hashCode);
      expect(different, isNot(first));
    });

    test('forwards opaque states and keeps backend labels in answer order',
        () async {
      final state = _queueState(activeQueue: ReviewQueueKind.review);
      final backendStates = state.schedulingSnapshot;
      final scheduler = _FakeNextStateDescriber(
        const ['Again 3m', 'Hard 5m', 'Good 10m', 'Easy 4d'],
      );

      final nextTimes = await AnswerButtonsNextTime.from(
        state: state,
        scheduler: scheduler,
      );

      expect(scheduler.receivedStates, same(backendStates));
      expect(
        [nextTimes.again, nextTimes.hard, nextTimes.good, nextTimes.easy],
        ['Again 3m', 'Hard 5m', 'Good 10m', 'Easy 4d'],
      );
    });

    test('fails when the backend omits one of the four required labels',
        () async {
      final state = _queueState(activeQueue: ReviewQueueKind.newCards);
      final scheduler = _FakeNextStateDescriber(
        const ['Again 3m', 'Hard 5m', 'Good 10m'],
      );

      await expectLater(
        AnswerButtonsNextTime.from(state: state, scheduler: scheduler),
        throwsA(isA<RangeError>()),
      );
    });
  });
}

ReviewQueueState<Object> _queueState({required ReviewQueueKind activeQueue}) =>
    ReviewQueueState<Object>(
      card: const ReviewCard(
        id: 1,
        questionHtml: 'question',
        answerHtml: 'answer',
      ),
      schedulingSnapshot: Object(),
      counts:
          const ReviewQueueCounts(newCount: 0, learnCount: 8, reviewCount: 17),
      activeQueue: activeQueue,
    );

class _FakeNextStateDescriber implements ReviewNextStateDescriber<Object> {
  _FakeNextStateDescriber(this.labels);

  final List<String> labels;
  Object? receivedStates;

  @override
  Future<List<String>> describeNextStates(Object schedulingStates) async {
    receivedStates = schedulingStates;
    return labels;
  }
}
