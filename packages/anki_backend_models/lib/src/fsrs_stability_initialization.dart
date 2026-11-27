// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

import 'fsrs_training_items.dart';

/// Initial FSRS stability values in rating order 1 through 4, and the number
/// of retained initialization examples for each first rating.
class FsrsStabilityParameters {
  FsrsStabilityParameters({
    required List<double> stabilities,
    required Map<int, int> ratingCounts,
  })  : stabilities = List.unmodifiable(stabilities),
        ratingCounts = Map.unmodifiable(ratingCounts);

  /// Four initial stabilities, indexed by rating minus one.
  final List<double> stabilities;

  /// Retained initialization item counts keyed by first rating.
  final Map<int, int> ratingCounts;
}

final _defaultStabilities = List<double>.unmodifiable(
  Float32List.fromList([0.212, 1.2931, 2.3065, 8.2956]),
);
const _stabilityMin = 0.0010000000474974513;
const _stabilityMax = 100.0;
const _w1 = 0.4099999964237213;
const _w2 = 0.5400000214576721;

/// Derives FSRS 5.2.0 initial stability values from training [items].
///
/// Only items with exactly one positive-`deltaT` review are used. They are
/// grouped by their first rating and the first positive interval. [averageRecall]
/// supplies the corpus-wide prior used by Laplace smoothing and is rounded to
/// Core's Float32 representation before the search. Histories must be nonempty,
/// use ratings 1–4, and contain at least one positive interval. The returned
/// stabilities and rating counts are immutable snapshots.
///
/// Throws [ArgumentError] for malformed items and [StateError] when no rating
/// has initialization examples.
FsrsStabilityParameters initializeFsrsStabilityParameters(
  List<FsrsTrainingItem> items, {
  required double averageRecall,
}) {
  if (!averageRecall.isFinite || averageRecall < 0.0 || averageRecall > 1.0) {
    throw ArgumentError.value(
      averageRecall,
      'averageRecall',
      'average recall must be finite and between 0 and 1',
    );
  }
  final f32 = _float32Rounder();
  final averageRecallF32 = f32(averageRecall);
  final grouped = <int, Map<int, List<int>>>{};

  for (var itemIndex = 0; itemIndex < items.length; itemIndex++) {
    final reviews = items[itemIndex].reviews;
    if (reviews.isEmpty) {
      throw ArgumentError.value(
        itemIndex,
        'items',
        'each FSRS training item must contain at least one review',
      );
    }
    if (reviews.first.deltaT != 0) {
      throw ArgumentError.value(
        itemIndex,
        'items',
        'the first review deltaT must be zero',
      );
    }
    if (reviews.any((review) => review.rating < 1 || review.rating > 4)) {
      throw ArgumentError.value(
        itemIndex,
        'items',
        'review ratings must be between 1 and 4',
      );
    }
    if (reviews.any((review) => review.deltaT < 0)) {
      throw ArgumentError.value(
        itemIndex,
        'items',
        'review deltaT values must not be negative',
      );
    }
    final positiveReviews = reviews.where((review) => review.deltaT > 0);
    if (positiveReviews.isEmpty) {
      throw ArgumentError.value(
        itemIndex,
        'items',
        'each FSRS training item must contain a positive deltaT review',
      );
    }
    if (reviews.last.deltaT <= 0) {
      throw ArgumentError.value(
        itemIndex,
        'items',
        'each FSRS training item must end with a long-term review',
      );
    }
    if (positiveReviews.length != 1) continue;

    final firstPositive = positiveReviews.first;
    grouped
        .putIfAbsent(reviews.first.rating, () => <int, List<int>>{})
        .putIfAbsent(firstPositive.deltaT, () => <int>[])
        .add(firstPositive.rating > 1 ? 1 : 0);
  }

  final ratingCounts = <int, int>{};
  final stabilityByRating = <int, double>{};
  for (final ratingEntry in grouped.entries) {
    final summaries = ratingEntry.value.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final totalCount = summaries.fold<int>(
      0,
      (sum, group) => sum + group.value.length,
    );
    ratingCounts[ratingEntry.key] = totalCount;
    stabilityByRating[ratingEntry.key] = _searchStability(
      summaries,
      averageRecallF32,
      _defaultStabilities[ratingEntry.key - 1],
    );
  }

  final stabilities = _smoothAndFill(stabilityByRating, ratingCounts, f32);
  return FsrsStabilityParameters(
    stabilities: stabilities,
    ratingCounts: ratingCounts,
  );
}

