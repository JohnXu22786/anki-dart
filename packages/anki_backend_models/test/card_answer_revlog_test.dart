// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/cards.pb.dart' as cards;
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as scheduler;
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('revlogEntryFromCardAnswer', () {
    test('derives intervals, ease, and kind from normal state variants', () {
      final cases = <(
        scheduler.SchedulingState,
        scheduler.SchedulingState,
        int,
        int,
        int,
        RevlogReviewKind,
      )>[
        (
          normalState(new_1: scheduler.SchedulingState_New(position: 8)),
          normalState(new_1: scheduler.SchedulingState_New(position: 9)),
          0,
          0,
          0,
          RevlogReviewKind.learning,
        ),
        (
          normalState(
            learning: scheduler.SchedulingState_Learning(scheduledSecs: 61),
          ),
          normalState(
            learning: scheduler.SchedulingState_Learning(scheduledSecs: 121),
          ),
          -61,
          -121,
          0,
          RevlogReviewKind.learning,
        ),
        (
          normalState(
            review: scheduler.SchedulingState_Review(
              scheduledDays: 8,
              elapsedDays: 8,
              easeFactor: 2.3,
            ),
          ),
          normalState(
            review: scheduler.SchedulingState_Review(
              scheduledDays: 12,
              elapsedDays: 0,
              easeFactor: 2.65,
            ),
          ),
          8,
          12,
          2650,
          RevlogReviewKind.review,
        ),
        (
          normalState(
            relearning: scheduler.SchedulingState_Relearning(
              review: scheduler.SchedulingState_Review(
                scheduledDays: 7,
                elapsedDays: 7,
                easeFactor: 2.4,
              ),
              learning: scheduler.SchedulingState_Learning(
                scheduledSecs: 600,
              ),
            ),
          ),
          normalState(
            relearning: scheduler.SchedulingState_Relearning(
              review: scheduler.SchedulingState_Review(
                scheduledDays: 9,
                easeFactor: 2.5,
              ),
              learning: scheduler.SchedulingState_Learning(
                scheduledSecs: 300,
              ),
            ),
          ),
          -600,
          -300,
          2500,
          RevlogReviewKind.relearning,
        ),
        (
          normalState(
            review: scheduler.SchedulingState_Review(
              scheduledDays: 8,
              elapsedDays: 2,
              easeFactor: 2.4,
            ),
          ),
          normalState(
            review: scheduler.SchedulingState_Review(
              scheduledDays: 12,
              easeFactor: 2.5,
              memoryState: cards.FsrsMemoryState(difficulty: 7),
            ),
          ),
          8,
          12,
          7100,
          RevlogReviewKind.filtered,
        ),
      ];

      for (final (current, next, lastInterval, interval, ease, kind) in cases) {
        final result = revlogEntryFromCardAnswer(
          answer: answer(current: current, next: next),
          usn: 17,
          secsUntilDayRollover: 3600,
        );
        expect(result.lastInterval, lastInterval);
        expect(result.interval, interval);
        expect(result.easeFactor, ease);
        expect(result.reviewKind, kind);
      }
    });

    test('supports Preview and rescheduling filtered wrappers', () {
      final preview = filteredState(
        preview: scheduler.SchedulingState_Preview(scheduledSecs: 90000),
      );
      final previewResult = revlogEntryFromCardAnswer(
        answer: answer(
          current: filteredState(
            preview: scheduler.SchedulingState_Preview(scheduledSecs: 0),
          ),
          next: preview,
        ),
        usn: 1,
        secsUntilDayRollover: 0,
      );
      expect(previewResult.reviewKind, RevlogReviewKind.filtered);
      expect(previewResult.interval, 2);
      expect(previewResult.easeFactor, 0);

      final rescheduling = (int days) => filteredState(
            rescheduling: scheduler.SchedulingState_ReschedulingFilter(
              originalState: scheduler.SchedulingState_Normal(
                review: scheduler.SchedulingState_Review(
                  scheduledDays: days,
                  elapsedDays: days,
                  easeFactor: 2.5,
                ),
              ),
            ),
          );
      final result = revlogEntryFromCardAnswer(
        answer: answer(current: rescheduling(3), next: rescheduling(5)),
        usn: 2,
        secsUntilDayRollover: 3600,
      );
      expect(result.reviewKind, RevlogReviewKind.review);
      expect(result.lastInterval, 3);
      expect(result.interval, 5);
    });

    test('converts seconds intervals at rollover boundaries', () {
      final current = normalState(
        learning: scheduler.SchedulingState_Learning(scheduledSecs: 3599),
      );
      final next = normalState(
        learning: scheduler.SchedulingState_Learning(scheduledSecs: 90000),
      );
      final result = revlogEntryFromCardAnswer(
        answer: answer(current: current, next: next),
        usn: 1,
        secsUntilDayRollover: 3600,
      );
      expect(result.lastInterval, -3599);
      expect(result.interval, 2);

      final exactlyAtRollover = revlogEntryFromCardAnswer(
        answer: answer(
          current: normalState(
            learning: scheduler.SchedulingState_Learning(scheduledSecs: 3600),
          ),
          next: normalState(
            learning: scheduler.SchedulingState_Learning(scheduledSecs: 89999),
          ),
        ),
        usn: 1,
        secsUntilDayRollover: 3600,
      );
      expect(exactlyAtRollover.lastInterval, 1);
      expect(exactlyAtRollover.interval, 1);
    });

    test('maps all ratings to Core one-based button values', () {
      for (final (rating, button) in <(scheduler.CardAnswer_Rating, int)>[
        (scheduler.CardAnswer_Rating.AGAIN, 1),
        (scheduler.CardAnswer_Rating.HARD, 2),
        (scheduler.CardAnswer_Rating.GOOD, 3),
        (scheduler.CardAnswer_Rating.EASY, 4),
      ]) {
        final result = revlogEntryFromCardAnswer(
          answer: answer(
            current: normalState(new_1: scheduler.SchedulingState_New()),
            next: normalState(new_1: scheduler.SchedulingState_New()),
            rating: rating,
          ),
          usn: 0,
          secsUntilDayRollover: 0,
        );
        expect(result.buttonChosen, button);
      }
    });

    test('preserves 64-bit IDs, timestamp, usn, and elapsed milliseconds', () {
      final cardId = Int64.parseInt('9007199254740997');
      final answeredAt = Int64.parseInt('9223372036854775000');
      final result = revlogEntryFromCardAnswer(
        answer: answer(
          current: normalState(new_1: scheduler.SchedulingState_New()),
          next: normalState(new_1: scheduler.SchedulingState_New()),
          cardId: cardId,
          answeredAtMillis: answeredAt,
          millisecondsTaken: 0xffffffff,
        ),
        usn: -2147483648,
        secsUntilDayRollover: 0,
      );
      expect(result.cardId, cardId);
      expect(result.id.value, answeredAt);
      expect(result.usn, -2147483648);
      expect(result.takenMillis, 0xffffffff);
    });

    test('rejects absent, unsupported, and invalid protocol data', () {
      final validState = normalState(new_1: scheduler.SchedulingState_New());
      expect(
        () => revlogEntryFromCardAnswer(
          answer: scheduler.CardAnswer(),
          usn: 0,
          secsUntilDayRollover: 0,
        ),
        throwsArgumentError,
      );
      for (final invalid in [
        scheduler.SchedulingState(),
        scheduler.SchedulingState(normal: scheduler.SchedulingState_Normal()),
        filteredState(
          rescheduling: scheduler.SchedulingState_ReschedulingFilter(),
        ),
        normalState(
          relearning: scheduler.SchedulingState_Relearning(
            review: scheduler.SchedulingState_Review(),
          ),
        ),
      ]) {
        expect(
          () => revlogEntryFromCardAnswer(
            answer: answer(current: invalid, next: validState),
            usn: 0,
            secsUntilDayRollover: 0,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => revlogEntryFromCardAnswer(
          answer: answer(
            current: validState,
            next: normalState(
              review: scheduler.SchedulingState_Review(easeFactor: double.nan),
            ),
          ),
          usn: 0,
          secsUntilDayRollover: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => revlogEntryFromCardAnswer(
          answer: answer(current: validState, next: validState),
          usn: 0x80000000,
          secsUntilDayRollover: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => revlogEntryFromCardAnswer(
          answer: answer(current: validState, next: validState),
          usn: 0,
          secsUntilDayRollover: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}

scheduler.SchedulingState normalState({
  scheduler.SchedulingState_New? new_1,
  scheduler.SchedulingState_Learning? learning,
  scheduler.SchedulingState_Review? review,
  scheduler.SchedulingState_Relearning? relearning,
}) =>
    scheduler.SchedulingState(
      normal: scheduler.SchedulingState_Normal(
        new_1: new_1,
        learning: learning,
        review: review,
        relearning: relearning,
      ),
    );

scheduler.SchedulingState filteredState({
  scheduler.SchedulingState_Preview? preview,
  scheduler.SchedulingState_ReschedulingFilter? rescheduling,
}) =>
    scheduler.SchedulingState(
      filtered: scheduler.SchedulingState_Filtered(
        preview: preview,
        rescheduling: rescheduling,
      ),
    );

scheduler.CardAnswer answer({
  required scheduler.SchedulingState current,
  required scheduler.SchedulingState next,
  scheduler.CardAnswer_Rating rating = scheduler.CardAnswer_Rating.GOOD,
  Int64? cardId,
  Int64? answeredAtMillis,
  int millisecondsTaken = 32,
}) =>
    scheduler.CardAnswer(
      cardId: cardId ?? Int64(42),
      currentState: current,
      newState: next,
      rating: rating,
      answeredAtMillis: answeredAtMillis ?? Int64(1234567890123),
      millisecondsTaken: millisecondsTaken,
    );
