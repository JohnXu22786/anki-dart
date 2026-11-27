// SPDX-License-Identifier: AGPL-3.0-or-later

/// Calculates the training iteration count used by FSRS 5.2.0.
///
/// This ports `train()`'s operation order:
/// `(total_size / batch_size + 1) * num_epochs`. The extra batch slot is
/// included even for empty datasets and exact batch multiples. Core's `usize`
/// multiplication follows target-width overflow behavior outside realistic
/// training-count ranges; this Dart projection uses Dart integer arithmetic.
///
/// [itemsTotal] and [epochTotal] must be nonnegative. [batchSize] must be
/// positive.
int calculateFsrsTrainingIterationCount({
  required int itemsTotal,
  required int batchSize,
  required int epochTotal,
}) {
  if (itemsTotal < 0) {
    throw ArgumentError.value(itemsTotal, 'itemsTotal', 'must be nonnegative');
  }
  if (batchSize <= 0) {
    throw ArgumentError.value(batchSize, 'batchSize', 'must be positive');
  }
  if (epochTotal < 0) {
    throw ArgumentError.value(epochTotal, 'epochTotal', 'must be nonnegative');
  }

  return (itemsTotal ~/ batchSize + 1) * epochTotal;
}
