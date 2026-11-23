// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'interval_load_weight.dart';
import 'seeded_rng.dart';

/// Selects an interval using Core's pinned seeded weighted-selection behavior.
///
/// The f32 weight accumulation and sampling reproduce rand 0.9.4's
/// `WeightedIndex<f32>` with rand_chacha 0.9.0 `StdRng` and rand_core 0.9.3
/// `seed_from_u64`. StdRng is version-sensitive; this behavior is pinned to
/// those crate versions. Returns null if the seed is absent or the weights
/// would be rejected by `WeightedIndex::new()`.
int? selectWeightedInterval(
  Iterable<IntervalLoadCandidate> candidates,
  BigInt? fuzzSeed,
) {
  if (fuzzSeed == null) return null;
  if (fuzzSeed < BigInt.zero ||
      fuzzSeed > BigInt.parse('ffffffffffffffff', radix: 16)) {
    throw ArgumentError.value(
      fuzzSeed,
      'fuzzSeed',
      'must fit in an unsigned 64-bit integer',
    );
  }

  final intervals = <int>[];
  final cumulativeWeights = <double>[];
  var totalWeight = 0.0;
  for (final candidate in candidates) {
    final weight = _f32(calculateIntervalLoadWeight(candidate));
    if (!weight.isFinite || weight < 0) return null;
    if (intervals.isEmpty) {
      totalWeight = weight;
    } else {
      cumulativeWeights.add(totalWeight);
      totalWeight = _f32(totalWeight + weight);
      if (!totalWeight.isFinite) return null;
    }
    intervals.add(candidate.targetInterval);
  }
  if (intervals.isEmpty || totalWeight == 0) return null;

  final sample = _sampleFloatBelow(fuzzSeed, totalWeight);
  var low = 0;
  var high = cumulativeWeights.length;
  while (low < high) {
    final mid = low + ((high - low) >> 1);
    if (cumulativeWeights[mid] <= sample) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  return intervals[low];
}

double _sampleFloatBelow(BigInt seed, double high) {
  final word = seededStdRngWords(seed).single;
  // rand 0.9.4's UniformFloat<f32> discards the low nine bits, constructs a
  // [1, 2) f32, subtracts one, then scales by `high` with f32 rounding.
  final fraction = _f32((word >> 9) / 8388608.0);
  return _f32(fraction * high);
}

double _f32(double value) => (Float32List(1)..[0] = value)[0];
