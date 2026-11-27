// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('answerFuzzSeedForCardIdAndReps', () {
    test('adds the card ID and u32 reps with u64 wrapping', () {
      expect(
        answerFuzzSeedForCardIdAndReps(
          cardId: BigInt.parse('fffffffffffffffe', radix: 16),
          reps: 3,
        ),
        BigInt.one,
      );
      expect(
        answerFuzzSeedForCardIdAndReps(
          cardId: BigInt.from(41),
          reps: 0x1_0000_0002,
        ),
        BigInt.from(43),
      );
    });
  });

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

  group('resolveLearningAnswerDueTimestamp', () {
    test('adds fuzzed seconds to the captured time', () {
      expect(
        resolveLearningAnswerDueTimestamp(
          fuzzedLearningSecs: 90,
          answerTiming: const CollectionAnswerTiming(
            now: 1712345678,
            daysElapsed: 6,
            nextDayAt: 1712347478,
            secsUntilDayRollover: 1800,
          ),
        ),
        1712345768,
      );
    });

    test('uses signed i32 Card representation and validates uint32 inputs', () {
      expect(
        resolveLearningAnswerDueTimestamp(
          fuzzedLearningSecs: 0xffffffff,
          answerTiming: const CollectionAnswerTiming(
            now: 0xffffffff,
            daysElapsed: 0,
            nextDayAt: 0xffffffff,
            secsUntilDayRollover: 0,
          ),
        ),
        -2,
      );

      for (final invalid in [-1, 0x100000000]) {
        expect(
          () => resolveLearningAnswerDueTimestamp(
            fuzzedLearningSecs: invalid,
            answerTiming: const CollectionAnswerTiming(
              now: 0,
              daysElapsed: 0,
              nextDayAt: 0,
              secsUntilDayRollover: 0,
            ),
          ),
          throwsFormatException,
        );
        for (final field in [
          'now',
          'daysElapsed',
          'nextDayAt',
          'secsUntilDayRollover',
        ]) {
          final timing = switch (field) {
            'now' => CollectionAnswerTiming(
              now: invalid,
              daysElapsed: 0,
              nextDayAt: 0,
              secsUntilDayRollover: 0,
            ),
            'daysElapsed' => CollectionAnswerTiming(
              now: 0,
              daysElapsed: invalid,
              nextDayAt: 0,
              secsUntilDayRollover: 0,
            ),
            'nextDayAt' => CollectionAnswerTiming(
              now: 0,
              daysElapsed: 0,
              nextDayAt: invalid,
              secsUntilDayRollover: 0,
            ),
            _ => CollectionAnswerTiming(
              now: 0,
              daysElapsed: 0,
              nextDayAt: 0,
              secsUntilDayRollover: invalid,
            ),
          };
          expect(
            () => resolveLearningAnswerDueTimestamp(
              fuzzedLearningSecs: 0,
              answerTiming: timing,
            ),
            throwsFormatException,
            reason: 'rejects invalid $field',
          );
        }
      }
    });
  });

  group('resolveLearningAnswerElapsedSecs', () {
    test('uses prior-step fuzz seed with wrapping reps for Learn cards', () {
      final card = Card(
        id: Int64(41),
        noteId: Int64(1),
        deckId: Int64(1),
        ctype: CardType.learn,
        queue: CardQueue.learn,
        due: 200000,
        reps: 0,
      );
      const timing = CollectionAnswerTiming(
        now: 1712345678,
        daysElapsed: 10,
        nextDayAt: 1712349278,
        secsUntilDayRollover: 3600,
      );

      // Core adds the wrapped u32 reps value to the u64 card ID.
      final previousStepDue =
          card.due - fuzzLearningIntervalSecs(1200, BigInt.from(4294967336));
      expect(
        resolveLearningAnswerElapsedSecs(
          card: card,
          scheduledSecs: 1200,
          answerTiming: timing,
        ),
        (timing.now - previousStepDue) & 0xffffffff,
      );
    });

    test('derives DayLearn elapsed days with Core signed conversions', () {
      final card = Card(
        id: Int64(9),
        noteId: Int64(1),
        deckId: Int64(1),
        ctype: CardType.relearn,
        queue: CardQueue.dayLearn,
        due: 20,
        reps: 3,
      );
      const timing = CollectionAnswerTiming(
        now: 1712345678,
        daysElapsed: 22,
        nextDayAt: 1712349278,
        secsUntilDayRollover: 3600,
      );

      expect(
        resolveLearningAnswerElapsedSecs(
          card: card,
          scheduledSecs: 90000,
          answerTiming: timing,
        ),
        3 * 86400,
      );
    });

    test(
      'uses one day for same-day DayLearn steps and wraps uint32 seconds',
      () {
        final card = Card(
          id: Int64(9),
          noteId: Int64(1),
          deckId: Int64(1),
          ctype: CardType.learn,
          queue: CardQueue.dayLearn,
          due: 0x7fffffff,
          reps: 1,
        );
        const timing = CollectionAnswerTiming(
          now: 0,
          daysElapsed: 0xffffffff,
          nextDayAt: 86400,
          secsUntilDayRollover: 86400,
        );

        expect(
          resolveLearningAnswerElapsedSecs(
            card: card,
            scheduledSecs: 1,
            answerTiming: timing,
          ),
          (-2147483647 * 86400) & 0xffffffff,
        );
      },
    );
  });
}
