// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
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
