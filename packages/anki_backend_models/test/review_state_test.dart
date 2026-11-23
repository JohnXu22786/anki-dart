// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  test('load-balancer augmentation preserves every scheduler input', () {
    final resolver = (double interval, int minimum, int maximum) => maximum;
    final memory = FsrsMemoryState(stability: 3, difficulty: 5);
    final fsrs = FsrsReviewNextStates(
      again: FsrsReviewNextState(interval: 1, memoryState: memory),
      hard: FsrsReviewNextState(interval: 2, memoryState: memory),
      good: FsrsReviewNextState(interval: 3, memoryState: memory),
      easy: FsrsReviewNextState(interval: 4, memoryState: memory),
    );
    final params = List<double>.filled(21, 0.25);
    final learningSteps = <double>[1.5, 10];
    final relearningSteps = <double>[5.5];
    final base = ReviewSchedulingContext(
      hardMultiplier: 1.4,
      easyMultiplier: 1.7,
      intervalMultiplier: 1.2,
      maximumReviewInterval: 321,
      leechThreshold: 9,
      lapseMultiplier: 0.5,
      minimumLapseInterval: 3,
      fuzzFactor: 0.42,
      loadBalancedIntervalResolver: (double i, int min, int max) => min,
      fsrsNextStates: fsrs,
      fsrsParams: params,
      fsrsDesiredRetention: 0.87,
      relearningAgainDelaySecs: 77,
      relearningRemainingSteps: 2,
      fsrsAllowShortTerm: true,
      fsrsShortTermWithStepsEnabled: true,
      relearningStepsEmpty: false,
      learningStepsMinutes: learningSteps,
      relearningStepsMinutes: relearningSteps,
      graduatingIntervalGood: 7,
      graduatingIntervalEasy: 11,
    );

    final augmented = base.withLoadBalancedIntervalResolver(resolver);

    expect(augmented.hardMultiplier, base.hardMultiplier);
    expect(augmented.easyMultiplier, base.easyMultiplier);
    expect(augmented.intervalMultiplier, base.intervalMultiplier);
    expect(augmented.maximumReviewInterval, base.maximumReviewInterval);
    expect(augmented.leechThreshold, base.leechThreshold);
    expect(augmented.lapseMultiplier, base.lapseMultiplier);
    expect(augmented.minimumLapseInterval, base.minimumLapseInterval);
    expect(augmented.fuzzFactor, base.fuzzFactor);
    expect(augmented.loadBalancedIntervalResolver, same(resolver));
    expect(augmented.fsrsNextStates, same(fsrs));
    expect(augmented.fsrsParams, same(params));
    expect(augmented.fsrsDesiredRetention, base.fsrsDesiredRetention);
    expect(augmented.relearningAgainDelaySecs, base.relearningAgainDelaySecs);
    expect(augmented.relearningRemainingSteps, base.relearningRemainingSteps);
    expect(augmented.fsrsAllowShortTerm, base.fsrsAllowShortTerm);
    expect(
      augmented.fsrsShortTermWithStepsEnabled,
      base.fsrsShortTermWithStepsEnabled,
    );
    expect(augmented.relearningStepsEmpty, base.relearningStepsEmpty);
    expect(augmented.learningStepsMinutes, same(learningSteps));
    expect(augmented.relearningStepsMinutes, same(relearningSteps));
    expect(augmented.graduatingIntervalGood, base.graduatingIntervalGood);
    expect(augmented.graduatingIntervalEasy, base.graduatingIntervalEasy);
  });

  group('learning card scheduling states', () {
    test('projects stored Relearn learning and review states', () {
      final card = Card(
        ctype: CardType.relearn,
        interval: 17,
        easeFactorRaw: 2380,
        lapses: 4,
        remainingStepsRaw: 2003,
        memoryState: FsrsMemoryState(stability: 2.5, difficulty: 6.25),
      );

      final states = RelearningCardState.fromCard(
        card,
        scheduledSecs: 361,
        elapsedSecs: 42,
      );

      expect(states.learning.remainingSteps, 3);
      expect(states.learning.scheduledSecs, 361);
      expect(states.learning.elapsedSecs, 42);
      expect(states.learning.memoryState!.stability, 2.5);
      expect(states.review.scheduledDays, 17);
      expect(states.review.elapsedDays, 17);
      expect(states.review.easeFactor, closeTo(2.38, 0.00001));
      expect(states.review.lapses, 4);
      expect(states.review.leeched, isFalse);
      expect(states.review.memoryState!.difficulty, 6.25);
      expect(
        () => RelearningCardState.fromCard(
          Card(ctype: CardType.learn),
          scheduledSecs: 0,
          elapsedSecs: 0,
        ),
        throwsA(isA<InvalidModelValue>()),
      );
    });

    test('Again resets to first step, Hard stays, and Good advances', () {
      final state = LearningCardState(
        remainingSteps: 1,
        scheduledSecs: 600,
        elapsedSecs: 25,
      ).nextStates(
        const ReviewSchedulingContext(learningStepsMinutes: [1, 10]),
      );
      expect(state.again.learning!.remainingSteps, 2);
      expect(state.again.learning!.scheduledSecs, 60);
      expect(state.hard.learning!.remainingSteps, 1);
      expect(state.hard.learning!.scheduledSecs, 600);
      expect(state.good.review!.scheduledDays, 1);
      expect(state.easy.review!.scheduledDays, 4);
    });

    test('New starts learning and empty steps graduate on Again', () {
      final stepped = NewCardState(position: 7).nextStates(
        const ReviewSchedulingContext(learningStepsMinutes: [1, 10]),
      );
      expect(stepped.current.newCard!.position, 7);
      expect(NewCardState(position: -1).position, 0xffffffff);
      expect(stepped.again.learning!.remainingSteps, 2);
      final empty = NewCardState().nextStates(const ReviewSchedulingContext());
      expect(empty.again.review!.scheduledDays, 1);
    });

    test('FSRS short term Good preserves learning remaining steps', () {
      final memory = FsrsMemoryState(stability: 1, difficulty: 5);
      final states = LearningCardState(
        remainingSteps: 1,
        scheduledSecs: 60,
        elapsedSecs: 0,
      ).nextStates(ReviewSchedulingContext(
        learningStepsMinutes: const [1],
        fsrsAllowShortTerm: true,
        fsrsShortTermWithStepsEnabled: true,
        fsrsNextStates: FsrsReviewNextStates(
          again: FsrsReviewNextState(interval: 0.2, memoryState: memory),
          hard: FsrsReviewNextState(interval: 0.2, memoryState: memory),
          good: FsrsReviewNextState(interval: 0.2, memoryState: memory),
          easy: FsrsReviewNextState(interval: 2, memoryState: memory),
        ),
      ));
      expect(states.good.kind, LearningTransitionKind.learning);
      expect(states.good.learning!.remainingSteps, 1);
    });

    test('Hard delay uses Core u32 saturation before averaging large steps',
        () {
      final states = LearningCardState(
        remainingSteps: 2,
        scheduledSecs: 0,
        elapsedSecs: 0,
      ).nextStates(const ReviewSchedulingContext(
        learningStepsMinutes: [1e30, 1e30],
      ));
      expect(states.hard.learning!.scheduledSecs, 2147472000);
      final oneStep = LearningCardState(
        remainingSteps: 1,
        scheduledSecs: 0,
        elapsedSecs: 0,
      ).nextStates(const ReviewSchedulingContext(
        learningStepsMinutes: [1e30],
      ));
      expect(oneStep.hard.learning!.scheduledSecs, 2147472000);
    });

    test('Fractional learning minutes use Core Float32 conversion order', () {
      final states = LearningCardState(
        remainingSteps: 1,
        scheduledSecs: 0,
        elapsedSecs: 0,
      ).nextStates(const ReviewSchedulingContext(
        learningStepsMinutes: [1.05, 2],
      ));
      expect(states.again.learning!.scheduledSecs, 62);
    });

    test('Relearning Hard and FSRS graduation preserve elapsed seconds', () {
      final review = ReviewCardState(scheduledDays: 10);
      final learning = LearningCardState(
        remainingSteps: 1,
        scheduledSecs: 600,
        elapsedSecs: 47,
      );
      final stepped = RelearningCardState(
        review: review,
        learning: learning,
      ).nextStates(const ReviewSchedulingContext(
        relearningStepsMinutes: [10],
      ));
      expect(stepped.hard.learning!.elapsedSecs, 47);

      final memory = FsrsMemoryState(stability: 1, difficulty: 5);
      final short = RelearningCardState(
        review: review,
        learning: learning,
      ).nextStates(ReviewSchedulingContext(
        fsrsAllowShortTerm: true,
        fsrsNextStates: FsrsReviewNextStates(
          again: FsrsReviewNextState(interval: 0.2, memoryState: memory),
          hard: FsrsReviewNextState(interval: 0.2, memoryState: memory),
          good: FsrsReviewNextState(interval: 0.2, memoryState: memory),
          easy: FsrsReviewNextState(interval: 2, memoryState: memory),
        ),
        relearningStepsMinutes: const [],
      ));
      expect(short.hard.learning!.elapsedSecs, 47);
      expect(short.good.learning!.elapsedSecs, 47);
    });

    test(
      'Relearning Good preserves review and FSRS short term keeps learning',
      () {
        final review = ReviewCardState(scheduledDays: 10, lapses: 3);
        final ordinary = RelearningCardState(
          review: review,
          learning: LearningCardState(
            remainingSteps: 1,
            scheduledSecs: 600,
            elapsedSecs: 12,
          ),
        ).nextStates(
          const ReviewSchedulingContext(relearningStepsMinutes: [10]),
        );
        expect(ordinary.good.review!.scheduledDays, 10);
        expect(ordinary.good.review!.lapses, 3);
        final memory = FsrsMemoryState(stability: 1, difficulty: 5);
        final fsrs = FsrsReviewNextStates(
          again: FsrsReviewNextState(interval: 0.2, memoryState: memory),
          hard: FsrsReviewNextState(interval: 0.2, memoryState: memory),
          good: FsrsReviewNextState(interval: 0.2, memoryState: memory),
          easy: FsrsReviewNextState(interval: 2, memoryState: memory),
        );
        final short = RelearningCardState(
          review: review,
          learning: LearningCardState(
            remainingSteps: 1,
            scheduledSecs: 600,
            elapsedSecs: 0,
          ),
        ).nextStates(
          ReviewSchedulingContext(
            fsrsNextStates: fsrs,
            fsrsAllowShortTerm: true,
            relearningStepsMinutes: const [],
          ),
        );
        expect(short.good.kind, LearningTransitionKind.relearning);
        expect(short.good.learning!.scheduledSecs, 17280);
        expect(short.good.review!.scheduledDays, 1);
      },
    );

    test('Relearning preserves Core interval and untouched review fields', () {
      final review = ReviewCardState(
        scheduledDays: 10,
        elapsedDays: 4,
        lapses: 2,
      );
      final emptySteps = RelearningCardState(
        review: review,
        learning: LearningCardState(
          remainingSteps: 0,
          scheduledSecs: 0,
          elapsedSecs: 0,
        ),
      ).nextStates(const ReviewSchedulingContext(
        maximumReviewInterval: 1,
        minimumLapseInterval: 3,
        lapseMultiplier: 0,
        fuzzFactor: 0.99,
      ));
      expect(emptySteps.good.review!.elapsedDays, 4);
      expect(emptySteps.again.review!.scheduledDays, 10);
      expect(emptySteps.easy.review!.scheduledDays, 11);

      final configuredSteps = RelearningCardState(
        review: review,
        learning: LearningCardState(
          remainingSteps: 1,
          scheduledSecs: 600,
          elapsedSecs: 0,
        ),
      ).nextStates(const ReviewSchedulingContext(
        relearningStepsMinutes: [10],
        minimumLapseInterval: 3,
        lapseMultiplier: 0,
      ));
      expect(configuredSteps.again.review!.scheduledDays, 3);

      final memory = FsrsMemoryState(stability: 1, difficulty: 5);
      final fsrsAgain = RelearningCardState(
        review: review,
        learning: LearningCardState(
          remainingSteps: 1,
          scheduledSecs: 600,
          elapsedSecs: 0,
        ),
      ).nextStates(ReviewSchedulingContext(
        relearningStepsMinutes: const [10],
        fsrsNextStates: FsrsReviewNextStates(
          again: FsrsReviewNextState(interval: 10.1, memoryState: memory),
          hard: FsrsReviewNextState(interval: 10, memoryState: memory),
          good: FsrsReviewNextState(interval: 10, memoryState: memory),
          easy: FsrsReviewNextState(interval: 11, memoryState: memory),
        ),
        fuzzFactor: 0.99,
      ));
      expect(fsrsAgain.again.review!.scheduledDays, 10);
      expect(fsrsAgain.again.review!.elapsedDays, 0);

      final fsrsNoSteps = RelearningCardState(
        review: review,
        learning: LearningCardState(
          remainingSteps: 0,
          scheduledSecs: 0,
          elapsedSecs: 0,
        ),
      ).nextStates(ReviewSchedulingContext(
        fsrsNextStates: FsrsReviewNextStates(
          again: FsrsReviewNextState(interval: 10, memoryState: memory),
          hard: FsrsReviewNextState(interval: 10, memoryState: memory),
          good: FsrsReviewNextState(interval: 10, memoryState: memory),
          easy: FsrsReviewNextState(interval: 11, memoryState: memory),
        ),
      ));
      expect(fsrsNoSteps.hard.review!.elapsedDays, 4);
      expect(fsrsNoSteps.good.review!.elapsedDays, 4);
    });
  });

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

    test('balanced interval resolver receives adjusted intervals and bounds',
        () {
      final calls = <(double, int, int)>[];
      final states = ReviewCardState(
        scheduledDays: 10,
        elapsedDays: 10,
      ).nextStates(ReviewSchedulingContext(
        intervalMultiplier: 1.5,
        fuzzFactor: 0.99,
        loadBalancedIntervalResolver: (interval, minimum, maximum) {
          calls.add((interval, minimum, maximum));
          return minimum;
        },
      ));

      expect(
        calls.map((call) => call.$1).toList(),
        [18, 37.5, 48.75],
      );
      expect(calls.map((call) => call.$2).toList(), [11, 12, 13]);
      expect(calls.every((call) => call.$3 == 36500), isTrue);
      expect(
        [
          states.hard.review.scheduledDays,
          states.good.review.scheduledDays,
          states.easy.review.scheduledDays,
        ],
        [11, 12, 13],
      );
    });

    test('null balanced interval falls back to deterministic review fuzz', () {
      final state = ReviewCardState(scheduledDays: 10, elapsedDays: 10);
      final fallback = state.nextStates(ReviewSchedulingContext(
        fuzzFactor: 0.99,
        loadBalancedIntervalResolver: (_, __, ___) => null,
      ));
      final ordinary = state.nextStates(
        const ReviewSchedulingContext(fuzzFactor: 0.99),
      );

      expect(
        [
          fallback.hard.review.scheduledDays,
          fallback.good.review.scheduledDays,
          fallback.easy.review.scheduledDays,
        ],
        [
          ordinary.hard.review.scheduledDays,
          ordinary.good.review.scheduledDays,
          ordinary.easy.review.scheduledDays,
        ],
      );
    });

    test('absent balanced interval resolver preserves existing fuzz output',
        () {
      final state = ReviewCardState(scheduledDays: 10, elapsedDays: 14);
      final withoutResolver = state.nextStates(
        const ReviewSchedulingContext(fuzzFactor: 0.4),
      );
      final direct = state.nextStates(ReviewSchedulingContext(
        fuzzFactor: 0.4,
        loadBalancedIntervalResolver: null,
      ));

      expect(
        [
          direct.hard.review.scheduledDays,
          direct.good.review.scheduledDays,
          direct.easy.review.scheduledDays,
        ],
        [
          withoutResolver.hard.review.scheduledDays,
          withoutResolver.good.review.scheduledDays,
          withoutResolver.easy.review.scheduledDays,
        ],
      );
    });

    test('early review bypasses balanced interval resolver', () {
      var calls = 0;
      final states = ReviewCardState(
        scheduledDays: 10,
        elapsedDays: 5,
      ).nextStates(ReviewSchedulingContext(
        fuzzFactor: 0.99,
        loadBalancedIntervalResolver: (_, __, ___) {
          calls++;
          return 1;
        },
      ));

      expect(calls, 0);
      expect(
        [
          states.hard.review.scheduledDays,
          states.good.review.scheduledDays,
          states.easy.review.scheduledDays,
        ],
        [6, 13, 14],
      );
    });

    test('supplied FSRS intervals use balanced sequential minima', () {
      final memory = FsrsMemoryState(stability: 2, difficulty: 5);
      final states = ReviewCardState(scheduledDays: 10).nextStates(
        ReviewSchedulingContext(
          fuzzFactor: 0.99,
          fsrsNextStates: FsrsReviewNextStates(
            again: FsrsReviewNextState(interval: 1, memoryState: memory),
            hard: FsrsReviewNextState(interval: 12, memoryState: memory),
            good: FsrsReviewNextState(interval: 12, memoryState: memory),
            easy: FsrsReviewNextState(interval: 12, memoryState: memory),
          ),
          loadBalancedIntervalResolver: (_, minimum, __) => minimum,
        ),
      );

      expect(
        [
          states.hard.review.scheduledDays,
          states.good.review.scheduledDays,
          states.easy.review.scheduledDays,
        ],
        [11, 12, 13],
      );
    });

    test('computed FSRS state derivation preserves balanced interval resolver',
        () {
      var calls = 0;
      final states = ReviewCardState(scheduledDays: 10).nextStates(
        ReviewSchedulingContext(
          fsrsParams: const [],
          fsrsDesiredRetention: 0.9,
          fuzzFactor: 0.99,
          loadBalancedIntervalResolver: (_, minimum, __) {
            calls++;
            return minimum;
          },
        ),
      );

      expect(calls, 3);
      expect(
        [
          states.hard.review.scheduledDays,
          states.good.review.scheduledDays,
          states.easy.review.scheduledDays,
        ],
        [1, 2, 3],
      );
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

    test(
      'FSRS inputs retain order, memory values, and monotonic constraints',
      () {
        final memory = FsrsMemoryState(
          stability: 0.123456789,
          difficulty: 4.25,
        );
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
      },
    );

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

    test(
      'interval fuzz honors minimum, maximum, and deterministic endpoints',
      () {
        final states =
            ReviewCardState(scheduledDays: 10, elapsedDays: 14).nextStates(
          const ReviewSchedulingContext(
            fuzzFactor: 0.99,
            maximumReviewInterval: 20,
          ),
        );

        expect(states.hard.review.scheduledDays, lessThanOrEqualTo(20));
        expect(states.good.review.scheduledDays, lessThanOrEqualTo(20));
        expect(states.easy.review.scheduledDays, 20);
        expect(states.hard.review.scheduledDays, greaterThanOrEqualTo(1));
      },
    );

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
          .nextStates(
            ReviewSchedulingContext(
              fsrsNextStates: fsrs,
              fsrsAllowShortTerm: true,
              relearningStepsEmpty: true,
            ),
          )
          .again;
      final review = state
          .nextStates(
            ReviewSchedulingContext(
              fsrsNextStates: fsrs,
              fsrsAllowShortTerm: true,
              fsrsShortTermWithStepsEnabled: false,
              relearningStepsEmpty: false,
            ),
          )
          .again;

      expect(relearning.kind, ReviewScheduleKind.relearning);
      expect(relearning.learning!.scheduledSecs, 21600);
      expect(review.kind, ReviewScheduleKind.review);
    });

    test('Core fuzz boundary fixtures match the source endpoints', () {
      expect(constrainedFuzzBounds(5, 1, 20), (4, 6));
      expect(constrainedFuzzBounds(5, 5, 5), (5, 5));
      expect(constrainedFuzzBounds(5, 10, 5), (5, 5));
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
      ).nextStates(const ReviewSchedulingContext(leechThreshold: 16777217));

      expect(states.again.review.lapses, 25165825);
      expect(states.again.review.leeched, isTrue);
    });

    test(
      'u32 elapsed days use Rust signed reinterpretation for early reviews',
      () {
        final states = ReviewCardState(
          scheduledDays: 1,
          elapsedDays: 0x80000001,
        ).nextStates(const ReviewSchedulingContext());

        expect(states.hard.review.scheduledDays, 36500);
      },
    );

    test('days-late subtraction wraps as a signed 32-bit Core value', () {
      final states = ReviewCardState(
        scheduledDays: 0x80000000,
        elapsedDays: 0x7fffffff,
        easeFactor: 1,
      ).nextStates(
        const ReviewSchedulingContext(
          hardMultiplier: 1,
          maximumReviewInterval: 0xffffffff,
        ),
      );

      expect(states.good.review.scheduledDays, 0x80000000);
    });
  });
}