double _searchStability(
  List<MapEntry<int, List<int>>> summaries,
  double averageRecallF32,
  double defaultStability,
) {
  final deltaT = <double>[];
  final recall = <double>[];
  final counts = <double>[];
  for (final summary in summaries) {
    final count = summary.value.length;
    final passCount = summary.value.fold<int>(0, (sum, value) => sum + value);
    deltaT.add(summary.key.toDouble());
    recall.add(passCount / count);
    counts.add(count.toDouble());
  }

  // Rust converts its f32 prior to f64 before applying this formula.
  final smoothedRecall = <double>[
    for (var index = 0; index < recall.length; index++)
      (recall[index] * counts[index] + averageRecallF32) /
          (counts[index] + 1.0),
  ];
  final decay = -_float32(_fsrsDecay);
  final factor = math.pow(0.9, 1.0 / decay) - 1.0;
  double loss(double stability) {
    var sum = 0.0;
    for (var index = 0; index < deltaT.length; index++) {
      final predicted = math
          .pow(
            deltaT[index] / stability * factor + 1.0,
            decay,
          )
          .toDouble();
      final observed = smoothedRecall[index];
      final logLoss = -(observed * math.log(predicted) +
              (1.0 - observed) * math.log(1.0 - predicted)) *
          counts[index];
      sum += logLoss;
    }
    final l1 = (stability - defaultStability).abs() / 16.0;
    return sum + l1;
  }

  const epsilon = 2.220446049250313e-16;
  var low = _stabilityMin;
  var high = _stabilityMax;
  var optimal = defaultStability;
  var iteration = 0;
  while (high - low > epsilon && iteration < 1000) {
    iteration++;
    final mid1 = low + (high - low) / 3.0;
    final mid2 = high - (high - low) / 3.0;
    if (loss(mid1) < loss(mid2)) {
      high = mid2;
    } else {
      low = mid1;
    }
    optimal = (high + low) / 2.0;
  }
  return _float32(optimal);
}

