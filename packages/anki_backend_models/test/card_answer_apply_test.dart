// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/cards.pb.dart' as proto;
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as scheduler;
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

void main() {
  group('applyNewCardAnswerState', () {
    test('applies every rating that produces a Normal/New state', () {
      final ratings = <scheduler.CardAnswer_Rating>[
        scheduler.CardAnswer_Rating.AGAIN,
        scheduler.CardAnswer_Rating.HARD,
        scheduler.CardAnswer_Rating.GOOD,
        scheduler.CardAnswer_Rating.EASY,
      ];

      for (final (index, rating) in ratings.indexed) {
        final position = index.isEven ? 0 : 37;
        final answer = _answer(
          position: position,
          rating: rating,
          customData: 'rating-${rating.name}',
        );
        final card = Card(id: Int64(42));

        final updated = applyNewCardAnswerState(
          card: card,
          answer: answer,
          desiredRetention: null,
        );

        expect(updated.ctype, CardType.newCard);
        expect(updated.queue, CardQueue.newCard);
        expect(updated.due, position);
        expect(updated.customData, 'rating-${rating.name}');
      }
    });

    test(
        'copies answer values, clears nullable fields, and preserves other data',
        () {
      final card = Card(
        id: Int64(42),
        noteId: Int64(43),
        deckId: Int64(44),
        templateIdx: 7,
        mtimeSecs: Int64(45),
        usn: 12,
        ctype: CardType.review,
        queue: CardQueue.review,
        due: 46,
        interval: 47,
        easeFactorRaw: 2300,
        reps: 77,
        lapses: 48,
        remainingStepsRaw: 49,
        originalDue: 50,
        originalDeckId: Int64(51),
        flags: 52,
        originalPosition: 53,
        memoryState: FsrsMemoryState(stability: 54.5, difficulty: 5.5),
        desiredRetention: 0.8,
        decay: 0.1542,
        lastReviewTimeSecs: Int64(55),
        customData: 'old custom data',
      );
      final answer = _answer(position: 56, customData: '');
      final answerBefore = answer.deepCopy();
      final cardBefore = card.toProto();

      final updated = applyNewCardAnswerState(
        card: card,
        answer: answer,
        desiredRetention: 0.9,
      );

      expect(updated.reps, 78);
      expect(updated.originalPosition, isNull);
      expect(updated.memoryState, isNull);
      expect(updated.customData, '');
      expect(updated.desiredRetention, closeTo(0.9, 0.000001));
      expect(updated.id, card.id);
      expect(updated.noteId, card.noteId);
      expect(updated.deckId, card.deckId);
      expect(updated.templateIdx, card.templateIdx);
      expect(updated.mtimeSecs, card.mtimeSecs);
      expect(updated.usn, card.usn);
      expect(updated.interval, card.interval);
      expect(updated.easeFactorRaw, card.easeFactorRaw);
      expect(updated.lapses, card.lapses);
      expect(updated.remainingStepsRaw, card.remainingStepsRaw);
      expect(updated.originalDue, card.originalDue);
      expect(updated.originalDeckId, card.originalDeckId);
      expect(updated.flags, card.flags);
      expect(updated.decay, card.decay);
      expect(updated.lastReviewTimeSecs, card.lastReviewTimeSecs);
      expect(card.toProto(), cardBefore);
      expect(answer, answerBefore);
      expect(identical(updated, card), isFalse);
    });

    test('clears retention when the explicit Core input is absent', () {
      final card = Card(id: Int64(42), desiredRetention: 0.85);
      final updated = applyNewCardAnswerState(
        card: card,
        answer: _answer(position: 1),
        desiredRetention: null,
      );
      expect(updated.desiredRetention, isNull);
    });

    test('rejects an answer for another card or a non-Normal/New state', () {
      final card = Card(id: Int64(42));
      expect(
        () => applyNewCardAnswerState(
          card: card,
          answer: _answer(position: 1, cardId: Int64(43)),
          desiredRetention: null,
        ),
        throwsArgumentError,
      );
      for (final state in <scheduler.SchedulingState>[
        scheduler.SchedulingState(),
        scheduler.SchedulingState(normal: scheduler.SchedulingState_Normal()),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            learning: scheduler.SchedulingState_Learning(scheduledSecs: 60),
          ),
        ),
        scheduler.SchedulingState(
          filtered: scheduler.SchedulingState_Filtered(
            preview: scheduler.SchedulingState_Preview(scheduledSecs: 60),
          ),
        ),
      ]) {
        expect(
          () => applyNewCardAnswerState(
            card: card,
            answer: scheduler.CardAnswer(
              cardId: card.id,
              newState: state,
              rating: scheduler.CardAnswer_Rating.GOOD,
            ),
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('applyLearningCardAnswerState', () {
    test('applies New-to-Learning with caller-resolved intraday due', () {
      final card = _learningCard(
        originalPosition: 91,
        memoryState: FsrsMemoryState(stability: 5, difficulty: 6),
      );
      final answer = _learningAnswer(
        currentState: _normalNewState(position: 91),
        remainingSteps: 0,
        customData: 'learning custom data',
      );
      final cardBefore = card.toProto();
      final answerBefore = answer.deepCopy();

      final updated = applyLearningCardAnswerState(
        card: card,
        answer: answer,
        queue: CardQueue.learn,
        due: 1700000123,
        desiredRetention: 0.9,
      );

      expect(updated.ctype, CardType.learn);
      expect(updated.queue, CardQueue.learn);
      expect(updated.due, 1700000123);
      expect(updated.reps, card.reps + 1);
      expect(updated.remainingSteps, 0);
      expect(updated.originalPosition, 91);
      expect(updated.memoryState, isNull);
      expect(updated.customData, 'learning custom data');
      expect(updated.desiredRetention, closeTo(0.9, 0.000001));
      _expectUnchangedCardFields(updated, card);
      expect(card.toProto(), cardBefore);
      expect(answer, answerBefore);
      expect(identical(updated, card), isFalse);
    });

    test('applies Learning-to-Learning with day due and new memory state', () {
      final card = _learningCard(
        originalPosition: 92,
        remainingStepsRaw: 1007,
        desiredRetention: 0.8,
      );
      final answer = _learningAnswer(
        currentState: _normalLearningState(remainingSteps: 1),
        remainingSteps: 7,
        memoryState: proto.FsrsMemoryState(
          stability: 12.5,
          difficulty: 4.25,
        ),
        customData: '',
      );

      final updated = applyLearningCardAnswerState(
        card: card,
        answer: answer,
        queue: CardQueue.dayLearn,
        due: 27,
        desiredRetention: null,
      );

      expect(updated.ctype, CardType.learn);
      expect(updated.queue, CardQueue.dayLearn);
      expect(updated.due, 27);
      expect(updated.reps, card.reps + 1);
      expect(updated.remainingSteps, 7);
      expect(updated.originalPosition, card.originalPosition);
      expect(updated.memoryState!.stability, 12.5);
      expect(updated.memoryState!.difficulty, 4.25);
      expect(updated.customData, '');
      expect(updated.desiredRetention, isNull);
      _expectUnchangedCardFields(updated, card);
    });

    test('rejects mismatched IDs and unsupported state wrappers', () {
      final card = _learningCard();
      final validCurrent = _normalNewState(position: 1);
      final invalidCurrentStates = <scheduler.SchedulingState>[
        scheduler.SchedulingState(),
        scheduler.SchedulingState(normal: scheduler.SchedulingState_Normal()),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            review: scheduler.SchedulingState_Review(),
          ),
        ),
        scheduler.SchedulingState(
          filtered: scheduler.SchedulingState_Filtered(
            preview: scheduler.SchedulingState_Preview(scheduledSecs: 60),
          ),
        ),
      ];
      for (final state in invalidCurrentStates) {
        expect(
          () => applyLearningCardAnswerState(
            card: card,
            answer: _learningAnswer(currentState: state),
            queue: CardQueue.learn,
            due: 123,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }

      for (final state in <scheduler.SchedulingState>[
        scheduler.SchedulingState(),
        scheduler.SchedulingState(normal: scheduler.SchedulingState_Normal()),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            learning: scheduler.SchedulingState_Learning(),
          ),
        ),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            new_1: scheduler.SchedulingState_New(position: 1),
          ),
        ),
        scheduler.SchedulingState(
          filtered: scheduler.SchedulingState_Filtered(
            preview: scheduler.SchedulingState_Preview(scheduledSecs: 60),
          ),
        ),
      ]) {
        expect(
          () => applyLearningCardAnswerState(
            card: card,
            answer: scheduler.CardAnswer(
              cardId: card.id,
              currentState: validCurrent,
              newState: state,
              rating: scheduler.CardAnswer_Rating.GOOD,
            ),
            queue: CardQueue.learn,
            due: 123,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }

      expect(
        () => applyLearningCardAnswerState(
          card: card,
          answer: _learningAnswer(
            currentState: validCurrent,
            cardId: Int64(43),
          ),
          queue: CardQueue.learn,
          due: 123,
          desiredRetention: null,
        ),
        throwsArgumentError,
      );
    });

    test('rejects queues outside caller-resolved Learning due classes', () {
      final card = _learningCard();
      final answer =
          _learningAnswer(currentState: _normalNewState(position: 1));
      for (final queue in <CardQueue>[
        CardQueue.newCard,
        CardQueue.review,
        CardQueue.previewRepeat,
        CardQueue.suspended,
        CardQueue.schedBuried,
        CardQueue.userBuried,
      ]) {
        expect(
          () => applyLearningCardAnswerState(
            card: card,
            answer: answer,
            queue: queue,
            due: 123,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('applyReviewCardAnswerState', () {
    test('applies Review outcomes and maps the new state to the Card', () {
      for (final rating in <scheduler.CardAnswer_Rating>[
        scheduler.CardAnswer_Rating.AGAIN,
        scheduler.CardAnswer_Rating.HARD,
        scheduler.CardAnswer_Rating.GOOD,
        scheduler.CardAnswer_Rating.EASY,
      ]) {
        final card = _learningCard(
          originalPosition: 91,
          remainingStepsRaw: 49,
          memoryState: FsrsMemoryState(stability: 2.5, difficulty: 7),
        );
        final review = scheduler.SchedulingState_Review(
          scheduledDays: 77,
          elapsedDays: 4,
          easeFactor: 2.3456,
          lapses: 12,
          memoryState: proto.FsrsMemoryState(stability: 9.5, difficulty: 3.25),
        );
        final answer = _reviewAnswer(
          currentState: _normalNewState(position: 91),
          review: review,
          rating: rating,
          customData: 'review-${rating.name}',
        );
        final cardBefore = card.toProto();
        final answerBefore = answer.deepCopy();

        final updated = applyReviewCardAnswerState(
          card: card,
          answer: answer,
          dueDay: 1234,
          desiredRetention: 0.9,
        );

        expect(updated.ctype, CardType.review);
        expect(updated.queue, CardQueue.review);
        expect(updated.due, 1234);
        expect(updated.interval, 77);
        expect(updated.easeFactorRaw, 2346);
        expect(updated.lapses, 12);
        expect(updated.remainingSteps, 0);
        expect(updated.reps, card.reps + 1);
        expect(updated.originalPosition, 91);
        expect(updated.memoryState!.stability, 9.5);
        expect(updated.memoryState!.difficulty, 3.25);
        expect(updated.desiredRetention, closeTo(0.9, 0.000001));
        expect(updated.customData, 'review-${rating.name}');
        _expectReviewUnchangedCardFields(updated, card);
        expect(updated.originalPosition, 91);
        expect(card.toProto(), cardBefore);
        expect(answer, answerBefore);
        expect(identical(updated, card), isFalse);
      }
    });

    test('preserves original position for non-New Normal current states', () {
      final card = _learningCard(
        originalPosition: 88,
        memoryState: FsrsMemoryState(stability: 4, difficulty: 5),
      );
      for (final currentState in <scheduler.SchedulingState>[
        _normalLearningState(remainingSteps: 1),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            review: scheduler.SchedulingState_Review(scheduledDays: 1),
          ),
        ),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            relearning: scheduler.SchedulingState_Relearning(
              review: scheduler.SchedulingState_Review(scheduledDays: 1),
            ),
          ),
        ),
      ]) {
        final updated = applyReviewCardAnswerState(
          card: card,
          answer: _reviewAnswer(currentState: currentState),
          dueDay: 10,
          desiredRetention: null,
        );
        expect(updated.originalPosition, 88);
        expect(updated.desiredRetention, isNull);
        expect(updated.memoryState, isNull);
      }

      final answerWithUnsetCustomData = scheduler.CardAnswer(
        cardId: card.id,
        currentState: _normalNewState(position: 1),
        newState: scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            review: scheduler.SchedulingState_Review(
              scheduledDays: 1,
              easeFactor: 2.5,
              lapses: 0,
            ),
          ),
        ),
        rating: scheduler.CardAnswer_Rating.GOOD,
      );
      expect(answerWithUnsetCustomData.newState.hasCustomData(), isFalse);
      final unchangedCustomData = applyReviewCardAnswerState(
        card: card,
        answer: answerWithUnsetCustomData,
        dueDay: 10,
        desiredRetention: null,
      );
      expect(unchangedCustomData.customData, card.customData);
    });

    test('rejects mismatched IDs, unsupported wrappers, and missing fields',
        () {
      final card = _learningCard();
      final validCurrent = _normalNewState(position: 1);
      for (final currentState in <scheduler.SchedulingState>[
        scheduler.SchedulingState(),
        scheduler.SchedulingState(normal: scheduler.SchedulingState_Normal()),
        scheduler.SchedulingState(
          filtered: scheduler.SchedulingState_Filtered(
            preview: scheduler.SchedulingState_Preview(scheduledSecs: 60),
          ),
        ),
      ]) {
        expect(
          () => applyReviewCardAnswerState(
            card: card,
            answer: _reviewAnswer(currentState: currentState),
            dueDay: 1,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => applyReviewCardAnswerState(
          card: card,
          answer: _reviewAnswer(
            currentState: validCurrent,
            cardId: Int64(43),
          ),
          dueDay: 1,
          desiredRetention: null,
        ),
        throwsArgumentError,
      );
      expect(
        () => applyReviewCardAnswerState(
          card: card,
          answer: scheduler.CardAnswer(
            cardId: card.id,
            newState: _reviewAnswer(currentState: validCurrent).newState,
            rating: scheduler.CardAnswer_Rating.GOOD,
          ),
          dueDay: 1,
          desiredRetention: null,
        ),
        throwsArgumentError,
      );

      final malformedReviews = <scheduler.SchedulingState_Review>[
        scheduler.SchedulingState_Review(
            elapsedDays: 1, easeFactor: 2.5, lapses: 1),
        scheduler.SchedulingState_Review(
            scheduledDays: 1, elapsedDays: 1, lapses: 1),
        scheduler.SchedulingState_Review(scheduledDays: 1, easeFactor: 2.5),
      ];
      for (final review in malformedReviews) {
        expect(
          () => applyReviewCardAnswerState(
            card: card,
            answer: _reviewAnswer(currentState: validCurrent, review: review),
            dueDay: 1,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }
      for (final newState in <scheduler.SchedulingState>[
        scheduler.SchedulingState(),
        scheduler.SchedulingState(normal: scheduler.SchedulingState_Normal()),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            learning: scheduler.SchedulingState_Learning(),
          ),
        ),
        scheduler.SchedulingState(
          filtered: scheduler.SchedulingState_Filtered(
            preview: scheduler.SchedulingState_Preview(scheduledSecs: 60),
          ),
        ),
      ]) {
        expect(
          () => applyReviewCardAnswerState(
            card: card,
            answer: scheduler.CardAnswer(
              cardId: card.id,
              currentState: validCurrent,
              newState: newState,
              rating: scheduler.CardAnswer_Rating.GOOD,
            ),
            dueDay: 1,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('applyRelearningCardAnswerState', () {
    test('maps paired state fields and all supported current-state kinds', () {
      final card = _learningCard(
        originalPosition: 88,
        remainingStepsRaw: 49,
        memoryState: FsrsMemoryState(stability: 2, difficulty: 7),
      );
      final review = scheduler.SchedulingState_Review(
        scheduledDays: 77,
        elapsedDays: 4,
        easeFactor: 2.3456,
        lapses: 12,
      );
      final learning = scheduler.SchedulingState_Learning(
        remainingSteps: 3,
        scheduledSecs: 60,
        elapsedSecs: 5,
        memoryState: proto.FsrsMemoryState(stability: 9.5, difficulty: 3.25),
      );
      final currentStates = <scheduler.SchedulingState>[
        _normalNewState(position: 91),
        _normalLearningState(remainingSteps: 2),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            review: scheduler.SchedulingState_Review(scheduledDays: 2),
          ),
        ),
        _normalRelearningState(
          review: scheduler.SchedulingState_Review(scheduledDays: 1),
          learning: scheduler.SchedulingState_Learning(remainingSteps: 1),
        ),
      ];

      for (final (index, currentState) in currentStates.indexed) {
        final answer = _relearningAnswer(
          currentState: currentState,
          review: review,
          learning: learning,
        );
        final answerBefore = answer.deepCopy();
        final cardBefore = card.toProto();
        final queue = index.isEven ? CardQueue.learn : CardQueue.dayLearn;
        final due = index.isEven ? 1700000123 : 27;

        final updated = applyRelearningCardAnswerState(
          card: card,
          answer: answer,
          queue: queue,
          due: due,
          desiredRetention: 0.9,
        );

        expect(updated.ctype, CardType.relearn);
        expect(updated.queue, queue);
        expect(updated.due, due);
        expect(updated.interval, 77);
        expect(updated.easeFactorRaw, 2346);
        expect(updated.lapses, 12);
        expect(updated.remainingSteps, 3);
        expect(updated.reps, card.reps + 1);
        expect(updated.originalPosition, index == 0 ? 91 : 88);
        expect(updated.memoryState!.stability, 9.5);
        expect(updated.memoryState!.difficulty, 3.25);
        expect(updated.desiredRetention, closeTo(0.9, 0.000001));
        expect(updated.customData, 'relearning answer data');
        _expectReviewUnchangedCardFields(updated, card);
        expect(updated.originalDue, card.originalDue);
        expect(
            updated.originalPosition, index == 0 ? 91 : card.originalPosition);
        expect(card.toProto(), cardBefore);
        expect(answer, answerBefore);
        expect(identical(updated, card), isFalse);
      }
    });

    test(
        'clears absent learning memory, applies nullable retention, and handles custom data presence',
        () {
      final card = _learningCard(
        memoryState: FsrsMemoryState(stability: 2, difficulty: 7),
        desiredRetention: 0.8,
      );
      final base = _relearningAnswer(
        currentState: _normalNewState(position: 42),
        learning: scheduler.SchedulingState_Learning(remainingSteps: 0),
      );

      final withEmptyCustomData = base.deepCopy()..newState.customData = '';
      final cleared = applyRelearningCardAnswerState(
        card: card,
        answer: withEmptyCustomData,
        queue: CardQueue.learn,
        due: 0,
        desiredRetention: null,
      );
      expect(cleared.memoryState, isNull);
      expect(cleared.remainingSteps, 0);
      expect(cleared.desiredRetention, isNull);
      expect(cleared.customData, '');

      final absentCustomData = scheduler.CardAnswer(
        cardId: card.id,
        currentState: _normalNewState(position: 42),
        newState: _relearningState(
          learning: scheduler.SchedulingState_Learning(remainingSteps: 1),
        ),
        rating: scheduler.CardAnswer_Rating.GOOD,
      );
      expect(absentCustomData.newState.hasCustomData(), isFalse);
      final preserved = applyRelearningCardAnswerState(
        card: card,
        answer: absentCustomData,
        queue: CardQueue.dayLearn,
        due: -10,
        desiredRetention: 0.75,
      );
      expect(preserved.customData, card.customData);
      expect(preserved.memoryState, isNull);
      expect(preserved.desiredRetention, closeTo(0.75, 0.000001));
      expect(preserved.due, -10);
    });

    test(
        'rejects mismatched IDs, unsupported wrappers, and missing paired fields',
        () {
      final card = _learningCard();
      final current = _normalNewState(position: 1);
      expect(
        () => applyRelearningCardAnswerState(
          card: card,
          answer: _relearningAnswer(currentState: current, cardId: Int64(43)),
          queue: CardQueue.learn,
          due: 1,
          desiredRetention: null,
        ),
        throwsArgumentError,
      );

      for (final currentState in <scheduler.SchedulingState>[
        scheduler.SchedulingState(),
        scheduler.SchedulingState(normal: scheduler.SchedulingState_Normal()),
        scheduler.SchedulingState(
          filtered: scheduler.SchedulingState_Filtered(
            preview: scheduler.SchedulingState_Preview(scheduledSecs: 60),
          ),
        ),
      ]) {
        expect(
          () => applyRelearningCardAnswerState(
            card: card,
            answer: _relearningAnswer(currentState: currentState),
            queue: CardQueue.learn,
            due: 1,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }

      for (final newState in <scheduler.SchedulingState>[
        scheduler.SchedulingState(),
        scheduler.SchedulingState(normal: scheduler.SchedulingState_Normal()),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            review: scheduler.SchedulingState_Review(scheduledDays: 1),
          ),
        ),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            relearning: scheduler.SchedulingState_Relearning(
              learning: scheduler.SchedulingState_Learning(remainingSteps: 1),
            ),
          ),
        ),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            relearning: scheduler.SchedulingState_Relearning(
              review: scheduler.SchedulingState_Review(scheduledDays: 1),
            ),
          ),
        ),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            relearning: scheduler.SchedulingState_Relearning(
              review: scheduler.SchedulingState_Review(
                scheduledDays: 1,
                easeFactor: 2.5,
                lapses: 2,
              ),
              learning: scheduler.SchedulingState_Learning(),
            ),
          ),
        ),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            relearning: scheduler.SchedulingState_Relearning(
              review: scheduler.SchedulingState_Review(
                easeFactor: 2.5,
                lapses: 2,
              ),
              learning: scheduler.SchedulingState_Learning(remainingSteps: 1),
            ),
          ),
        ),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            relearning: scheduler.SchedulingState_Relearning(
              review: scheduler.SchedulingState_Review(
                scheduledDays: 1,
                lapses: 2,
              ),
              learning: scheduler.SchedulingState_Learning(remainingSteps: 1),
            ),
          ),
        ),
        scheduler.SchedulingState(
          normal: scheduler.SchedulingState_Normal(
            relearning: scheduler.SchedulingState_Relearning(
              review: scheduler.SchedulingState_Review(
                scheduledDays: 1,
                easeFactor: 2.5,
              ),
              learning: scheduler.SchedulingState_Learning(remainingSteps: 1),
            ),
          ),
        ),
        scheduler.SchedulingState(
          filtered: scheduler.SchedulingState_Filtered(
            preview: scheduler.SchedulingState_Preview(scheduledSecs: 60),
          ),
        ),
      ]) {
        expect(
          () => applyRelearningCardAnswerState(
            card: card,
            answer: scheduler.CardAnswer(
              cardId: card.id,
              currentState: current,
              newState: newState,
              rating: scheduler.CardAnswer_Rating.GOOD,
            ),
            queue: CardQueue.learn,
            due: 1,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }

      for (final queue in <CardQueue>[
        CardQueue.newCard,
        CardQueue.review,
        CardQueue.previewRepeat,
        CardQueue.suspended,
        CardQueue.schedBuried,
        CardQueue.userBuried,
      ]) {
        expect(
          () => applyRelearningCardAnswerState(
            card: card,
            answer: _relearningAnswer(currentState: current),
            queue: queue,
            due: 1,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }
    });
  });
}

scheduler.CardAnswer _answer({
  required int position,
  scheduler.CardAnswer_Rating rating = scheduler.CardAnswer_Rating.GOOD,
  Int64? cardId,
  String customData = 'answer data',
}) =>
    scheduler.CardAnswer(
      cardId: cardId ?? Int64(42),
      newState: scheduler.SchedulingState(
        normal: scheduler.SchedulingState_Normal(
          new_1: scheduler.SchedulingState_New(position: position),
        ),
      )..customData = customData,
      rating: rating,
    );

Card _learningCard({
  int originalPosition = 53,
  int remainingStepsRaw = 49,
  FsrsMemoryState? memoryState,
  double? desiredRetention = 0.8,
}) =>
    Card(
      id: Int64(42),
      noteId: Int64(43),
      deckId: Int64(44),
      templateIdx: 7,
      mtimeSecs: Int64(45),
      usn: 12,
      ctype: CardType.newCard,
      queue: CardQueue.newCard,
      due: 46,
      interval: 47,
      easeFactorRaw: 2300,
      reps: 77,
      lapses: 48,
      remainingStepsRaw: remainingStepsRaw,
      originalDue: 50,
      originalDeckId: Int64(51),
      flags: 52,
      originalPosition: originalPosition,
      memoryState: memoryState,
      desiredRetention: desiredRetention,
      decay: 0.1542,
      lastReviewTimeSecs: Int64(55),
      customData: 'old custom data',
    );

scheduler.SchedulingState _normalNewState({required int position}) =>
    scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        new_1: scheduler.SchedulingState_New(position: position),
      ),
    );

scheduler.SchedulingState _normalLearningState({required int remainingSteps}) =>
    scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        learning: scheduler.SchedulingState_Learning(
          remainingSteps: remainingSteps,
          scheduledSecs: 30,
          elapsedSecs: 2,
        ),
      ),
    );

scheduler.CardAnswer _learningAnswer({
  required scheduler.SchedulingState currentState,
  int remainingSteps = 1,
  proto.FsrsMemoryState? memoryState,
  Int64? cardId,
  String customData = 'answer data',
}) =>
    scheduler.CardAnswer(
      cardId: cardId ?? Int64(42),
      currentState: currentState,
      newState: scheduler.SchedulingState(
        normal: scheduler.SchedulingState_Normal(
          learning: scheduler.SchedulingState_Learning(
            remainingSteps: remainingSteps,
            scheduledSecs: 60,
            elapsedSecs: 3,
            memoryState: memoryState,
          ),
        ),
      )..customData = customData,
      rating: scheduler.CardAnswer_Rating.GOOD,
    );

scheduler.CardAnswer _reviewAnswer({
  required scheduler.SchedulingState currentState,
  scheduler.SchedulingState_Review? review,
  scheduler.CardAnswer_Rating rating = scheduler.CardAnswer_Rating.GOOD,
  Int64? cardId,
  String customData = 'review answer data',
}) =>
    scheduler.CardAnswer(
      cardId: cardId ?? Int64(42),
      currentState: currentState,
      newState: scheduler.SchedulingState(
        normal: scheduler.SchedulingState_Normal(
          review: review ??
              scheduler.SchedulingState_Review(
                scheduledDays: 7,
                elapsedDays: 2,
                easeFactor: 2.3,
                lapses: 3,
              ),
        ),
      )..customData = customData,
      rating: rating,
    );

scheduler.SchedulingState _normalRelearningState({
  required scheduler.SchedulingState_Review review,
  required scheduler.SchedulingState_Learning learning,
}) =>
    scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        relearning: scheduler.SchedulingState_Relearning(
          review: review,
          learning: learning,
        ),
      ),
    );

