// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as scheduler;
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

void main() {
  group('applyFilteredPreviewCardAnswerState', () {
    test(
        'applies unfinished preview with caller-resolved due and preserves card state',
        () {
      final card = _card(queue: CardQueue.review, due: 12, customData: 'keep');
      final answer = _answer(
        cardId: card.id,
        current: _preview(scheduledSecs: 60, finished: false),
        next: _preview(scheduledSecs: 30, finished: false, customData: 'new'),
      );
      final beforeCard = card.toProto();
      final beforeAnswer = answer.deepCopy();

      final updated = applyFilteredPreviewCardAnswerState(
        card: card,
        answer: answer,
        dueTimestampSecs: 1700000000,
      );

      expect(updated.queue, CardQueue.previewRepeat);
      expect(updated.due, 1700000000);
      expect(updated.ctype, card.ctype);
      expect(updated.reps, card.reps);
      expect(updated.originalDue, card.originalDue);
      expect(updated.originalDeckId, card.originalDeckId);
      expect(updated.desiredRetention, card.desiredRetention);
      expect(updated.memoryState!.stability, card.memoryState!.stability);
      expect(updated.customData, 'new');
      _expectUnchangedFields(updated, card);
      expect(card.toProto(), beforeCard);
      expect(answer, beforeAnswer);
      expect(identical(updated, card), isFalse);
    });

    test(
        'finished preview restores deck and due, deriving queue from type and due',
        () {
      for (final (type, expectedQueue, originalDue, due)
          in <(CardType, CardQueue, int, int)>[
        (CardType.newCard, CardQueue.newCard, 0, 4),
        (CardType.review, CardQueue.review, 23, 4),
        (CardType.learn, CardQueue.learn, 0, 1700000000),
        (CardType.learn, CardQueue.dayLearn, 0, 23),
        (CardType.relearn, CardQueue.learn, 1700000001, 1000000001),
        (CardType.relearn, CardQueue.dayLearn, 12, 1000000000),
      ]) {
        final card = _card(
          ctype: type,
          queue: CardQueue.previewRepeat,
          due: due,
          originalDue: originalDue,
          originalDeckId: Int64(20),
          customData: 'existing',
        );
        final answer = _answer(
          cardId: card.id,
          current: _preview(scheduledSecs: 5, finished: false),
          next: _preview(scheduledSecs: 0, finished: true),
        );

        final updated = applyFilteredPreviewCardAnswerState(
          card: card,
          answer: answer,
        );

        expect(updated.queue, expectedQueue);
        expect(updated.due, originalDue == 0 ? due : originalDue);
        expect(updated.deckId, Int64(20));
        expect(updated.originalDeckId, Int64.ZERO);
        expect(updated.originalDue, 0);
        expect(updated.ctype, type);
        expect(updated.reps, card.reps);
        expect(updated.desiredRetention, card.desiredRetention);
        expect(updated.customData, 'existing');
      }
    });

    test(
        'finished preview preserves negative queues and applies present custom data',
        () {
      for (final queue in <CardQueue>[
        CardQueue.suspended,
        CardQueue.schedBuried,
        CardQueue.userBuried,
      ]) {
        final card = _card(queue: queue, originalDue: 30, customData: 'old');
        final updated = applyFilteredPreviewCardAnswerState(
          card: card,
          answer: _answer(
            cardId: card.id,
            current: _preview(scheduledSecs: 1, finished: false),
            next: _preview(scheduledSecs: 0, finished: true, customData: ''),
          ),
        );
        expect(updated.queue, queue);
        expect(updated.customData, '');
      }
    });

    test(
        'unfinished preview requires resolved due; missing custom data preserves it',
        () {
      final card = _card(customData: 'old');
      final answer = _answer(
        cardId: card.id,
        current: _preview(scheduledSecs: 0, finished: false),
        next: _preview(scheduledSecs: 20, finished: false),
      );
      expect(
        () => applyFilteredPreviewCardAnswerState(card: card, answer: answer),
        throwsArgumentError,
      );
      final updated = applyFilteredPreviewCardAnswerState(
        card: card,
        answer: answer,
        dueTimestampSecs: 1700000000,
      );
      expect(updated.customData, 'old');
    });

    test(
        'rejects wrong IDs, wrappers, missing required fields and cards outside filtered decks',
        () {
      final card = _card();
      final validCurrent = _preview(scheduledSecs: 1, finished: false);
      final validNext = _preview(scheduledSecs: 2, finished: false);
      final invalidStates = <scheduler.SchedulingState>[
        scheduler.SchedulingState(),
        scheduler.SchedulingState(
            filtered: scheduler.SchedulingState_Filtered()),
        scheduler.SchedulingState(normal: scheduler.SchedulingState_Normal()),
        scheduler.SchedulingState(
            filtered: scheduler.SchedulingState_Filtered(
          rescheduling: scheduler.SchedulingState_ReschedulingFilter(),
        )),
        scheduler.SchedulingState(
            filtered: scheduler.SchedulingState_Filtered(
          preview: scheduler.SchedulingState_Preview(finished: false),
        )),
      ];
      for (final state in invalidStates) {
        expect(
            () => applyFilteredPreviewCardAnswerState(
                  card: card,
                  answer:
                      _answer(cardId: card.id, current: state, next: validNext),
                  dueTimestampSecs: 10,
                ),
            throwsArgumentError);
        expect(
            () => applyFilteredPreviewCardAnswerState(
                  card: card,
                  answer: _answer(
                      cardId: card.id, current: validCurrent, next: state),
                  dueTimestampSecs: 10,
                ),
            throwsArgumentError);
      }
      expect(
          () => applyFilteredPreviewCardAnswerState(
                card: card,
                answer: _answer(
                    cardId: Int64(999), current: validCurrent, next: validNext),
                dueTimestampSecs: 10,
              ),
          throwsArgumentError);
      for (final originalDeckId in <Int64>[Int64.ZERO]) {
        final notFiltered = _card(originalDeckId: originalDeckId);
        expect(
            () => applyFilteredPreviewCardAnswerState(
                  card: notFiltered,
                  answer: _answer(
                      cardId: notFiltered.id,
                      current: validCurrent,
                      next: validNext),
                  dueTimestampSecs: 10,
                ),
            throwsArgumentError);
      }
    });
  });
}

