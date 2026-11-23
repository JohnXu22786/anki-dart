// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

/// Inputs for Core's per-interval load-balancer weight calculation.
///
/// The modifiers are supplied by the caller; this model does not derive
/// sibling history, easy-day configuration, or scheduler state.
class IntervalLoadCandidate {
  const IntervalLoadCandidate({
    required this.targetInterval,
    required this.reviewCount,
    this.siblingModifier = 1.0,
    this.easyDaysModifier = 1.0,
  });

  final int targetInterval;
  final int reviewCount;
  final double siblingModifier;
  final double easyDaysModifier;
}

/// Computes Core's pure weight for one interval candidate using float32
/// arithmetic. A candidate with no reviews always receives full weight.
double calculateIntervalLoadWeight(IntervalLoadCandidate candidate) {
  if (candidate.targetInterval < 0 || candidate.targetInterval > 0xffffffff) {
    throw ArgumentError.value(
      candidate.targetInterval,
      'targetInterval',
      'must fit in a Core u32',
    );
  }
  if (candidate.reviewCount < 0 || candidate.reviewCount > 0x20000000000000) {
    throw ArgumentError.value(
      candidate.reviewCount,
      'reviewCount',
      'must be a nonnegative integer no greater than 2^53',
    );
  }
  if (candidate.reviewCount == 0) return 1.0;

  final reviewCount = _float32(candidate.reviewCount.toDouble());
  final targetInterval = _float32(candidate.targetInterval.toDouble());
  final reviewBase = _float32(1.0 / reviewCount);
  final reviewExponent = _float32(2.15);
  final reviewWeight =
      _float32(math.pow(reviewBase, reviewExponent).toDouble());
  final intervalBase = _float32(1.0 / targetInterval);
  final squaredIntervalBase = _float32(intervalBase * intervalBase);
  final intervalWeight = _float32(squaredIntervalBase * intervalBase);
  final siblingModifier = _float32(candidate.siblingModifier);
  final easyDaysModifier = _float32(candidate.easyDaysModifier);

  return _float32(
    _float32(
          _float32(reviewWeight * intervalWeight) * siblingModifier,
        ) *
        easyDaysModifier,
  );
}

double _float32(double value) {
  final narrowed = Float32List(1)..[0] = value;
  return narrowed[0];
}
