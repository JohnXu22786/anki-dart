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
 * Behavioral reference: ReviewerViewModel.kt, libanki Scheduler.kt, and
 * Collection.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewSession', () {
    test('starts on the question and reveals the answer once', () async {
      final queue = _queueState(1, 'question 1', 'answer 1');
      final scheduler = _FakeReviewScheduler([queue]);
      final session = ReviewSession<Object>(scheduler);

      await session.start();

      expect(session.phase, ReviewSessionPhase.question);
      expect(session.current, same(queue));
      expect(session.visibleContent, 'question 1');

      await session.showAnswer();
      await session.showAnswer();

      expect(session.phase, ReviewSessionPhase.answer);
      expect(session.visibleContent, 'answer 1');
      expect(scheduler.answers, isEmpty);
    });

    test('pauses for a scheduler timebox before showing the queued card',
        () async {
      final cardState = _queueState(1, 'question 1', 'answer 1');
      final timedState = ReviewQueueState<Object>(
        card: cardState.card,
        schedulingSnapshot: cardState.schedulingSnapshot,
        counts: cardState.counts,
        activeQueue: cardState.activeQueue,
        timeboxReached: const ReviewTimeboxReached(secs: 60, reps: 3),
      );
      final scheduler = _FakeReviewScheduler([cardState])
        ..queueReadSequence = [timedState, cardState];
      final session = ReviewSession<Object>(scheduler);

      await session.start();

      expect(session.phase, ReviewSessionPhase.timeboxReached);
      expect(session.timeboxReached, timedState.timeboxReached);
      expect(session.current, isNull);
      expect(session.visibleContent, isNull);
      await session.answerCard(ReviewRating.good);
      expect(scheduler.answers, isEmpty);

      await session.continueAfterTimebox();

      expect(scheduler.queueReads, 2);
      expect(session.phase, ReviewSessionPhase.question);
      expect(session.timeboxReached, isNull);
      expect(session.current, same(cardState));
      expect(session.visibleContent, 'question 1');
    });

    test('keeps the displayed side visible beneath a reached timebox',
        () async {
      final first = _queueState(1, 'question 1', 'answer 1');
      final next = _queueState(2, 'question 2', 'answer 2');
      final timedState = ReviewQueueState<Object>(
        card: next.card,
        schedulingSnapshot: next.schedulingSnapshot,
        counts: next.counts,
        activeQueue: next.activeQueue,
        timeboxReached: const ReviewTimeboxReached(secs: 60, reps: 3),
      );
      final scheduler = _FakeReviewScheduler([first, next])
        ..queueReadSequence = [first, timedState, next];
      final session = ReviewSession<Object>(scheduler);
      await session.start();
      await session.showAnswer();

      await session.answerCard(ReviewRating.good);

      expect(session.phase, ReviewSessionPhase.timeboxReached);
      expect(session.current, isNull);
      expect(session.visibleContent, 'answer 1');
      await session.answerCard(ReviewRating.again);
      expect(scheduler.answers, hasLength(1));

      scheduler.failNextQueueRead = true;
      await expectLater(
        session.continueAfterTimebox(),
        throwsA(isA<StateError>()),
      );

      expect(session.phase, ReviewSessionPhase.loading);
      expect(session.visibleContent, 'answer 1');

      await session.retryCurrentQueueState();

      expect(session.phase, ReviewSessionPhase.question);
      expect(session.visibleContent, 'question 2');
    });

    test(
        'waits for state mutations before showing an answer or sending a rating',
        () async {
      final first = _queueState(1, 'question 1', 'answer 1');
      final second = _queueState(2, 'question 2', 'answer 2');
      final scheduler = _FakeReviewScheduler([first, second]);
      final session = ReviewSession<Object>(scheduler);
      await session.start();

      final revealGate = scheduler.blockNextMutation();
      final reveal = session.showAnswer();
      await Future<void>.delayed(Duration.zero);
      expect(revealGate.started.isCompleted, isTrue);
      expect(session.phase, ReviewSessionPhase.question);
      revealGate.release.complete();
      await reveal;
      expect(session.phase, ReviewSessionPhase.answer);

      await session.answerCard(ReviewRating.good);
      final answerGate = scheduler.blockNextMutation();
      final answer = session.answerCard(ReviewRating.easy);
      await Future<void>.delayed(Duration.zero);
      expect(answerGate.started.isCompleted, isTrue);
      expect(scheduler.answers.map((call) => call.state), [first]);
      answerGate.release.complete();
      await answer;
      expect(scheduler.answers.map((call) => call.state), [first, second]);
    });

    test('forwards rating and queue state then loads the next question',
        () async {
      final first = _queueState(1, 'question 1', 'answer 1');
      final second = _queueState(2, 'question 2', 'answer 2');
      final scheduler = _FakeReviewScheduler([first, second]);
      final session = ReviewSession<Object>(scheduler);
      await session.start();

      // The source action dispatcher routes ratings directly; it does not
      // require the answer side to be visible before calling answerCard.
      await session.answerCard(ReviewRating.good);

      expect(scheduler.answers, hasLength(1));
      expect(scheduler.answers.single.state, same(first));
      expect(scheduler.answers.single.rating, ReviewRating.good);
      expect(session.current, same(second));
      expect(session.phase, ReviewSessionPhase.question);
      expect(session.visibleContent, 'question 2');
    });

    test('keeps the current card if the scheduler rejects an answer', () async {
      final first = _queueState(1, 'question 1', 'answer 1');
      final scheduler = _FakeReviewScheduler([first])..failNextAnswer = true;
      final session = ReviewSession<Object>(scheduler);
      await session.start();
      await session.showAnswer();

      await expectLater(
        session.answerCard(ReviewRating.easy),
        throwsA(isA<StateError>()),
      );

      expect(session.current, same(first));
      expect(session.phase, ReviewSessionPhase.answer);
      expect(scheduler.queueReads, 1);
    });

    test('retries a failed queue refresh without regrading the consumed card',
        () async {
      final first = _queueState(1, 'question 1', 'answer 1');
      final second = _queueState(2, 'question 2', 'answer 2');
      final scheduler = _FakeReviewScheduler([first, second]);
      final session = ReviewSession<Object>(scheduler);
      await session.start();
      await session.showAnswer();
      scheduler.failNextQueueRead = true;

      await expectLater(
        session.answerCard(ReviewRating.good),
        throwsA(isA<StateError>()),
      );

      expect(session.current, isNull);
      expect(session.phase, ReviewSessionPhase.loading);
      expect(session.visibleContent, 'answer 1');
      await session.answerCard(ReviewRating.again);
      expect(scheduler.answers, hasLength(1));

      await session.retryCurrentQueueState();

      expect(session.current, same(second));
      expect(session.phase, ReviewSessionPhase.question);
      expect(scheduler.answers, hasLength(1));
    });

    test('serializes ratings while the first scheduler answer is pending',
        () async {
      final first = _queueState(1, 'question 1', 'answer 1');
      final second = _queueState(2, 'question 2', 'answer 2');
      final scheduler = _FakeReviewScheduler([first, second]);
      final answerGate = Completer<void>();
      scheduler.firstAnswerGate = answerGate;
      final session = ReviewSession<Object>(scheduler);
      await session.start();

      final firstAnswer = session.answerCard(ReviewRating.good);
      await scheduler.firstAnswerStarted.future;
      final secondAnswer = session.answerCard(ReviewRating.again);
      answerGate.complete();
      await Future.wait([firstAnswer, secondAnswer]);

      expect(
        scheduler.answers.map((answer) => answer.state.card.id),
        [1, 2],
      );
      expect(
        scheduler.answers.map((answer) => answer.rating),
        [ReviewRating.good, ReviewRating.again],
      );
      expect(session.phase, ReviewSessionPhase.finished);
    });

    test('finishes when the scheduler has no card initially or after the last',
        () async {
      final emptySession = ReviewSession<Object>(_FakeReviewScheduler([]));
      await emptySession.start();
      expect(emptySession.phase, ReviewSessionPhase.finished);
      expect(emptySession.visibleContent, isNull);

      final finalCard = _queueState(1, 'question 1', 'answer 1');
      final finalSession =
          ReviewSession<Object>(_FakeReviewScheduler([finalCard]));
      await finalSession.start();
      await finalSession.showAnswer();
      await finalSession.answerCard(ReviewRating.again);
      expect(finalSession.phase, ReviewSessionPhase.finished);
      expect(finalSession.current, isNull);
      expect(finalSession.visibleContent, isNull);
    });
  });
}

