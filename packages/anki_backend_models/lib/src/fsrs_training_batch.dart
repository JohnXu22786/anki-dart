// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'fsrs_training_items.dart';

/// A tensor-compatible batch of FSRS training examples.
///
/// History matrices are sequence-major: each row is one history position and
/// each column corresponds to an input item. The returned lists, including
/// each history row, are immutable snapshots.
class FsrsTrainingBatch {
  FsrsTrainingBatch({
    required List<List<double>> timeHistories,
    required List<List<double>> ratingHistories,
    required List<double> deltaTs,
    required List<int> labels,
    required List<double> weights,
  })  : timeHistories = List.unmodifiable(
          timeHistories.map(List<double>.unmodifiable),
        ),
        ratingHistories = List.unmodifiable(
          ratingHistories.map(List<double>.unmodifiable),
        ),
        deltaTs = List.unmodifiable(deltaTs),
        labels = List.unmodifiable(labels),
        weights = List.unmodifiable(weights);

  /// Padded review intervals, indexed by history position then batch item.
  final List<List<double>> timeHistories;

  /// Padded prior ratings, indexed by history position then batch item.
  final List<List<double>> ratingHistories;

  /// Current review intervals in caller item order.
  final List<double> deltaTs;

  /// Current-rating targets: Again is zero and every other rating is one.
  final List<int> labels;

  /// Optimizer weights in caller item order.
  final List<double> weights;
}

/// Packs caller-ordered [items] into the deterministic FSRS 5.2.0 batch
/// values, without sorting or mutating the input.
///
/// Each item's current review is excluded from its history. Shorter histories
/// are padded with trailing zeroes to the longest history in the batch. Values
/// corresponding to Rust `f32` fields are rounded to Float32 precision.
/// Empty batches and empty item histories are rejected because the source
/// batcher panics on those inputs.
FsrsTrainingBatch packFsrsTrainingBatch(
  List<WeightedFsrsTrainingItem> items,
) {
  if (items.isEmpty) {
    throw ArgumentError.value(items, 'items', 'batch must not be empty');
  }

  var padSize = 0;
  for (var index = 0; index < items.length; index++) {
    final reviewCount = items[index].item.reviews.length;
    if (reviewCount == 0) {
      throw ArgumentError.value(
        index,
        'items',
        'each FSRS training item must contain at least one review',
      );
    }
    if (reviewCount - 1 > padSize) padSize = reviewCount - 1;
  }

  final currentDeltas = <double>[];
  final labels = <int>[];
  final weights = <double>[];
  for (final weightedItem in items) {
    final reviews = weightedItem.item.reviews;
    currentDeltas.add(_fsrsFloat32(reviews.last.deltaT.toDouble()));
    labels.add(reviews.last.rating == 1 ? 0 : 1);
    weights.add(_fsrsFloat32(weightedItem.weight));
  }

  final timeHistories = <List<double>>[];
  final ratingHistories = <List<double>>[];
  for (var historyIndex = 0; historyIndex < padSize; historyIndex++) {
    final timeRow = <double>[];
    final ratingRow = <double>[];
    for (final weightedItem in items) {
      final history = weightedItem.item.reviews;
      if (historyIndex < history.length - 1) {
        final review = history[historyIndex];
        timeRow.add(_fsrsFloat32(review.deltaT.toDouble()));
        ratingRow.add(_fsrsFloat32(review.rating.toDouble()));
      } else {
        timeRow.add(0);
        ratingRow.add(0);
      }
    }
    timeHistories.add(timeRow);
    ratingHistories.add(ratingRow);
  }

  return FsrsTrainingBatch(
    timeHistories: timeHistories,
    ratingHistories: ratingHistories,
    deltaTs: currentDeltas,
    labels: labels,
    weights: weights,
  );
}

/// Returns [batches] in the order specified by a complete permutation of
/// their indexes.
///
/// The returned list is immutable. Batch objects are reused, and neither
/// input list nor its values are modified.
List<FsrsTrainingBatch> orderFsrsTrainingBatchesByIndices({
  required List<FsrsTrainingBatch> batches,
  required List<int> indices,
}) {
  if (indices.length != batches.length) {
    throw ArgumentError.value(
      indices,
      'indices',
      'must contain one index for each batch',
    );
  }

  final seen = List<bool>.filled(batches.length, false);
  final ordered = <FsrsTrainingBatch>[];
  for (final index in indices) {
    if (index < 0 || index >= batches.length) {
      throw ArgumentError.value(
        index,
        'indices',
        'batch index must be between 0 and ${batches.length - 1}',
      );
    }
    if (seen[index]) {
      throw ArgumentError.value(index, 'indices', 'duplicate batch index');
    }
    seen[index] = true;
    ordered.add(batches[index]);
  }

  return List.unmodifiable(ordered);
}

double _fsrsFloat32(double value) {
  final storage = Float32List(1);
  storage[0] = value;
  return storage[0];
}
