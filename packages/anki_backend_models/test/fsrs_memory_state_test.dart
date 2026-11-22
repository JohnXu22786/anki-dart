// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

final _nextDayAt = Int64(86400 * 1000);

RevlogEntry _entry({
  required RevlogReviewKind kind,
  required int daysAgo,
  int rating = 3,
  int interval = 1,
  int easeFactor = 0,
}) =>
    RevlogEntry(
      id: RevlogId(Int64((_nextDayAt.toInt() - daysAgo * 86400) * 1000)),
      buttonChosen: rating,
      interval: interval,
      easeFactor: easeFactor,
      reviewKind: kind,
    );

FsrsMemoryState? _compute(
  List<RevlogEntry> revlogs, {
  List<double> params = const [],
  Int64? cutoff,
}) =>
    computeFsrsMemoryState(
      revlogs: revlogs,
      nextDayAt: _nextDayAt,
      params: params,
      historicalRetention: 0.9,
      ignoreRevlogsBefore: cutoff ?? Int64.ZERO,
    );

void main() {
  group('FSRS memory state', () {
    test('computes all new-card rating states with pinned FSRS defaults', () {
      final states = computeFsrsNextStates(
        currentMemoryState: null,
        daysElapsed: 0,
        desiredRetention: 0.9,
        params: const [],
      );

      // FSRS 5.2.0 initializes stability from w[0..3] and computes difficulty
      // from the rating-specific initial-difficulty equation.
      expect(states.again.memoryState.stability, closeTo(0.212, 0.000001));
      expect(states.hard.memoryState.stability, closeTo(1.2931, 0.0001));
      expect(states.good.memoryState.stability, closeTo(2.3065, 0.0001));
      expect(states.easy.memoryState.stability, closeTo(8.2956, 0.0001));
      expect(states.again.memoryState.difficulty, closeTo(6.4133, 0.0001));
      expect(states.easy.memoryState.difficulty, closeTo(1.0, 0.0001));
      expect(
        states.again.interval,
        closeTo(states.again.memoryState.stability, 0.0001),
      );
      expect(states.easy.interval, greaterThan(states.good.interval));
    });

    test(
      'uses explicit elapsed days, retention and pre-existing memory state',
      () {
        final parameters = [
          0.6845422,
          1.6790825,
          4.7349424,
          10.042885,
          7.4410233,
          0.64219797,
          1.071918,
          0.0025195254,
          1.432437,
          0.1544,
          0.8692766,
          2.0696752,
          0.0953,
          0.2975,
          2.4691248,
          0.19542035,
          3.201072,
          0.18046261,
          0.121442534,
        ];
        final afterTwentyOneDays = computeFsrsNextStates(
          currentMemoryState: FsrsMemoryState(
            stability: 21,
            difficulty: 8,
          ),
          daysElapsed: 21,
          desiredRetention: 0.9,
          params: parameters,
        );
        final sameDay = computeFsrsNextStates(
          currentMemoryState: FsrsMemoryState(
            stability: 21,
            difficulty: 8,
          ),
          daysElapsed: 0,
          desiredRetention: 0.9,
          params: parameters,
        );

        expect(
          afterTwentyOneDays.again.memoryState.stability,
          greaterThan(sameDay.again.memoryState.stability),
        );
        expect(
          afterTwentyOneDays.good.interval,
          closeTo(afterTwentyOneDays.good.memoryState.stability, 0.001),
        );
        expect(
          afterTwentyOneDays.easy.memoryState.difficulty,
          lessThan(afterTwentyOneDays.again.memoryState.difficulty),
        );
        expect(
          computeFsrsNextStates(
            currentMemoryState: FsrsMemoryState(
              stability: 21,
              difficulty: 8,
            ),
            daysElapsed: 21,
            desiredRetention: 1,
            params: parameters,
          ).good.interval,
          0,
        );
        expect(
          computeFsrsNextInterval(
            stability: 1,
            desiredRetention: 0,
            params: parameters,
          ).isInfinite,
          isTrue,
        );
      },
    );

    test('matches the fsrs 5.2.0 next interval fixture', () {
      final parameters = List<double>.filled(21, 0)
        ..[0] = 0.212
        ..[1] = 1.2931
        ..[2] = 2.3065
        ..[3] = 8.2956
        ..[4] = 6.4133
        ..[5] = 0.8334
        ..[6] = 3.0194
        ..[7] = 0.001
        ..[8] = 1.8722
        ..[9] = 0.1666
        ..[10] = 0.796
        ..[11] = 1.4835
        ..[12] = 0.0614
        ..[13] = 0.2629
        ..[14] = 1.6483
        ..[15] = 0.6014
        ..[16] = 1.8729
        ..[17] = 0.5425
        ..[18] = 0.0912
        ..[19] = 0.0658
        ..[20] = 0.1542;

      expect(
        computeFsrsNextInterval(
          stability: 121.01552,
          desiredRetention: 0.9,
          params: parameters,
        ),
        closeTo(121.01551, 0.0001),
      );
    });

    test(
      'review projections can compute FSRS states while legacy inputs remain',
      () {
        const params = <double>[];
        final computed = ReviewCardState(
          scheduledDays: 10,
          elapsedDays: 12,
          memoryState: FsrsMemoryState(stability: 10, difficulty: 6),
        ).nextStates(
          const ReviewSchedulingContext(
            fsrsParams: params,
            fsrsDesiredRetention: 0.9,
          ),
        );
        final direct = computeFsrsNextStates(
          currentMemoryState: FsrsMemoryState(
            stability: 10,
            difficulty: 6,
          ),
          daysElapsed: 12,
          desiredRetention: 0.9,
          params: params,
        );

        expect(
          computed.again.review.memoryState!.stability,
          direct.again.memoryState.stability,
        );
        expect(
          computed.hard.review.memoryState!.difficulty,
          direct.hard.memoryState.difficulty,
        );
        expect(
          computed.good.review.memoryState!.stability,
          direct.good.memoryState.stability,
        );
        expect(
          computed.easy.review.memoryState!.difficulty,
          direct.easy.memoryState.difficulty,
        );
        expect(
          computed.good.review.scheduledDays,
          direct.good.interval.round(),
        );
        expect(
          ReviewCardState(scheduledDays: 10)
              .nextStates(const ReviewSchedulingContext())
              .good
              .review
              .memoryState,
          isNull,
        );
      },
    );

    test('uses pinned Core fallback for a truncated review history', () {
      final inferred = _compute([
        _entry(
          kind: RevlogReviewKind.review,
          daysAgo: 99,
          interval: 100,
          easeFactor: 2500,
        ),
      ])!;
      expect(inferred.stability, closeTo(100, 0.0001));
      expect(inferred.difficulty, closeTo(5.003576, 0.0001));
      final state = _compute([
        _entry(
          kind: RevlogReviewKind.review,
          daysAgo: 99,
          interval: 100,
          easeFactor: 2500,
        ),
        _entry(kind: RevlogReviewKind.review, daysAgo: 0),
      ])!;

      // Core's source test rounds these state values to whole numbers because
      // supported floating-point backends can differ slightly.
      expect(state.stability.round(), 249);
      expect(state.difficulty.round(), 5);
      expect(state.difficulty, closeTo(4.9938006, 0.0001));
    });

    test(
      'uses cutoff history and ignores cramming; reset can remove all history',
      () {
        final state = _compute([
          _entry(kind: RevlogReviewKind.learning, daysAgo: 10),
          _entry(
            kind: RevlogReviewKind.filtered,
            daysAgo: 1,
            rating: 0,
            interval: 0,
          ),
          _entry(
            kind: RevlogReviewKind.review,
            daysAgo: 0,
            interval: 100,
            easeFactor: 2500,
          ),
        ], cutoff: Int64((_nextDayAt.toInt() - 5 * 86400) * 1000));
        expect(state, isNotNull);
        expect(state!.stability.round(), 100);

        final afterReset = _compute([
          _entry(kind: RevlogReviewKind.review, daysAgo: 2),
          _entry(
            kind: RevlogReviewKind.manual,
            daysAgo: 1,
            rating: 0,
            easeFactor: 0,
          ),
        ]);
        expect(afterReset, isNull);
        expect(_compute(const []), isNull);
      },
    );

    test(
      'selects default and legacy decay and rejects invalid parameter lengths',
      () {
        expect(fsrsDecayFromParams(const []), closeTo(0.1542, 0.000001));
        expect(fsrsDecayFromParams(List<double>.filled(17, 0)), 0.5);
        expect(fsrsDecayFromParams(List<double>.filled(20, 0)), 0.5);
        final current = List<double>.filled(21, 0)..[20] = 0.31;
        expect(fsrsDecayFromParams(current), closeTo(0.31, 0.000001));

        for (final size in [16, 18, 20, 22]) {
          expect(
            () => _compute(const [], params: List<double>.filled(size, 0)),
            throwsA(isA<InvalidModelValue>()),
          );
        }

        const defaults = [
          0.212,
          1.2931,
          2.3065,
          8.2956,
          6.4133,
          0.8334,
          3.0194,
          0.001,
          1.8722,
          0.1666,
          0.796,
          1.4835,
          0.0614,
          0.2629,
          1.6483,
          0.6014,
          1.8729,
          0.5425,
          0.0912,
          0.0658,
          0.1542,
        ];
        final completeHistory = [
          _entry(kind: RevlogReviewKind.learning, daysAgo: 1),
          _entry(kind: RevlogReviewKind.review, daysAgo: 0),
        ];
        for (final size in [17, 19, 21]) {
          final legacyState = _compute(
            completeHistory,
            params: defaults.take(size).toList(),
          );
          expect(legacyState, isNotNull);
          expect(legacyState!.stability.isFinite, isTrue);
          expect(legacyState.difficulty.isFinite, isTrue);
        }
      },
    );
  });
}
