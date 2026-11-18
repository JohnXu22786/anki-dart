// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'card.dart';

const double _initialEaseFactor = 2.5;
const double _minimumEaseFactor = 1.3;
const double _againEaseDelta = -0.2;
const double _hardEaseDelta = -0.15;
const double _easyEaseDelta = 0.15;
const int _maximumU32 = 0xffffffff;
const int _secondsPerDay = 86400;

/// The Core-provided FSRS interval and memory state for one answer rating.
class FsrsReviewNextState {
  FsrsReviewNextState({required double interval, required this.memoryState})
      : interval = _toFloat32(interval);

  final double interval;
  final FsrsMemoryState memoryState;
}

/// FSRS review outputs supplied by Core or another scheduler host.
class FsrsReviewNextStates {
  const FsrsReviewNextStates({
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });

  final FsrsReviewNextState again;
  final FsrsReviewNextState hard;
  final FsrsReviewNextState good;
  final FsrsReviewNextState easy;
}

/// Inputs normally read from scheduler configuration or computed by Core.
///
/// [fuzzFactor] is a deterministic value in the same `[0, 1)` range Core uses
/// for its fuzz draw. FSRS interval/memory calculations are caller supplied.
class ReviewSchedulingContext {
  const ReviewSchedulingContext({
    this.hardMultiplier = 1.2,
    this.easyMultiplier = 1.3,
    this.intervalMultiplier = 1.0,
    this.maximumReviewInterval = 36500,
    this.leechThreshold = 8,
    this.lapseMultiplier = 0.0,
    this.minimumLapseInterval = 1,
    this.fuzzFactor,
    this.fsrsNextStates,
    this.relearningAgainDelaySecs,
    this.relearningRemainingSteps = 0,
    this.fsrsAllowShortTerm = false,
    this.fsrsShortTermWithStepsEnabled = false,
    this.relearningStepsEmpty = true,
  });

  final double hardMultiplier;
  final double easyMultiplier;
  final double intervalMultiplier;
  final int maximumReviewInterval;
  final int leechThreshold;
  final double lapseMultiplier;
  final int minimumLapseInterval;
  final double? fuzzFactor;
  final FsrsReviewNextStates? fsrsNextStates;
  final int? relearningAgainDelaySecs;
  final int relearningRemainingSteps;
  final bool fsrsAllowShortTerm;
  final bool fsrsShortTermWithStepsEnabled;
  final bool relearningStepsEmpty;
}

/// A review-card state as used by Anki Core's scheduling-state calculation.
class ReviewCardState {
  ReviewCardState({
    int scheduledDays = 0,
    int elapsedDays = 0,
    double easeFactor = _initialEaseFactor,
    int lapses = 0,
    bool leeched = false,
    this.memoryState,
  })  : scheduledDays = scheduledDays.toUnsigned(32),
        elapsedDays = elapsedDays.toUnsigned(32),
        easeFactor = _toFloat32(easeFactor),
        lapses = lapses.toUnsigned(32),
        leeched = leeched;

  final int scheduledDays;
  final int elapsedDays;
  final double easeFactor;
  final int lapses;
  final bool leeched;
  final FsrsMemoryState? memoryState;

  /// Calculate Again/Hard/Good/Easy outcomes using Core's review rules.
  ReviewCardSchedulingStates nextStates(ReviewSchedulingContext context) {
    final intervals = _passingReviewIntervals(context);
    final again = _answerAgain(context);
    return ReviewCardSchedulingStates(
      current: ReviewCardTransition.review(this),
      again: again,
      hard: ReviewCardTransition.review(
        _answerHard(intervals.$1, context),
      ),
      good: ReviewCardTransition.review(
        _answerGood(intervals.$2, context),
      ),
      easy: ReviewCardTransition.review(
        _answerEasy(intervals.$3, context),
      ),
    );
  }