Card _card({
  CardType ctype = CardType.review,
  CardQueue queue = CardQueue.learn,
  int due = 10,
  int originalDue = 7,
  Int64? originalDeckId,
  String customData = 'card data',
}) =>
    Card(
      id: Int64(42),
      noteId: Int64(43),
      deckId: Int64(44),
      templateIdx: 7,
      mtimeSecs: Int64(45),
      usn: 12,
      ctype: ctype,
      queue: queue,
      due: due,
      interval: 47,
      easeFactorRaw: 2300,
      reps: 77,
      lapses: 48,
      remainingStepsRaw: 49,
      originalDue: originalDue,
      originalDeckId: originalDeckId ?? Int64(51),
      flags: 52,
      originalPosition: 53,
      memoryState: FsrsMemoryState(stability: 54.5, difficulty: 5.5),
      desiredRetention: 0.8,
      decay: 0.1542,
      lastReviewTimeSecs: Int64(55),
      customData: customData,
    );

scheduler.SchedulingState _preview({
  int? scheduledSecs,
  bool? finished,
  String? customData,
}) {
  final state = scheduler.SchedulingState(
    filtered: scheduler.SchedulingState_Filtered(
      preview: scheduler.SchedulingState_Preview(
        scheduledSecs: scheduledSecs,
        finished: finished,
      ),
    ),
  );
  if (customData != null) state.customData = customData;
  return state;
}

scheduler.CardAnswer _answer({
  required Int64 cardId,
  required scheduler.SchedulingState current,
  required scheduler.SchedulingState next,
}) =>
    scheduler.CardAnswer(
      cardId: cardId,
      currentState: current,
      newState: next,
      rating: scheduler.CardAnswer_Rating.GOOD,
    );

void _expectUnchangedFields(Card actual, Card before) {
  expect(actual.id, before.id);
  expect(actual.noteId, before.noteId);
  expect(actual.deckId, before.deckId);
  expect(actual.templateIdx, before.templateIdx);
  expect(actual.mtimeSecs, before.mtimeSecs);
  expect(actual.usn, before.usn);
  expect(actual.interval, before.interval);
  expect(actual.easeFactorRaw, before.easeFactorRaw);
  expect(actual.lapses, before.lapses);
  expect(actual.remainingStepsRaw, before.remainingStepsRaw);
  expect(actual.flags, before.flags);
  expect(actual.originalPosition, before.originalPosition);
  expect(actual.decay, before.decay);
  expect(actual.lastReviewTimeSecs, before.lastReviewTimeSecs);
}
