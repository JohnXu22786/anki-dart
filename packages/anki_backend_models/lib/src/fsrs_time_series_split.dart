// SPDX-License-Identifier: AGPL-3.0-or-later
import 'fsrs_training_items.dart';

/// One expanding-window FSRS training and validation split.
class FsrsTimeSeriesSplit {
  FsrsTimeSeriesSplit({
    required Iterable<FsrsTrainingItem> trainingItems,
    required Iterable<FsrsTrainingItem> validationItems,
  })  : trainingItems = List.unmodifiable(trainingItems),
        validationItems = List.unmodifiable(validationItems);

  /// The prefix of items used to train this fold.
  final List<FsrsTrainingItem> trainingItems;

  /// The next segment of items used to validate this fold.
  final List<FsrsTrainingItem> validationItems;
}

/// Splits timestamp-ordered FSRS training items into expanding-window folds.
///
/// [items] must already be sorted by review timestamp, as in FSRS 5.2.0. This
/// helper preserves that order and the original item instances; it does not
/// sort or modify the input. Returns no folds for empty input, a nonpositive
/// [nSplits], or when the equal segment size is zero.
List<FsrsTimeSeriesSplit> splitFsrsTrainingItemsByTimeSeries(
  List<FsrsTrainingItem> items, {
  required int nSplits,
}) {
  if (items.isEmpty || nSplits <= 0) {
    return const [];
  }

  final segmentSize = items.length ~/ (nSplits + 1);
  if (segmentSize == 0) {
    return const [];
  }

  final folds = <FsrsTimeSeriesSplit>[];
  for (var index = 0; index < nSplits; index++) {
    final testStart = (index + 1) * segmentSize;
    final testEnd =
        index == nSplits - 1 ? items.length : (index + 2) * segmentSize;
    folds.add(
      FsrsTimeSeriesSplit(
        trainingItems: items.sublist(0, testStart),
        validationItems: items.sublist(testStart, testEnd),
      ),
    );
  }
  return List.unmodifiable(folds);
}
