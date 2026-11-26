// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'seeded_rng.dart';

/// Applies Anki Core's seeded Learning/Relearning interval fuzz to seconds.
///
/// This reproduces `learning_ivl_with_fuzz()` from the pinned rand 0.9.4,
/// rand_chacha 0.9.0, and rand_core 0.9.3 behavior. StdRng and its integer
/// sampling are version-sensitive. A missing seed or empty fuzz range returns
/// [scheduledSecs] unchanged.
int fuzzLearningIntervalSecs(int scheduledSecs, BigInt? fuzzSeed) {
  if (scheduledSecs < 0 || scheduledSecs > 0xffffffff) {
    throw ArgumentError.value(
        scheduledSecs, 'scheduledSecs', 'expected uint32');
  }
  if (fuzzSeed != null &&
      (fuzzSeed < BigInt.zero ||
          fuzzSeed > BigInt.parse('ffffffffffffffff', radix: 16))) {
    throw ArgumentError.value(
      fuzzSeed,
      'fuzzSeed',
      'must fit in an unsigned 64-bit integer',
    );
  }
  final fuzzRange = _learningFuzzRange(scheduledSecs);
  if (fuzzSeed == null || fuzzRange == 0) return scheduledSecs;
  final upperExclusive = scheduledSecs + fuzzRange;
  if (upperExclusive > 0xffffffff) {
    throw ArgumentError.value(
        scheduledSecs, 'scheduledSecs', 'fuzz range overflows uint32');
  }

  // rand 0.9.4's default `u32::sample_single_inclusive()` implementation
  // multiplies a random u32 by the range, then consumes another word on its
  // small bias-correction path. This is the default build without rand's
  // optional `unbiased` feature.
  final words = seededStdRngWords(fuzzSeed);
  final firstProduct = BigInt.from(words.single) * BigInt.from(fuzzRange);
  var result = (firstProduct >> 32).toInt();
  final low = (firstProduct & BigInt.from(0xffffffff)).toInt();
  if (low > 0x100000000 - fuzzRange) {
    final correctionWord = seededStdRngWords(fuzzSeed, count: 2).last;
    final correctionHigh =
        (BigInt.from(correctionWord) * BigInt.from(fuzzRange) >> 32).toInt();
    if (low + correctionHigh > 0xffffffff) result++;
  }
  return scheduledSecs + result;
}

int _learningFuzzRange(int scheduledSecs) {
  final secondsAsF32 = (Float32List(1)..[0] = scheduledSecs.toDouble())[0];
  return (secondsAsF32 * 0.25).floor().clamp(0, 300);
}
