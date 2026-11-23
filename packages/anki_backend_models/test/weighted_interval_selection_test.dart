// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_models/src/seeded_rng.dart';
import 'package:test/test.dart';

void main() {
  group('seeded StdRng words', () {
    test('matches pinned rand seed expansion and ChaCha12 output', () {
      // Derived from rand_core 0.9.3 seed_from_u64 PCG32 expansion followed by
      // rand_chacha 0.9.0 ChaCha12. The separate reference script's core was
      // cross-checked against rand_chacha 0.9.0's
      // `test_chacha_true_values_a` 20-round vector, then run for 12 rounds as
      // StdRng does.
      expect(seededStdRngWords(BigInt.zero, count: 4), [
        0xcd2c6f7f,
        0xbb2a3fb2,
        0x8e27697b,
        0xc6017c94,
      ]);
      expect(seededStdRngWords(BigInt.one, count: 4), [
        0xd3301861,
        0xf9681a64,
        0xcc0d694a,
        0xb0f4d125,
      ]);
      expect(
        seededStdRngWords(
          BigInt.parse('8000000000000000', radix: 16),
          count: 4,
        ),
        [0xc9d3d842, 0xac1f4e02, 0x61af0d12, 0x96114433],
      );
      expect(
        () => seededStdRngWords(BigInt.from(-1)),
        throwsArgumentError,
      );
      expect(
        () => seededStdRngWords(BigInt.one << 64),
        throwsArgumentError,
      );
    });
  });

  group('selectWeightedInterval', () {
    test('returns null without a seed and for empty input', () {
      expect(selectWeightedInterval([_candidate(10, 1)], null), isNull);
      expect(selectWeightedInterval(const [], BigInt.zero), isNull);
    });

    test('returns null when WeightedIndex rejects weights or total', () {
      expect(selectWeightedInterval([_candidate(10, 0)], BigInt.zero), isNull);
      expect(selectWeightedInterval([_candidate(10, -1)], BigInt.zero), isNull);
      expect(
        selectWeightedInterval([_candidate(10, double.nan)], BigInt.zero),
        isNull,
      );
      expect(
        selectWeightedInterval([
          _candidate(10, 3.0e38),
          _candidate(20, 3.0e38),
        ], BigInt.zero),
        isNull,
      );
    });

    test(
      'matches pinned weighted choices for seed fixtures in input order',
      () {
        const intervals = [10, 20, 30, 40];
        final candidates = intervals.map((interval) => _candidate(interval, 1));
        expect(selectWeightedInterval(candidates, BigInt.zero), 40);
        expect(selectWeightedInterval(candidates, BigInt.one), 40);
        expect(
          selectWeightedInterval(
            candidates,
            BigInt.parse('8000000000000000', radix: 16),
          ),
          40,
        );
        expect(
          selectWeightedInterval(
            candidates,
            BigInt.parse('ffffffffffffffff', radix: 16),
          ),
          10,
        );
        expect(selectWeightedInterval(candidates, BigInt.from(123456789)), 20);
      },
    );

    test(
      'returns a single candidate and gives zero-review candidates full weight',
      () {
        expect(selectWeightedInterval([_candidate(77, 1)], BigInt.zero), 77);
        // Core's reviewCount == 0 branch ignores the supplied modifiers.
        final noReview = IntervalLoadCandidate(
          targetInterval: 11,
          reviewCount: 0,
          siblingModifier: double.nan,
          easyDaysModifier: -100,
        );
        expect(
          selectWeightedInterval([noReview, _candidate(22, 1)], BigInt.zero),
          22,
        );
        expect(
          selectWeightedInterval([
            _candidate(90, 0),
            _candidate(33, 1),
            _candidate(33, 0),
            _candidate(44, 1),
          ], BigInt.parse('ffffffffffffffff', radix: 16)),
          33,
        );
      },
    );

    test('uses the first cumulative weight strictly greater than the sample',
        () {
      // For this seed, rand's f32 sample with total 1 is exactly this value.
      // The first candidate has that same f32 weight, so equality must advance
      // to the next interval, as WeightedIndex::sample's partition_point does.
      const sample = 0.1806238889694214;
      final firstWeight = _f32(sample);
      final secondWeight = _f32(1 - firstWeight);
      expect(firstWeight + secondWeight, 1);
      expect(
        selectWeightedInterval([
          _candidate(10, firstWeight),
          _candidate(20, secondWeight),
        ], BigInt.parse('ffffffffffffffff', radix: 16)),
        20,
      );
    });
  });
}

IntervalLoadCandidate _candidate(int interval, double weight) =>
    _candidateWithExactWeight(interval, weight);

IntervalLoadCandidate _candidateWithExactWeight(int interval, double weight) {
  final baseWeight = calculateIntervalLoadWeight(
    IntervalLoadCandidate(targetInterval: interval, reviewCount: 1),
  );
  return IntervalLoadCandidate(
    targetInterval: interval,
    reviewCount: 1,
    siblingModifier: _f32(weight / baseWeight),
  );
}

double _f32(double value) => (Float32List(1)..[0] = value)[0];
