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
