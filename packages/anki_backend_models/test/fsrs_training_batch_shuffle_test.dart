// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart' as models;
import 'package:anki_backend_models/src/fsrs_training_batch_shuffle.dart'
    as shuffle;
import 'package:anki_backend_models/src/seeded_rng.dart' as rng;
import 'package:test/test.dart';

void main() {
  group('FsrsTrainingBatchShuffle', () {
    test('matches rand 0.9.4 seeded permutations at multiple counts', () {
      final expected = <int, List<int>>{
        0: [],
        1: [0],
        2: [1, 0],
        3: [1, 0, 2],
        5: [1, 0, 2, 3, 4],
        10: [1, 0, 7, 3, 6, 4, 5, 9, 8, 2],
      };
      for (final entry in expected.entries) {
        expect(
          models.FsrsTrainingBatchShuffle(BigInt.zero)
              .nextPermutation(entry.key),
          entry.value,
          reason: 'batch count ${entry.key}',
        );
      }
    });

    test('keeps one StdRng stream across calls and reproduces fresh streams',
        () {
      final loader = models.FsrsTrainingBatchShuffle(BigInt.zero);
      final actual = [
        loader.nextPermutation(5),
        loader.nextPermutation(5),
        loader.nextPermutation(10),
      ];
      expect(actual, [
        [1, 0, 2, 3, 4],
        [0, 1, 2, 4, 3],
        [9, 1, 4, 5, 6, 7, 3, 2, 8, 0],
      ]);
      final repeated = models.FsrsTrainingBatchShuffle(BigInt.zero);
      expect([
        repeated.nextPermutation(5),
        repeated.nextPermutation(5),
        repeated.nextPermutation(10),
      ], actual);
    });

    test('returns immutable snapshots that later calls do not change', () {
      final loader = models.FsrsTrainingBatchShuffle(BigInt.zero);
      final first = loader.nextPermutation(10);
      final snapshot = List<int>.of(first);
      loader.nextPermutation(20);
      expect(first, snapshot);
      expect(() => first[0] = -1, throwsUnsupportedError);
    });

    test('zero and one counts consume no words and validates domains', () {
      final afterIdentity = models.FsrsTrainingBatchShuffle(BigInt.zero)
        ..nextPermutation(0)
        ..nextPermutation(1);
      final fresh = models.FsrsTrainingBatchShuffle(BigInt.zero);
      expect(afterIdentity.nextPermutation(5), fresh.nextPermutation(5));
      expect(() => models.FsrsTrainingBatchShuffle(BigInt.from(-1)),
          throwsArgumentError);
      expect(() => models.FsrsTrainingBatchShuffle(BigInt.one << 64),
          throwsArgumentError);
      expect(() => fresh.nextPermutation(-1), throwsArgumentError);
      expect(() => fresh.nextPermutation(0xffffffff), throwsArgumentError);
    });

    test('matches the pinned Canon correction and consumes its extra word', () {
      final words = [0x55555555, 0xffffffff];
      var consumed = 0;
      final result = rng.rand094RandomRangeU32(3, () => words[consumed++]);
      expect(result, 1);
      expect(consumed, 2);
    });

    test('calculates large IncreasingUniform bounds without overflow', () {
      expect(shuffle.increasingUniformBoundU32(0xfffffffe), (0xfffffffe, 1));
    });

    test('carries the ChaCha block counter across the u32 rollover', () {
      final wraps =
          rng.SeededStdRng(BigInt.zero, blockLow: 0xffffffff).takeWords(17);
      final nextHighBlock =
          rng.SeededStdRng(BigInt.zero, blockHigh: 1).takeWords(1);
      expect(wraps.last, nextHighBlock.single);
    });
  });
}