ReviewQueueState<Object> _queueState(
        int cardId, String question, String answer) =>
    ReviewQueueState<Object>(
      card: ReviewCard(
        id: cardId,
        questionHtml: question,
        answerHtml: answer,
      ),
      schedulingSnapshot: Object(),
      counts:
          const ReviewQueueCounts(newCount: 10, learnCount: 5, reviewCount: 20),
      activeQueue: ReviewQueueKind.newCards,
    );

class _FakeReviewScheduler implements ReviewScheduler<Object> {
  _FakeReviewScheduler(this._queue);

  final List<ReviewQueueState<Object>> _queue;
  final answers = <({ReviewQueueState<Object> state, ReviewRating rating})>[];
  int _index = 0;
  int queueReads = 0;
  bool failNextAnswer = false;
  bool failNextQueueRead = false;
  Completer<void>? firstAnswerGate;
  final _mutationGates = <_MutationGate>[];
  final firstAnswerStarted = Completer<void>();
  List<ReviewQueueState<Object>?>? queueReadSequence;
  int _queueReadSequenceIndex = 0;

  @override
  Future<ReviewQueueState<Object>?> currentQueueState() async {
    queueReads++;
    if (failNextQueueRead) {
      failNextQueueRead = false;
      throw StateError('queue refresh failed');
    }
    final sequence = queueReadSequence;
    if (sequence != null) {
      final index = _queueReadSequenceIndex++;
      return index < sequence.length ? sequence[index] : null;
    }
    if (_index >= _queue.length) return null;
    return _queue[_index];
  }

  @override
  Future<void> answerCard(
    ReviewQueueState<Object> state,
    ReviewRating rating,
  ) async {
    answers.add((state: state, rating: rating));
    if (answers.length == 1) {
      firstAnswerStarted.complete();
      if (firstAnswerGate case final gate?) await gate.future;
    }
    if (failNextAnswer) {
      failNextAnswer = false;
      throw StateError('scheduler rejected the answer');
    }
    _index++;
  }

  _MutationGate blockNextMutation() {
    final gate = _MutationGate();
    _mutationGates.add(gate);
    return gate;
  }

  @override
  Future<void> waitForCurrentCardStateMutation() async {
    if (_mutationGates.isEmpty) return;
    final gate = _mutationGates.removeAt(0);
    gate.started.complete();
    await gate.release.future;
  }
}

class _MutationGate {
  final started = Completer<void>();
  final release = Completer<void>();
}