scheduler.SchedulingState _relearningState({
  scheduler.SchedulingState_Review? review,
  scheduler.SchedulingState_Learning? learning,
}) =>
    scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        relearning: scheduler.SchedulingState_Relearning(
          review: review ??
              scheduler.SchedulingState_Review(
                scheduledDays: 7,
                elapsedDays: 2,
                easeFactor: 2.3,
                lapses: 3,
              ),
          learning: learning ??
              scheduler.SchedulingState_Learning(
                remainingSteps: 1,
                scheduledSecs: 60,
                elapsedSecs: 3,
              ),
        ),
      ),
    );

scheduler.CardAnswer _relearningAnswer({
  required scheduler.SchedulingState currentState,
  scheduler.SchedulingState_Review? review,
  scheduler.SchedulingState_Learning? learning,
  Int64? cardId,
}) =>
    scheduler.CardAnswer(
      cardId: cardId ?? Int64(42),
      currentState: currentState,
      newState: _relearningState(review: review, learning: learning)
        ..customData = 'relearning answer data',
      rating: scheduler.CardAnswer_Rating.GOOD,
    );

void _expectUnchangedCardFields(Card updated, Card original) {
  expect(updated.id, original.id);
  expect(updated.noteId, original.noteId);
  expect(updated.deckId, original.deckId);
  expect(updated.templateIdx, original.templateIdx);
  expect(updated.mtimeSecs, original.mtimeSecs);
  expect(updated.usn, original.usn);
  expect(updated.interval, original.interval);
  expect(updated.easeFactorRaw, original.easeFactorRaw);
  expect(updated.lapses, original.lapses);
  expect(updated.originalDue, original.originalDue);
  expect(updated.originalDeckId, original.originalDeckId);
  expect(updated.flags, original.flags);
  expect(updated.decay, original.decay);
  expect(updated.lastReviewTimeSecs, original.lastReviewTimeSecs);
}

void _expectReviewUnchangedCardFields(Card updated, Card original) {
  expect(updated.id, original.id);
  expect(updated.noteId, original.noteId);
  expect(updated.deckId, original.deckId);
  expect(updated.templateIdx, original.templateIdx);
  expect(updated.mtimeSecs, original.mtimeSecs);
  expect(updated.usn, original.usn);
  expect(updated.originalDue, original.originalDue);
  expect(updated.originalDeckId, original.originalDeckId);
  expect(updated.flags, original.flags);
  expect(updated.decay, original.decay);
  expect(updated.lastReviewTimeSecs, original.lastReviewTimeSecs);
}