  ReviewCardState _answerHard(int scheduledDays, ReviewSchedulingContext ctx) =>
      ReviewCardState(
        scheduledDays: scheduledDays,
        elapsedDays: 0,
        easeFactor: _f32((easeFactor + _hardEaseDelta).clamp(
          _minimumEaseFactor,
          double.infinity,
        )),
        lapses: lapses,
        leeched: leeched,
        memoryState: ctx.fsrsNextStates?.hard.memoryState,
      );

  ReviewCardState _answerGood(int scheduledDays, ReviewSchedulingContext ctx) =>
      ReviewCardState(
        scheduledDays: scheduledDays,
        elapsedDays: 0,
        easeFactor: easeFactor,
        lapses: lapses,
        leeched: leeched,
        memoryState: ctx.fsrsNextStates?.good.memoryState,
      );

  ReviewCardState _answerEasy(int scheduledDays, ReviewSchedulingContext ctx) =>
      ReviewCardState(
        scheduledDays: scheduledDays,
        elapsedDays: 0,
        easeFactor: _f32(easeFactor + _easyEaseDelta),
        lapses: lapses,
        leeched: leeched,
        memoryState: ctx.fsrsNextStates?.easy.memoryState,
      );

  ReviewCardTransition _answerAgain(ReviewSchedulingContext ctx) {
    final nextLapses = (lapses + 1).toUnsigned(32);
    final failedInterval = _failingReviewInterval(ctx);
    final review = ReviewCardState(
      scheduledDays:
          _asU32(failedInterval.$1.roundToDouble().clamp(1, double.infinity)),
      elapsedDays: 0,
      easeFactor: _f32((easeFactor + _againEaseDelta)
          .clamp(_minimumEaseFactor, double.infinity)),
      lapses: nextLapses,
      leeched: _leechThresholdMet(nextLapses, ctx.leechThreshold),
      memoryState: failedInterval.$2,
    );
    final delay = ctx.relearningAgainDelaySecs;
    if (delay != null) {
      return ReviewCardTransition.relearning(
        review,
        ReviewLearningState(
          remainingSteps: ctx.relearningRemainingSteps,
          scheduledSecs: delay,
          elapsedSecs: 0,
          memoryState: failedInterval.$2,
        ),
      );
    }

    if (ctx.fsrsAllowShortTerm &&
        (ctx.fsrsShortTermWithStepsEnabled || ctx.relearningStepsEmpty) &&
        failedInterval.$1 < 0.5) {
      return ReviewCardTransition.relearning(
        review,
        ReviewLearningState(
          remainingSteps: ctx.relearningRemainingSteps,
          scheduledSecs: _asU32(_f32(failedInterval.$1 * _secondsPerDay)),
          elapsedSecs: 0,
          memoryState: failedInterval.$2,
        ),
      );
    }
    return ReviewCardTransition.review(review);
  }

  (double, FsrsMemoryState?) _failingReviewInterval(
    ReviewSchedulingContext ctx,
  ) {
    final fsrs = ctx.fsrsNextStates;
    if (fsrs != null) return (fsrs.again.interval, fsrs.again.memoryState);

    final bounds = _minAndMax(ctx.minimumLapseInterval, ctx);
    final interval = _f32(
      _f32(scheduledDays.toDouble().clamp(1, double.infinity)) *
          _f32(ctx.lapseMultiplier),
    );
    return (_f32(_withReviewFuzz(interval, bounds.$1, bounds.$2, ctx)), null);
  }

