// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('review-card scheduling states', () {
    test('early reviews use elapsed time without days-late bonuses', () {
      final states = ReviewCardState(
        scheduledDays: 10,
        elapsedDays: 5,
      ).nextStates(const ReviewSchedulingContext());

      expect(states.hard.review.scheduledDays, 6);
      expect(states.good.review.scheduledDays, 13);
      expect(states.easy.review.scheduledDays, 14);
    });

    test('non-early reviews include lateness in each passing interval', () {
      final states = ReviewCardState(
        scheduledDays: 10,
        elapsedDays: 14,
      ).nextStates(const ReviewSchedulingContext());

      expect(states.hard.review.scheduledDays, 12);
      expect(states.good.review.scheduledDays, 30);
      expect(states.easy.review.scheduledDays, 46);
    });

    test('passing ratings update ease and clear absent FSRS memory', () {
      final states = ReviewCardState(
        scheduledDays: 10,
        elapsedDays: 10,
        easeFactor: 2,
        lapses: 4,
        memoryState: FsrsMemoryState(stability: 3, difficulty: 4),
      ).nextStates(const ReviewSchedulingContext());

      expect(states.hard.review.easeFactor, closeTo(1.85, 0.000001));
      expect(states.good.review.easeFactor, 2);
      expect(states.easy.review.easeFactor, closeTo(2.15, 0.000001));
      for (final transition in [states.hard, states.good, states.easy]) {
        expect(transition.review.elapsedDays, 0);
        expect(transition.review.lapses, 4);
        expect(transition.review.memoryState, isNull);
      }
    });

    test('FSRS inputs retain order, memory values, and monotonic constraints',
        () {
      final memory = FsrsMemoryState(stability: 0.123456789, difficulty: 4.25);
      final states = ReviewCardState(scheduledDays: 10).nextStates(
        ReviewSchedulingContext(
          fsrsNextStates: FsrsReviewNextStates(
            again: FsrsReviewNextState(interval: 0.2, memoryState: memory),
            hard: FsrsReviewNextState(interval: 12.4, memoryState: memory),
            good: FsrsReviewNextState(interval: 12.4, memoryState: memory),
            easy: FsrsReviewNextState(interval: 12.4, memoryState: memory),
          ),
          fuzzFactor: 0,
        ),
      );

      expect(states.hard.review.scheduledDays, 11);
      expect(states.good.review.scheduledDays, 12);
      expect(states.easy.review.scheduledDays, 13);
      expect(states.hard.review.memoryState!.stability, 0.12345679104328156);
      expect(states.again.review.memoryState!.difficulty, 4.25);
    });

    test('Again updates lapse fields and selects configured relearning', () {
      final states = ReviewCardState(
        scheduledDays: 10,
        easeFactor: 1.4,
        lapses: 1,
      ).nextStates(
        const ReviewSchedulingContext(
          lapseMultiplier: 0.5,
          minimumLapseInterval: 1,
          leechThreshold: 2,
          relearningAgainDelaySecs: 60,
          relearningRemainingSteps: 3,
        ),
      );

      expect(states.again.kind, ReviewScheduleKind.relearning);
      expect(states.again.review.scheduledDays, 5);
      expect(states.again.review.easeFactor, closeTo(1.3, 0.000001));
      expect(states.again.review.lapses, 2);
      expect(states.again.review.leeched, isTrue);
      expect(states.again.learning!.scheduledSecs, 60);
      expect(states.again.learning!.remainingSteps, 3);
    });

    test('interval fuzz honors minimum, maximum, and deterministic endpoints',
        () {
      final states = ReviewCardState(scheduledDays: 10, elapsedDays: 14)
          .nextStates(const ReviewSchedulingContext(
        fuzzFactor: 0.99,
        maximumReviewInterval: 20,
      ));

      expect(states.hard.review.scheduledDays, lessThanOrEqualTo(20));
      expect(states.good.review.scheduledDays, lessThanOrEqualTo(20));
      expect(states.easy.review.scheduledDays, 20);
      expect(states.hard.review.scheduledDays, greaterThanOrEqualTo(1));
    });

    test('short-term FSRS failures enter relearning only when enabled', () {
      final fsrs = FsrsReviewNextStates(
        again: FsrsReviewNextState(
          interval: 0.25,
          memoryState: FsrsMemoryState(stability: 0.5, difficulty: 5),
        ),
        hard: FsrsReviewNextState(
          interval: 2,
          memoryState: FsrsMemoryState(stability: 0.5, difficulty: 5),
        ),
        good: FsrsReviewNextState(
          interval: 3,
          memoryState: FsrsMemoryState(stability: 0.5, difficulty: 5),
        ),
        easy: FsrsReviewNextState(
          interval: 4,
          memoryState: FsrsMemoryState(stability: 0.5, difficulty: 5),
        ),
      );
      final state = ReviewCardState(scheduledDays: 10);
      final relearning = state
          .nextStates(ReviewSchedulingContext(
            fsrsNextStates: fsrs,
            fsrsAllowShortTerm: true,
            relearningStepsEmpty: true,
          ))
          .again;
      final review = state
          .nextStates(ReviewSchedulingContext(
            fsrsNextStates: fsrs,
            fsrsAllowShortTerm: true,
            fsrsShortTermWithStepsEnabled: false,
            relearningStepsEmpty: false,
          ))
          .again;

      expect(relearning.kind, ReviewScheduleKind.relearning);
      expect(relearning.learning!.scheduledSecs, 21600);
      expect(review.kind, ReviewScheduleKind.review);
    });

    test('Core fuzz boundary fixtures match the source endpoints', () {
      final state = ReviewCardState(
        scheduledDays: 1,
        elapsedDays: 1,
        easeFactor: 1.3,
      );
      ReviewCardSchedulingStates calculate(double fuzzFactor) =>
          state.nextStates(ReviewSchedulingContext(fuzzFactor: fuzzFactor));

      final lower = calculate(0);
      final upper = calculate(0.99);
      expect(
        [
          lower.hard.review.scheduledDays,
          lower.good.review.scheduledDays,
          lower.easy.review.scheduledDays,
        ],
        [2, 3, 4],
      );
      expect(
        [
          upper.hard.review.scheduledDays,
          upper.good.review.scheduledDays,
          upper.easy.review.scheduledDays,
        ],
        [2, 4, 6],
      );
    });

    test('leech cadence keeps Core Float32 threshold rounding', () {
      final states = ReviewCardState(
        scheduledDays: 1,
        lapses: 25165824,
      ).nextStates(const ReviewSchedulingContext(
        leechThreshold: 16777217,
      ));

      expect(states.again.review.lapses, 25165825);
      expect(states.again.review.leeched, isTrue);
    });

    test('u32 elapsed days use Rust signed reinterpretation for early reviews',
        () {
      final states = ReviewCardState(
        scheduledDays: 1,
        elapsedDays: 0x80000001,
      ).nextStates(const ReviewSchedulingContext());

      expect(states.hard.review.scheduledDays, 36500);
    });

    test('days-late subtraction wraps as a signed 32-bit Core value', () {
      final states = ReviewCardState(
        scheduledDays: 0x80000000,
        elapsedDays: 0x7fffffff,
        easeFactor: 1,
      ).nextStates(const ReviewSchedulingContext(
        hardMultiplier: 1,
        maximumReviewInterval: 0xffffffff,
      ));

      expect(states.good.review.scheduledDays, 0x80000000);
    });
  });
}
