// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

/// Core's easy-day classification for one weekday's configured percentage.
enum EasyDay {
  minimum,
  reduced,
  normal;

  /// Classifies a percentage after narrowing it to Core's `f32` precision.
  static EasyDay fromPercentage(double percentage) {
    final value = _float32(percentage);
    if (value == 1.0) return EasyDay.normal;
    if (value == 0.0) return EasyDay.minimum;
    return EasyDay.reduced;
  }

  /// The nonzero weight applied to this day by Core's load balancer.
  double get loadModifier => switch (this) {
        EasyDay.normal => 1.0,
        EasyDay.reduced => 0.5,
        EasyDay.minimum => _float32(0.0001),
      };
}

/// Parses the seven configured weekday percentages into Core's typed values.
///
/// An empty configuration uses seven normal days. A nonempty configuration
/// must contain exactly seven percentages, matching Core's `expected 7 days`
/// invalid-input message.
List<EasyDay> parseEasyDaysPercentages(List<double> percentages) {
  if (percentages.isEmpty) {
    return List<EasyDay>.filled(7, EasyDay.normal, growable: false);
  }
  if (percentages.length != 7) {
    throw const FormatException('expected 7 days');
  }
  return List<EasyDay>.unmodifiable(
    percentages.map(EasyDay.fromPercentage),
  );
}

/// Computes Core's easy-day modifiers for caller-supplied weekday indices and
/// review counts. Inputs are intentionally explicit; this helper does not
/// access deck configuration, storage, or scheduler state.
///
/// Totals use the complete `reviewCounts`/`weekdays` inputs while output pairs
/// those inputs using zip semantics, matching Core. A reduced day is normalized
/// to minimum when twice its load exceeds the average load of other days.
List<double> calculateEasyDaysModifiers(
  List<EasyDay> easyDays,
  List<int> weekdays,
  List<int> reviewCounts,
) {
  if (easyDays.length != 7) {
    throw ArgumentError.value(easyDays.length, 'easyDays', 'expected 7 days');
  }

  final totalReviewCount =
      reviewCounts.fold<int>(0, (sum, count) => sum + count);
  var totalPercents = 0.0;
  for (final weekday in weekdays) {
    totalPercents = _float32(totalPercents + easyDays[weekday].loadModifier);
  }

  final result = <double>[];
  final pairCount = weekdays.length < reviewCounts.length
      ? weekdays.length
      : reviewCounts.length;
  for (var index = 0; index < pairCount; index++) {
    final weekday = weekdays[index];
    final reviewCount = reviewCounts[index];
    var day = easyDays[weekday];
    if (day == EasyDay.reduced) {
      const half = 0.5;
      final otherDaysReviewTotal = _float32(
        (totalReviewCount - reviewCount).toDouble(),
      );
      final otherDaysPercentTotal = _float32(totalPercents - half);
      final normalizedCount = _float32(
        _float32(reviewCount.toDouble()) / half,
      );
      final reducedDayThreshold = _float32(
        otherDaysReviewTotal / otherDaysPercentTotal,
      );
      if (normalizedCount > reducedDayThreshold) {
        day = EasyDay.minimum;
      } else {
        day = EasyDay.normal;
      }
    }
    result.add(day.loadModifier);
  }
  return result;
}

double _float32(double value) {
  final narrowed = Float32List(1)..[0] = value;
  return narrowed[0];
}
