// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as scheduler;
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

void main() {
  group('applyReschedulingFilteredCardAnswerState', () {
    test('applies every Normal outcome while staying filtered or leaving', () {
      for (final leavesFilteredDeck in <bool>[false, true]) {
        for (final kind in <scheduler.SchedulingState_Normal_Kind>[
          scheduler.SchedulingState_Normal_Kind.new_1,
          scheduler.SchedulingState_Normal_Kind.learning,
          scheduler.SchedulingState_Normal_Kind.review,
          scheduler.SchedulingState_Normal_Kind.relearning,
        ]) {
          final card = _card();
          final normal = _normal(kind);
          final answer = _answer(
            card: card,
            current: _filtered(
              _normal(scheduler.SchedulingState_Normal_Kind.new_1),
            ),
            next: leavesFilteredDeck ? _filtered(normal) : _normalState(normal),
            customData: 'next-${kind.name}',
          );
          final beforeCard = card.toProto();
          final beforeAnswer = answer.deepCopy();

          final updated = applyReschedulingFilteredCardAnswerState(
            card: card,
            answer: answer,
            learningQueue: CardQueue.dayLearn,
            learningDue: 78,
            reviewDueDay: 91,
            desiredRetention: 0.91,
          );

          expect(
            updated.deckId,
            leavesFilteredDeck ? card.deckId : card.originalDeckId,
          );
          expect(
            updated.originalDeckId,
            leavesFilteredDeck ? card.originalDeckId : Int64.ZERO,
          );
          expect(updated.originalDue, leavesFilteredDeck ? updated.due : 0);
          expect(updated.reps, card.reps + 1);
          expect(updated.customData, 'next-${kind.name}');
          expect(updated.desiredRetention, closeTo(0.91, 0.000001));
          switch (kind) {
            case scheduler.SchedulingState_Normal_Kind.new_1:
              expect(updated.ctype, CardType.newCard);
              expect(updated.due, 15);
            case scheduler.SchedulingState_Normal_Kind.learning:
              expect(updated.ctype, CardType.learn);
              expect(updated.queue, CardQueue.dayLearn);
              expect(updated.due, 78);
            case scheduler.SchedulingState_Normal_Kind.review:
              expect(updated.ctype, CardType.review);
              expect(updated.queue, CardQueue.review);
              expect(updated.due, 91);
            case scheduler.SchedulingState_Normal_Kind.relearning:
              expect(updated.ctype, CardType.relearn);
              expect(updated.queue, CardQueue.dayLearn);
              expect(updated.due, 78);
            case scheduler.SchedulingState_Normal_Kind.notSet:
              fail('test only covers populated states');
          }
          expect(card.toProto(), beforeCard);
          expect(answer, beforeAnswer);
        }
      }
    });

    test(
      'validates due inputs and preserves optional custom data semantics',
      () {
        final card = _card(customData: 'existing');
        final learning = _normal(
          scheduler.SchedulingState_Normal_Kind.learning,
        );
        final learningAnswer = _answer(
          card: card,
          current: _filtered(
            _normal(scheduler.SchedulingState_Normal_Kind.new_1),
          ),
          next: _filtered(learning),
          customData: '',
        );
        expect(
          () => applyReschedulingFilteredCardAnswerState(
            card: card,
            answer: learningAnswer,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
        expect(
          applyReschedulingFilteredCardAnswerState(
            card: card,
            answer: learningAnswer,
            learningQueue: CardQueue.learn,
            learningDue: 88,
            desiredRetention: null,
          ).customData,
          '',
        );

        final reviewAnswer = _answer(
          card: card,
          current: _filtered(
            _normal(scheduler.SchedulingState_Normal_Kind.review),
          ),
          next: _filtered(
            _normal(scheduler.SchedulingState_Normal_Kind.review),
          ),
        );
        expect(
          () => applyReschedulingFilteredCardAnswerState(
            card: card,
            answer: reviewAnswer,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
        final preserved = applyReschedulingFilteredCardAnswerState(
          card: card,
          answer: reviewAnswer,
          reviewDueDay: 66,
          desiredRetention: null,
        );
        expect(preserved.customData, 'existing');
        expect(preserved.desiredRetention, isNull);

        final newAnswer = _answer(
          card: card,
          current:
              _filtered(_normal(scheduler.SchedulingState_Normal_Kind.new_1)),
          next: _normalState(
              _normal(scheduler.SchedulingState_Normal_Kind.new_1)),
        );
        expect(
          applyReschedulingFilteredCardAnswerState(
            card: card,
            answer: newAnswer,
            desiredRetention: null,
          ).customData,
          'existing',
        );

        for (final kind in <scheduler.SchedulingState_Normal_Kind>[
          scheduler.SchedulingState_Normal_Kind.new_1,
          scheduler.SchedulingState_Normal_Kind.learning,
          scheduler.SchedulingState_Normal_Kind.review,
          scheduler.SchedulingState_Normal_Kind.relearning,
        ]) {
          final answer = _answer(
            card: card,
            current: _filtered(
              _normal(scheduler.SchedulingState_Normal_Kind.new_1),
            ),
            next: _filtered(_normal(kind)),
          );
          final updated = applyReschedulingFilteredCardAnswerState(
            card: card,
            answer: answer,
            learningQueue: kind == scheduler.SchedulingState_Normal_Kind.review
                ? null
                : CardQueue.learn,
            learningDue: kind == scheduler.SchedulingState_Normal_Kind.review
                ? null
                : 10,
            reviewDueDay: kind == scheduler.SchedulingState_Normal_Kind.review
                ? 10
                : null,
            desiredRetention: null,
          );
          expect(updated.customData, card.customData);
        }
      },
    );

    test('rejects malformed wrappers, states, IDs, and nonfiltered cards', () {
      final card = _card();
      final current = _filtered(
        _normal(scheduler.SchedulingState_Normal_Kind.review),
      );
      final next = _filtered(
        _normal(scheduler.SchedulingState_Normal_Kind.review),
      );
      final invalidCurrent = <scheduler.SchedulingState>[
        scheduler.SchedulingState(),
        _normalState(_normal(scheduler.SchedulingState_Normal_Kind.review)),
        scheduler.SchedulingState(
          filtered: scheduler.SchedulingState_Filtered(
            preview: scheduler.SchedulingState_Preview(finished: false),
          ),
        ),
        scheduler.SchedulingState(
          filtered: scheduler.SchedulingState_Filtered(
            rescheduling: scheduler.SchedulingState_ReschedulingFilter(),
          ),
        ),
        _filtered(scheduler.SchedulingState_Normal()),
      ];
      for (final state in invalidCurrent) {
        expect(
          () => applyReschedulingFilteredCardAnswerState(
            card: card,
            answer: _answer(card: card, current: state, next: next),
            reviewDueDay: 1,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }
      final invalidNext = <scheduler.SchedulingState>[
        scheduler.SchedulingState(),
        scheduler.SchedulingState(
          filtered: scheduler.SchedulingState_Filtered(
            preview: scheduler.SchedulingState_Preview(finished: false),
          ),
        ),
        scheduler.SchedulingState(
          filtered: scheduler.SchedulingState_Filtered(
            rescheduling: scheduler.SchedulingState_ReschedulingFilter(),
          ),
        ),
        _normalState(scheduler.SchedulingState_Normal()),
      ];
      for (final state in invalidNext) {
        expect(
          () => applyReschedulingFilteredCardAnswerState(
            card: card,
            answer: _answer(card: card, current: current, next: state),
            reviewDueDay: 1,
            desiredRetention: null,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => applyReschedulingFilteredCardAnswerState(
          card: card,
          answer: _answer(
            card: card,
            current: current,
            next: next,
            id: Int64(999),
          ),
          reviewDueDay: 1,
          desiredRetention: null,
        ),
        throwsArgumentError,
      );
      expect(
        () => applyReschedulingFilteredCardAnswerState(
          card: _card(originalDeckId: Int64.ZERO),
          answer: _answer(card: card, current: current, next: next),
          reviewDueDay: 1,
          desiredRetention: null,
        ),
        throwsArgumentError,
      );
    });
  });
}

Card _card({Int64? originalDeckId, String customData = 'card data'}) => Card(
      id: Int64(42),
      noteId: Int64(43),
      deckId: Int64(44),
      ctype: CardType.review,
      queue: CardQueue.review,
      due: 12,
      interval: 7,
      reps: 77,
      originalDue: 31,
      originalDeckId: originalDeckId ?? Int64(51),
      customData: customData,
    );

scheduler.SchedulingState_Normal _normal(
  scheduler.SchedulingState_Normal_Kind kind,
) =>
    switch (kind) {
      scheduler.SchedulingState_Normal_Kind.new_1 =>
        scheduler.SchedulingState_Normal(
          new_1: scheduler.SchedulingState_New(position: 15),
        ),
      scheduler.SchedulingState_Normal_Kind.learning =>
        scheduler.SchedulingState_Normal(
          learning: scheduler.SchedulingState_Learning(remainingSteps: 2),
        ),
      scheduler.SchedulingState_Normal_Kind.review =>
        scheduler.SchedulingState_Normal(
          review: scheduler.SchedulingState_Review(
            scheduledDays: 21,
            easeFactor: 2.5,
            lapses: 3,
          ),
        ),
      scheduler.SchedulingState_Normal_Kind.relearning =>
        scheduler.SchedulingState_Normal(
          relearning: scheduler.SchedulingState_Relearning(
            review: scheduler.SchedulingState_Review(
              scheduledDays: 22,
              easeFactor: 2.4,
              lapses: 4,
            ),
            learning: scheduler.SchedulingState_Learning(remainingSteps: 1),
          ),
        ),
      scheduler.SchedulingState_Normal_Kind.notSet =>
        scheduler.SchedulingState_Normal(),
    };

scheduler.SchedulingState _normalState(
  scheduler.SchedulingState_Normal normal,
) =>
    scheduler.SchedulingState(normal: normal);

scheduler.SchedulingState _filtered(scheduler.SchedulingState_Normal normal) =>
    scheduler.SchedulingState(
      filtered: scheduler.SchedulingState_Filtered(
        rescheduling: scheduler.SchedulingState_ReschedulingFilter(
          originalState: normal,
        ),
      ),
    );

scheduler.CardAnswer _answer({
  required Card card,
  required scheduler.SchedulingState current,
  required scheduler.SchedulingState next,
  Int64? id,
  String? customData,
}) {
  if (customData != null) next.customData = customData;
  return scheduler.CardAnswer(
    cardId: id ?? card.id,
    currentState: current,
    newState: next,
    rating: scheduler.CardAnswer_Rating.GOOD,
  );
}
