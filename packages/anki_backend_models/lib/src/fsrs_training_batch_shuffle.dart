// SPDX-License-Identifier: AGPL-3.0-or-later
import 'seeded_rng.dart';

/// Stateful seeded permutations of FSRS training batch indices.
///
/// This adapts FSRS 5.2.0 `ShuffleDataLoader::iter()` with rand 0.9.4's
/// `SliceRandom::shuffle()` and `IncreasingUniform`. The seed and word stream
/// are pinned to rand 0.9.4, rand_core 0.9.3, and rand_chacha 0.9.0; changing
/// any of those versions may change returned permutations.
class FsrsTrainingBatchShuffle {
  FsrsTrainingBatchShuffle(BigInt seed) : _rng = SeededStdRng(seed);

  final SeededStdRng _rng;

  /// Returns an immutable permutation of `0..batchCount`.
  ///
  /// The count must fit the optimized u32 index domain used by rand 0.9.4's
  /// `IncreasingUniform` slice shuffle. Counts zero and one return identity
  /// permutations without consuming random words. Each call starts with a
  /// fresh index vector while keeping this object's seeded RNG stream alive.
  List<int> nextPermutation(int batchCount) {
    if (batchCount < 0 || batchCount >= _u32Max) {
      throw ArgumentError.value(
        batchCount,
        'batchCount',
        'must be in 0..${_u32Max - 1}',
      );
    }

    final indices = List<int>.generate(
      batchCount,
      (index) => index,
      growable: false,
    );
    if (batchCount > 1) {
      final chooser = _IncreasingUniform(_rng, 0);
      for (var index = 0; index < indices.length; index++) {
        final selected = chooser.nextIndex();
        final previous = indices[index];
        indices[index] = indices[selected];
        indices[selected] = previous;
      }
    }
    return List<int>.unmodifiable(indices);
  }
}

const _u32Max = 0xffffffff;

/// Rand 0.9.4's chunked chooser for slice shuffling.
class _IncreasingUniform {
  _IncreasingUniform(this._rng, int n)
      : _n = n,
        _chunkRemaining = n == 0 ? 1 : 0;

  final SeededStdRng _rng;
  int _n;
  int _chunk = 0;
  int _chunkRemaining;

  int nextIndex() {
    final nextN = _n + 1;
    int nextChunkRemaining;
    if (_chunkRemaining > 0) {
      nextChunkRemaining = _chunkRemaining - 1;
    } else {
      final (bound, remaining) = increasingUniformBoundU32(nextN);
      _chunk = rand094RandomRangeU32(bound, _rng.nextWord);
      nextChunkRemaining = remaining - 1;
    }

    final int result;
    if (nextChunkRemaining == 0) {
      result = _chunk;
    } else {
      result = _chunk % nextN;
      _chunk ~/= nextN;
    }

    _chunkRemaining = nextChunkRemaining;
    _n = nextN;
    return result;
  }
}

/// Returns the largest factorial chunk and its factor count for rand 0.9.4.
///
/// Kept package-internal so the overflow boundary can be regression-tested
/// without allocating a near-u32-sized batch.
(int, int) increasingUniformBoundU32(int min) {
  if (min < 1 || min >= _u32Max) {
    throw ArgumentError.value(min, 'min', 'must be in 1..${_u32Max - 1}');
  }
  var product = min;
  var current = min + 1;
  while (product <= _u32Max ~/ current) {
    product *= current;
    current++;
  }
  return (product, current - min);
}
