// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('fuzzLearningIntervalSecs', () {
    test('returns the scheduled interval when fuzz is disabled', () {
      expect(fuzzLearningIntervalSecs(120, null), 120);
      expect(
        () => fuzzLearningIntervalSecs(1, BigInt.one << 64),
        throwsArgumentError,
      );
    });

    test('returns the scheduled interval for zero-width short ranges', () {
      for (final seconds in [0, 1, 2, 3]) {
        expect(fuzzLearningIntervalSecs(seconds, BigInt.one), seconds);
      }
    });

    test('uses the floored 25 percent range and caps it at 300 seconds', () {
      expect(fuzzLearningIntervalSecs(403, null), 403);
      // A 403 second interval has a 100 second fuzz range.
      expect(fuzzLearningIntervalSecs(403, BigInt.one), 485);
      // The 25 percent range is capped at 300 seconds for long intervals.
      expect(fuzzLearningIntervalSecs(1200, BigInt.zero), 1440);
    });

    test('matches pinned Core fixtures for seeded u32 sampling', () {
      // Fixtures were generated from Anki Core e64c6b1a's
      // learning_ivl_with_fuzz() using rand 0.9.4, rand_chacha 0.9.0,
      // rand_core 0.9.3, and StdRng::seed_from_u64().
      expect(fuzzLearningIntervalSecs(400, BigInt.zero), 480);
      expect(
          fuzzLearningIntervalSecs(
              1200, BigInt.parse('ffffffffffffffff', radix: 16)),
          1254);
      // The first multiply's low word triggers rand's correction path; the
      // second word overflows its correction sum and increments the result.
      expect(fuzzLearningIntervalSecs(1200, BigInt.from(58205158)), 1473);
    });
  });
}
