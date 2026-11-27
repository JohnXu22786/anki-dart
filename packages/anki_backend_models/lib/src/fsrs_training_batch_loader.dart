// SPDX-License-Identifier: AGPL-3.0-or-later
import 'fsrs_training_batch.dart';
import 'fsrs_training_batch_iterator.dart';
import 'fsrs_training_batch_shuffle.dart';

/// Creates fresh traversals over an immutable snapshot of FSRS training batches.
///
/// Each call to [iterator] consumes the next permutation from this loader's
/// seeded shuffle stream. The batch values are reused without modification;
/// this helper covers batch traversal only, not training epochs or optimization.
class FsrsTrainingBatchLoader {
  FsrsTrainingBatchLoader(List<FsrsTrainingBatch> batches, BigInt seed)
      : _batches = List.unmodifiable(batches),
        _shuffle = FsrsTrainingBatchShuffle(seed);

  final List<FsrsTrainingBatch> _batches;
  final FsrsTrainingBatchShuffle _shuffle;

  /// Returns a new traversal using the next permutation in the seeded stream.
  FsrsTrainingBatchIterator iterator() => FsrsTrainingBatchIterator(
        batches: _batches,
        indices: _shuffle.nextPermutation(_batches.length),
      );
}