  (int, int, int) _passingReviewIntervals(ReviewSchedulingContext ctx) {
    final fsrs = ctx.fsrsNextStates;
    if (fsrs != null) {
      int greaterThanLast(double interval) {
        final rounded = _asU32(interval.roundToDouble());
        return rounded > scheduledDays ? (scheduledDays + 1).toUnsigned(32) : 0;
      }

      final hard = _constrainPassingInterval(
        fsrs.hard.interval,
        greaterThanLast(fsrs.hard.interval).clamp(1, _maximumU32),
        true,
        ctx,
      );
      final good = _constrainPassingInterval(
        fsrs.good.interval,
        greaterThanLast(fsrs.good.interval).clamp(hard + 1, _maximumU32),
        true,
        ctx,
      );
      final easy = _constrainPassingInterval(
        fsrs.easy.interval,
        greaterThanLast(fsrs.easy.interval).clamp(good + 1, _maximumU32),
        true,
        ctx,
      );
      return (hard, good, easy);
    }
    return _daysLate < 0
        ? _passingEarlyReviewIntervals(ctx)
        : _passingNonEarlyReviewIntervals(ctx);
  }

  int get _daysLate =>
      (_asI32(elapsedDays) - _asI32(scheduledDays)).toSigned(32);

  (int, int, int) _passingNonEarlyReviewIntervals(
    ReviewSchedulingContext ctx,
  ) {
    final current = _f32(scheduledDays.toDouble().clamp(1, double.infinity));
    final late = _f32(_daysLate.clamp(0, 0x7fffffff).toDouble());
    final hardFactor = _f32(ctx.hardMultiplier);
    final hardMinimum =
        hardFactor <= 1 ? 0 : (scheduledDays + 1).toUnsigned(32);
    final hard = _constrainPassingInterval(
      _f32(current * hardFactor),
      hardMinimum,
      true,
      ctx,
    );
    final goodMinimum = hardFactor <= 1
        ? (scheduledDays + 1).toUnsigned(32)
        : (hard + 1).toUnsigned(32);
    final good = _constrainPassingInterval(
      _f32(_f32(current + _f32(late / 2)) * easeFactor),
      goodMinimum,
      true,
      ctx,
    );
    final easy = _constrainPassingInterval(
      _f32(_f32(_f32(current + late) * easeFactor) * _f32(ctx.easyMultiplier)),
      (good + 1).toUnsigned(32),
      true,
      ctx,
    );
    return (hard, good, easy);
  }

  (int, int, int) _passingEarlyReviewIntervals(ReviewSchedulingContext ctx) {
    final scheduled = _f32(scheduledDays.toDouble().clamp(1, double.infinity));
    final elapsed = _f32(elapsedDays.toDouble());
    final factor = _f32(ctx.hardMultiplier);
    final hardRaw = _f32(elapsed * factor);
    final hardMinimum = _f32(scheduled * _f32(factor / 2));
    final hard = _constrainPassingInterval(
      hardRaw > hardMinimum ? hardRaw : hardMinimum,
      0,
      false,
      ctx,
    );
    final usual = _f32(_f32(elapsed * easeFactor).clamp(
      scheduled,
      double.infinity,
    ));
    final good = _constrainPassingInterval(usual, 0, false, ctx);
    final reducedBonus = _f32(
      _f32(ctx.easyMultiplier) - _f32(_f32(_f32(ctx.easyMultiplier) - 1) / 2),
    );
    final easy = _constrainPassingInterval(
      _f32(usual * reducedBonus),
      0,
      false,
      ctx,
    );
    return (hard, good, easy);
  }

  int _constrainPassingInterval(
    double interval,
    int minimum,
    bool fuzz,
    ReviewSchedulingContext ctx,
  ) {
    final adjusted = ctx.fsrsNextStates == null
        ? _f32(interval * _f32(ctx.intervalMultiplier))
        : interval;
    final bounds = _minAndMax(minimum, ctx);
    return fuzz
        ? _withReviewFuzz(adjusted, bounds.$1, bounds.$2, ctx)
        : _asU32(adjusted.roundToDouble()).clamp(bounds.$1, bounds.$2).toInt();
  }

  (int, int) _minAndMax(int minimum, ReviewSchedulingContext ctx) {
    final maximum = ctx.maximumReviewInterval.clamp(1, _maximumU32);
    return (minimum.clamp(1, maximum), maximum);
  }
}