List<double> _smoothAndFill(
  Map<int, double> stability,
  Map<int, int> counts,
  double Function(double) f32,
) {
  double add(double a, double b) => f32(a + b);
  double sub(double a, double b) => f32(a - b);
  double mul(double a, double b) => f32(a * b);
  double div(double a, double b) => f32(a / b);
  double pow(double value, double exponent) => _pow32(value, exponent, f32);

  for (final pair in const [(1, 2), (2, 3), (3, 4), (1, 3), (2, 4), (1, 4)]) {
    final smallValue = stability[pair.$1];
    final bigValue = stability[pair.$2];
    if (smallValue != null && bigValue != null && smallValue > bigValue) {
      if (counts[pair.$1]! > counts[pair.$2]!) {
        stability[pair.$2] = smallValue;
      } else {
        stability[pair.$1] = bigValue;
      }
    }
  }

  final values = List<double?>.filled(5, null);
  for (final entry in stability.entries) {
    values[entry.key] = entry.value;
  }
  final observedCount = stability.length;
  if (observedCount == 0) {
    throw StateError('not enough FSRS initialization data for any rating');
  }
  if (observedCount == 1) {
    final rating = stability.keys.first;
    final factor =
        div(stability[rating]!, f32(_defaultStabilities[rating - 1]));
    final filled = [
      for (final defaultValue in _defaultStabilities)
        mul(f32(defaultValue), factor),
    ]..sort();
    return _clampValues(filled, f32);
  }

  if (observedCount == 2) {
    if (values[1] == null && values[2] == null) {
      final r3 = values[3]!;
      final r4 = values[4]!;
      values[2] = mul(
        pow(r3, div(1.0, sub(1.0, _w2))),
        pow(r4, sub(1.0, div(1.0, sub(1.0, _w2)))),
      );
      values[1] = _geometric(
          rating: values[2]!, other: r3, exponent: div(1.0, _w1), f32: f32);
    } else if (values[1] == null &&
        values[2] != null &&
        values[3] == null &&
        values[4] != null) {
      final r2 = values[2]!;
      final r4 = values[4]!;
      values[3] = mul(pow(r2, sub(1.0, _w2)), pow(r4, _w2));
      values[1] = _geometric(
          rating: r2, other: values[3]!, exponent: div(1.0, _w1), f32: f32);
    } else if (values[1] == null &&
        values[2] != null &&
        values[3] != null &&
        values[4] == null) {
      values[4] = mul(
        pow(values[2]!, sub(1.0, div(1.0, _w2))),
        pow(values[3]!, div(1.0, _w2)),
      );
      values[1] = _geometric(
          rating: values[2]!,
          other: values[3]!,
          exponent: div(1.0, _w1),
          f32: f32);
    } else if (values[1] != null &&
        values[2] == null &&
        values[3] == null &&
        values[4] != null) {
      final r1 = values[1]!;
      final r4 = values[4]!;
      final denominator = f32(_w1 * -_w2 + add(_w1, _w2));
      values[2] = mul(
        pow(r1, div(_w1, denominator)),
        pow(r4, sub(1.0, div(_w1, denominator))),
      );
      values[3] = mul(
        pow(r1, sub(1.0, div(_w2, denominator))),
        pow(r4, div(_w2, denominator)),
      );
    } else if (values[1] != null &&
        values[2] == null &&
        values[3] != null &&
        values[4] == null) {
      final r1 = values[1]!;
      final r3 = values[3]!;
      values[2] = mul(pow(r1, _w1), pow(r3, sub(1.0, _w1)));
      values[4] = mul(
        pow(values[2]!, sub(1.0, div(1.0, _w2))),
        pow(r3, div(1.0, _w2)),
      );
    } else if (values[1] != null &&
        values[2] != null &&
        values[3] == null &&
        values[4] == null) {
      final r1 = values[1]!;
      final r2 = values[2]!;
      values[3] = mul(
        pow(r1, sub(1.0, div(1.0, sub(1.0, _w1)))),
        pow(r2, div(1.0, sub(1.0, _w1))),
      );
      values[4] = mul(
        pow(r2, sub(1.0, div(1.0, _w2))),
        pow(values[3]!, div(1.0, _w2)),
      );
    }
  } else if (observedCount == 3) {
    if (values[1] == null && values[2] != null && values[3] != null) {
      values[1] = mul(
        pow(values[2]!, div(1.0, _w1)),
        pow(values[3]!, sub(1.0, div(1.0, _w1))),
      );
    } else if (values[1] != null && values[2] == null && values[3] != null) {
      values[2] = mul(pow(values[1]!, _w1), pow(values[3]!, sub(1.0, _w1)));
    } else if (values[2] != null && values[3] == null && values[4] != null) {
      values[3] = mul(pow(values[2]!, sub(1.0, _w2)), pow(values[4]!, _w2));
    } else if (values[2] != null && values[3] != null && values[4] == null) {
      values[4] = mul(
        pow(values[2]!, sub(1.0, div(1.0, _w2))),
        pow(values[3]!, div(1.0, _w2)),
      );
    }
  }

  return _clampValues(values.skip(1).whereType<double>().toList(), f32);
}

List<double> _clampValues(List<double> values, double Function(double) f32) => [
      for (final value in values)
        f32(value.clamp(_stabilityMin, _stabilityMax)),
    ];

double _geometric({
  required double rating,
  required double other,
  required double exponent,
  required double Function(double) f32,
}) =>
    f32(_pow32(rating, exponent, f32) *
        _pow32(other, f32(1.0 - exponent), f32));

double _pow32(double value, double exponent, double Function(double) f32) =>
    f32(math.pow(value, exponent).toDouble());

const _fsrsDecay = 0.1541999876499176;

double _float32(double value) => _float32Rounder()(value);

double Function(double) _float32Rounder() {
  final storage = Float32List(1);
  return (value) {
    storage[0] = value;
    return storage[0];
  };
}
