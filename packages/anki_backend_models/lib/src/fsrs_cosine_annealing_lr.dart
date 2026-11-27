// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;

/// Stateful FSRS 5.2.0 cosine annealing learning-rate schedule.
///
/// [tMax] and [initialLearningRate] are fixed for the lifetime of this
/// scheduler. [loadRecord] restores only the step count, matching the source
/// scheduler's record semantics.
class FsrsCosineAnnealingLr {
  FsrsCosineAnnealingLr({
    required this.tMax,
    required this.initialLearningRate,
  })  : _stepCount = -1,
        _currentLearningRate = initialLearningRate {
    if (!tMax.isFinite || tMax <= 0.0) {
      throw ArgumentError.value(tMax, 'tMax', 'must be finite and positive');
    }
    if (!initialLearningRate.isFinite || initialLearningRate < 0.0) {
      throw ArgumentError.value(
        initialLearningRate,
        'initialLearningRate',
        'must be finite and nonnegative',
      );
    }
  }

  /// The period parameter used by the cosine schedule.
  final double tMax;

  /// Learning rate returned on the first step and at cosine restarts.
  final double initialLearningRate;

  int _stepCount;
  double _currentLearningRate;

  /// Number of steps completed; starts at -1 to match FSRS 5.2.0.
  int get stepCount => _stepCount;

  /// Learning rate produced by the most recent step.
  double get currentLearningRate => _currentLearningRate;

  /// Advances the schedule by one step and returns its current learning rate.
  double step() {
    _stepCount++;
    final stepCount = _stepCount.toDouble();
    if (stepCount == 0.0) {
      _currentLearningRate = initialLearningRate;
    } else if ((stepCount - 1.0 - tMax) % (2.0 * tMax) == 0.0) {
      _currentLearningRate =
          (initialLearningRate * (1.0 - math.cos(math.pi / tMax))) / 2.0;
    } else {
      final ratio = (1.0 + math.cos(math.pi * stepCount / tMax)) /
          (1.0 + math.cos(math.pi * (stepCount - 1.0) / tMax));
      // Dart exposes no fused multiply-add for Float64. This keeps the source
      // multiply-then-add order, with etaMin fixed at zero.
      _currentLearningRate = ratio * _currentLearningRate + 0.0;
    }
    return _currentLearningRate;
  }

  /// Returns the source-compatible nonnegative integer record.
  ///
  /// Rust's float-to-`usize` cast saturates the initial -1 step to zero.
  int toRecord() => _stepCount < 0 ? 0 : _stepCount;

  /// Restores a record's step count without changing the current learning rate.
  void loadRecord(Object? record) {
    if (record is! int || record < 0) {
      throw ArgumentError.value(
        record,
        'record',
        'must be a nonnegative integer',
      );
    }
    _stepCount = record;
  }
}