enum ReviewScheduleKind { review, relearning }

class ReviewLearningState {
  ReviewLearningState({
    required int remainingSteps,
    required int scheduledSecs,
    required int elapsedSecs,
    this.memoryState,
  })  : remainingSteps = remainingSteps.toUnsigned(32),
        scheduledSecs = scheduledSecs.toUnsigned(32),
        elapsedSecs = elapsedSecs.toUnsigned(32);

  final int remainingSteps;
  final int scheduledSecs;
  final int elapsedSecs;
  final FsrsMemoryState? memoryState;
}

class ReviewCardTransition {
  ReviewCardTransition.review(this.review)
      : kind = ReviewScheduleKind.review,
        learning = null;

  ReviewCardTransition.relearning(this.review, this.learning)
      : kind = ReviewScheduleKind.relearning;

  final ReviewScheduleKind kind;
  final ReviewCardState review;
  final ReviewLearningState? learning;
}

class ReviewCardSchedulingStates {
  const ReviewCardSchedulingStates({
    required this.current,
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });

  final ReviewCardTransition current;
  final ReviewCardTransition again;
  final ReviewCardTransition hard;
  final ReviewCardTransition good;
  final ReviewCardTransition easy;
}

int _withReviewFuzz(
  double interval,
  int minimum,
  int maximum,
  ReviewSchedulingContext ctx,
) {
  final fuzzFactor = ctx.fuzzFactor;
  if (fuzzFactor == null) {
    return _asU32(interval.roundToDouble()).clamp(minimum, maximum).toInt();
  }
  final bounds = _constrainedFuzzBounds(interval, minimum, maximum);
  final width = (1 + bounds.$2 - bounds.$1).toUnsigned(32);
  return _asU32(
    _f32(
      _f32(bounds.$1.toDouble()) +
          _f32(_f32(fuzzFactor) * _f32(width.toDouble())),
    ).floorToDouble(),
  ).clamp(minimum, maximum).toInt();
}

(int, int) _constrainedFuzzBounds(double interval, int minimum, int maximum) {
  minimum = minimum.clamp(0, maximum).toInt();
  final bounded =
      _f32(_f32(interval).clamp(minimum.toDouble(), maximum.toDouble()));
  final delta = _fuzzDelta(bounded);
  var lower = _asU32(_f32(bounded - delta).roundToDouble());
  var upper = _asU32(_f32(bounded + delta).roundToDouble());
  lower = lower.clamp(minimum, maximum);
  upper = upper.clamp(minimum, maximum);
  if (upper == lower && upper > 2 && upper < maximum) upper++;
  return (lower, upper);
}

double _fuzzDelta(double interval) {
  if (interval < 2.5) return 0;
  var delta = 1.0;
  for (final range in const [
    (2.5, 7.0, 0.15),
    (7.0, 20.0, 0.1),
    (20.0, double.infinity, 0.05),
  ]) {
    delta = _f32(delta +
        _f32(range.$3 *
            _f32((interval < range.$2 ? interval : range.$2) - range.$1)
                .clamp(0, double.infinity)));
  }
  return delta;
}

bool _leechThresholdMet(int lapses, int threshold) {
  if (threshold == 0) return false;
  final halfThreshold =
      _asU32(_f32(_f32(threshold.toDouble()) / 2).ceilToDouble())
          .clamp(1, _maximumU32)
          .toInt();
  return lapses >= threshold && (lapses - threshold) % halfThreshold == 0;
}

double _toFloat32(double value) =>
    (ByteData(4)..setFloat32(0, value, Endian.little))
        .getFloat32(0, Endian.little);

double _f32(num value) => _toFloat32(value.toDouble());

int _asU32(double value) {
  if (value.isNaN || value <= 0) return 0;
  if (value >= _maximumU32) return _maximumU32;
  return value.toInt();
}

int _asI32(int value) => value.toSigned(32);
