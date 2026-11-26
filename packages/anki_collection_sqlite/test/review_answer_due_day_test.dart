// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('resolveReviewAnswerDueDay', () {
    test('adds scheduled days to the captured collection day', () {
      final timing = CollectionAnswerTiming(
        now: 0,
        daysElapsed: 17,
        nextDayAt: 86400,
        secsUntilDayRollover: 86400,
      );

      expect(
        resolveReviewAnswerDueDay(
          nextState: ReviewCardState(scheduledDays: 12),
          answerTiming: timing,
        ),
        29,
      );
    });

    test('zero scheduled days remain due on the captured collection day', () {
      final timing = CollectionAnswerTiming(
        now: 0,
        daysElapsed: 0,
        nextDayAt: 86400,
        secsUntilDayRollover: 86400,
      );

      expect(
        resolveReviewAnswerDueDay(
          nextState: ReviewCardState(scheduledDays: 0),
          answerTiming: timing,
        ),
        0,
      );
      expect(
        resolveReviewAnswerDueDay(
          nextState: ReviewCardState(scheduledDays: 0),
          answerTiming: CollectionAnswerTiming(
            now: 0,
            daysElapsed: 2147483647,
            nextDayAt: 86400,
            secsUntilDayRollover: 86400,
          ),
        ),
        2147483647,
      );
    });

    test('uses signed i32 representation at the storage boundary', () {
      expect(
        resolveReviewAnswerDueDay(
          nextState: ReviewCardState(scheduledDays: 1),
          answerTiming: CollectionAnswerTiming(
            now: 0,
            daysElapsed: 2147483647,
            nextDayAt: 86400,
            secsUntilDayRollover: 86400,
          ),
        ),
        -2147483648,
      );
      expect(
        resolveReviewAnswerDueDay(
          nextState: ReviewCardState(scheduledDays: 0xffffffff),
          answerTiming: CollectionAnswerTiming(
            now: 0,
            daysElapsed: 0xffffffff,
            nextDayAt: 86400,
            secsUntilDayRollover: 86400,
          ),
        ),
        -2,
      );
    });
  });

  group('resolveLearningAnswerDueDay', () {
    const timing = CollectionAnswerTiming(
      now: 1000,
      daysElapsed: 17,
      nextDayAt: 1900,
      secsUntilDayRollover: 900,
    );

    test('returns no due day below the rollover barrier', () {
      expect(
        resolveLearningAnswerDueDay(scheduledSecs: 899, answerTiming: timing),
        isNull,
      );
    });

    test('uses the inclusive rollover boundary and whole-day offsets', () {
      expect(
        resolveLearningAnswerDueDay(scheduledSecs: 900, answerTiming: timing),
        18,
      );
      expect(
        resolveLearningAnswerDueDay(
          scheduledSecs: 900 + 2 * 86400 + 1,
          answerTiming: timing,
        ),
        20,
      );
    });

    test('wraps the due day to the signed i32 storage representation', () {
      expect(
        resolveLearningAnswerDueDay(
          scheduledSecs: 900,
          answerTiming: CollectionAnswerTiming(
            now: 0,
            daysElapsed: 0x7fffffff,
            nextDayAt: 900,
            secsUntilDayRollover: 900,
          ),
        ),
        -0x80000000,
      );
    });
  });
}
