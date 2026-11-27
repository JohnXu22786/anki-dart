// SPDX-License-Identifier: AGPL-3.0-or-later
import 'fsrs_training_batch.dart';

/// Immutable progress snapshot for one FSRS training batch traversal.
class FsrsTrainingBatchProgress {
  const FsrsTrainingBatchProgress({
    required this.itemsProcessed,
    required this.itemsTotal,
  });

  /// Number of batches returned by the iterator so far.
  final int itemsProcessed;

  /// Number of batches in the ordered traversal.
  final int itemsTotal;

  /// Whether every batch has been returned.
  bool get isComplete => itemsProcessed == itemsTotal;
}

/// Traverses existing FSRS training batches in a caller-supplied permutation.
///
/// The permutation is validated and copied into an immutable ordered snapshot
/// when the iterator is created. Batch objects are reused without modification.
class FsrsTrainingBatchIterator {
  FsrsTrainingBatchIterator({
    required List<FsrsTrainingBatch> batches,
    required List<int> indices,
  }) : _batches = orderFsrsTrainingBatchesByIndices(
          batches: batches,
          indices: indices,
        );

  final List<FsrsTrainingBatch> _batches;
  var _currentIndex = 0;

  /// Progress at the time this snapshot is requested.
  FsrsTrainingBatchProgress get progress => FsrsTrainingBatchProgress(
        itemsProcessed: _currentIndex,
        itemsTotal: _batches.length,
      );

  /// Returns the next batch, or `null` after all batches have been returned.
  FsrsTrainingBatch? nextBatch() {
    if (_currentIndex == _batches.length) return null;
    return _batches[_currentIndex++];
  }
}
