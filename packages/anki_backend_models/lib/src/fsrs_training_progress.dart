// SPDX-License-Identifier: AGPL-3.0-or-later

/// Progress for one split in FSRS 5.2.0 training.
///
/// This is a value projection of Core's `ProgressState` arithmetic. Native
/// Core `usize` counts have target-width overflow behavior outside the
/// realistic training-count domain; this Dart projection uses Dart integer
/// arithmetic.
class FsrsTrainingSplitProgress {
  FsrsTrainingSplitProgress({
    required Object? epoch,
    required Object? epochTotal,
    required Object? itemsProcessed,
    required Object? itemsTotal,
  })  : epoch = _nonnegativeCount(epoch, 'epoch'),
        epochTotal = _nonnegativeCount(epochTotal, 'epochTotal'),
        itemsProcessed = _nonnegativeCount(itemsProcessed, 'itemsProcessed'),
        itemsTotal = _nonnegativeCount(itemsTotal, 'itemsTotal');

  final int epoch;
  final int epochTotal;
  final int itemsProcessed;
  final int itemsTotal;

  /// Completed work across prior epochs plus work processed in this epoch.
  int get current => (epoch > 1 ? epoch - 1 : 0) * itemsTotal + itemsProcessed;

  /// Total item work across all epochs.
  int get total => epochTotal * itemsTotal;
}

/// Immutable aggregate progress across FSRS training splits.
class FsrsTrainingProgress {
  FsrsTrainingProgress({
    required Iterable<FsrsTrainingSplitProgress> splits,
    required this.finished,
  }) : splits = List.unmodifiable(splits);

  /// Per-split progress in the order supplied by the caller.
  final List<FsrsTrainingSplitProgress> splits;

  /// Whether the caller's training process has finished.
  final bool finished;

  /// Sum of current progress across all splits.
  int get current => splits.fold(0, (sum, split) => sum + split.current);

  /// Sum of total progress across all splits.
  int get total => splits.fold(0, (sum, split) => sum + split.total);
}

int _nonnegativeCount(Object? value, String name) {
  if (value is! int || value < 0) {
    throw ArgumentError.value(value, name, 'must be a nonnegative integer');
  }
  return value;
}
