// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'card.dart';
import 'fsrs_memory_state.dart';

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
    this.loadBalancedIntervalResolver,
    this.fsrsNextStates,
    this.fsrsParams,
    this.fsrsDesiredRetention,
    this.relearningAgainDelaySecs,
    this.relearningRemainingSteps = 0,
    this.fsrsAllowShortTerm = false,
    this.fsrsShortTermWithStepsEnabled = false,
    this.relearningStepsEmpty = true,
    this.learningStepsMinutes = const [],
    this.relearningStepsMinutes = const [],
    this.graduatingIntervalGood = 1,
    this.graduatingIntervalEasy = 4,
  });

  final double hardMultiplier;
  final double easyMultiplier;
  final double intervalMultiplier;
  final int maximumReviewInterval;
  final int leechThreshold;
  final double lapseMultiplier;
  final int minimumLapseInterval;
  final double? fuzzFactor;

  /// Resolves a review interval against a fixed load-balancer context.
  ///
  /// Called only for passing review intervals that use Core's fuzz path, after
  /// interval multipliers and final minimum/maximum bounds are applied. A null
  /// result falls back to [fuzzFactor].
  final ReviewLoadBalancerIntervalResolver? loadBalancedIntervalResolver;
  final FsrsReviewNextStates? fsrsNextStates;

  /// Exact FSRS parameter set used when [fsrsNextStates] is not precomputed.
  final List<double>? fsrsParams;

  /// Desired FSRS retention used with [fsrsParams].
  final double? fsrsDesiredRetention;
  final int? relearningAgainDelaySecs;
  final int relearningRemainingSteps;
  final bool fsrsAllowShortTerm;
  final bool fsrsShortTermWithStepsEnabled;
  final bool relearningStepsEmpty;

  /// Learning steps in minutes, as stored by scheduler configuration.
  final List<double> learningStepsMinutes;
  final List<double> relearningStepsMinutes;
  final int graduatingIntervalGood;
  final int graduatingIntervalEasy;

  ReviewSchedulingContext _withFsrsNextStates(FsrsReviewNextStates states) =>
      ReviewSchedulingContext(
        hardMultiplier: hardMultiplier,
        easyMultiplier: easyMultiplier,
        intervalMultiplier: intervalMultiplier,
        maximumReviewInterval: maximumReviewInterval,
        leechThreshold: leechThreshold,
        lapseMultiplier: lapseMultiplier,
        minimumLapseInterval: minimumLapseInterval,
        fuzzFactor: fuzzFactor,
        loadBalancedIntervalResolver: loadBalancedIntervalResolver,
        fsrsNextStates: states,
        fsrsParams: fsrsParams,
        fsrsDesiredRetention: fsrsDesiredRetention,
        relearningAgainDelaySecs: relearningAgainDelaySecs,
        relearningRemainingSteps: relearningRemainingSteps,
        fsrsAllowShortTerm: fsrsAllowShortTerm,
        fsrsShortTermWithStepsEnabled: fsrsShortTermWithStepsEnabled,
        relearningStepsEmpty: relearningStepsEmpty,
        learningStepsMinutes: learningStepsMinutes,
        relearningStepsMinutes: relearningStepsMinutes,
        graduatingIntervalGood: graduatingIntervalGood,
        graduatingIntervalEasy: graduatingIntervalEasy,
      );
}

/// Resolves one interval against a fixed load-balancer context.
typedef ReviewLoadBalancerIntervalResolver = int? Function(
  double interval,
  int minimum,
  int maximum,
);

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
    if (context.fsrsNextStates == null &&
        context.fsrsParams != null &&
        context.fsrsDesiredRetention != null) {
      final calculated = computeFsrsNextStates(
        currentMemoryState: memoryState,
        daysElapsed: elapsedDays,
        desiredRetention: context.fsrsDesiredRetention!,
        params: context.fsrsParams!,
      );
      context = context._withFsrsNextStates(
        FsrsReviewNextStates(
          again: FsrsReviewNextState(
            interval: calculated.again.interval,
            memoryState: calculated.again.memoryState,
          ),
          hard: FsrsReviewNextState(
            interval: calculated.hard.interval,
            memoryState: calculated.hard.memoryState,
          ),
          good: FsrsReviewNextState(
            interval: calculated.good.interval,
            memoryState: calculated.good.memoryState,
          ),
          easy: FsrsReviewNextState(
            interval: calculated.easy.interval,
            memoryState: calculated.easy.memoryState,
          ),
        ),
      );
    }
    final intervals = _passingReviewIntervals(context);
    final again = _answerAgain(context);
    return ReviewCardSchedulingStates(
      current: ReviewCardTransition.review(this),
      again: again,
      hard: ReviewCardTransition.review(_answerHard(intervals.$1, context)),
      good: ReviewCardTransition.review(_answerGood(intervals.$2, context)),
      easy: ReviewCardTransition.review(_answerEasy(intervals.$3, context)),
    );
  }

  ReviewCardState _answerHard(int scheduledDays, ReviewSchedulingContext ctx) =>
      ReviewCardState(
        scheduledDays: scheduledDays,
        elapsedDays: 0,
        easeFactor: _f32(
          (easeFactor + _hardEaseDelta).clamp(
            _minimumEaseFactor,
            double.infinity,
          ),
        ),
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
      scheduledDays: _asU32(
        failedInterval.$1.roundToDouble().clamp(1, double.infinity),
      ),
      elapsedDays: 0,
      easeFactor: _f32(
        (easeFactor + _againEaseDelta).clamp(
          _minimumEaseFactor,
          double.infinity,
        ),
      ),
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

  (int, int, int) _passingNonEarlyReviewIntervals(ReviewSchedulingContext ctx) {
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
    final usual = _f32(
      _f32(elapsed * easeFactor).clamp(scheduled, double.infinity),
    );
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
    if (!fuzz) {
      return _asU32(adjusted.roundToDouble())
          .clamp(bounds.$1, bounds.$2)
          .toInt();
    }
    final balanced = ctx.loadBalancedIntervalResolver?.call(
      adjusted,
      bounds.$1,
      bounds.$2,
    );
    return balanced ?? _withReviewFuzz(adjusted, bounds.$1, bounds.$2, ctx);
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

/// The learning portion of a Core scheduling state.
class LearningCardState {
  LearningCardState({
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

  LearningCardSchedulingStates nextStates(ReviewSchedulingContext ctx) =>
      _learningStates(this, ctx, false);
}

/// Learning state returned with the original review state during relearning.
class RelearningCardState {
  const RelearningCardState({required this.learning, required this.review});
  final LearningCardState learning;
  final ReviewCardState review;

  LearningCardSchedulingStates nextStates(ReviewSchedulingContext ctx) =>
      _learningStates(learning, ctx, true, review: review);
}

/// The new-card position is preserved as the current state; outcomes follow
/// Core's failed-learning transition using the configured learning steps.
class NewCardState {
  NewCardState({int position = 0}) : position = position.toUnsigned(32);
  final int position;

  LearningCardSchedulingStates nextStates(ReviewSchedulingContext ctx) {
    final result = _learningStates(
      LearningCardState(
        remainingSteps: ctx.learningStepsMinutes.length,
        scheduledSecs: 0,
        elapsedSecs: 0,
      ),
      ctx,
      false,
    );
    return result.copyWithCurrent(LearningCardTransition.newCard(this));
  }
}

enum LearningTransitionKind { newCard, learning, relearning, review }

class LearningCardTransition {
  const LearningCardTransition.newCard(NewCardState state)
      : kind = LearningTransitionKind.newCard,
        newCard = state,
        learning = null,
        review = null;
  const LearningCardTransition.learning(LearningCardState state)
      : kind = LearningTransitionKind.learning,
        newCard = null,
        learning = state,
        review = null;
  const LearningCardTransition.relearning(
    LearningCardState state,
    ReviewCardState reviewState,
  )   : kind = LearningTransitionKind.relearning,
        newCard = null,
        learning = state,
        review = reviewState;
  const LearningCardTransition.review(ReviewCardState state)
      : kind = LearningTransitionKind.review,
        newCard = null,
        learning = null,
        review = state;

  final LearningTransitionKind kind;
  final NewCardState? newCard;
  final LearningCardState? learning;
  final ReviewCardState? review;
}

class LearningCardSchedulingStates {
  const LearningCardSchedulingStates({
    required this.current,
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });
  final LearningCardTransition current;
  final LearningCardTransition again;
  final LearningCardTransition hard;
  final LearningCardTransition good;
  final LearningCardTransition easy;

  LearningCardSchedulingStates copyWithCurrent(LearningCardTransition value) =>
      LearningCardSchedulingStates(
        current: value,
        again: again,
        hard: hard,
        good: good,
        easy: easy,
      );
}

LearningCardSchedulingStates _learningStates(
  LearningCardState state,
  ReviewSchedulingContext ctx,
  bool relearning, {
  ReviewCardState? review,
}) {
  final steps =
      relearning ? ctx.relearningStepsMinutes : ctx.learningStepsMinutes;
  final count = steps.length;
  int index(int remaining) =>
      (count - (remaining % 1000)).clamp(0, count == 0 ? 0 : count - 1);
  int secs(double minutes) => _asU32(_f32(_f32(minutes) * 60.0));
  int goodRemaining(int remaining) =>
      (count - (index(remaining) + 1)).clamp(0, count);
  int? delayGood(int remaining) =>
      index(remaining) + 1 < count ? secs(steps[index(remaining) + 1]) : null;
  int? delayHard(int remaining) {
    if (count == 0) return null;
    final i = index(remaining);
    final current = secs(steps[i]);
    if (i != 0) return current;
    final int raw;
    if (count > 1) {
      raw = (current + secs(steps[1])).clamp(0, _maximumU32) ~/ 2;
    } else {
      final scaled = (current * 3).clamp(0, _maximumU32) ~/ 2;
      final max = (current + 86400).clamp(0, _maximumU32);
      raw = scaled.clamp(0, max);
    }
    return raw > 86400 ? _f32(raw / 86400).round() * 86400 : raw;
  }

  FsrsMemoryState? memory(int rating) {
    final values = ctx.fsrsNextStates;
    if (values == null) return null;
    return [
      values.again,
      values.hard,
      values.good,
      values.easy,
    ][rating]
        .memoryState;
  }

  LearningCardTransition learning(
    int rating, {
    int? scheduled,
    int? remaining,
    bool preserveElapsed = false,
  }) =>
      LearningCardTransition.learning(
        LearningCardState(
          remainingSteps: remaining ?? state.remainingSteps,
          scheduledSecs: scheduled ?? state.scheduledSecs,
          elapsedSecs: preserveElapsed ? state.elapsedSecs : 0,
          memoryState: memory(rating),
        ),
      );
  LearningCardTransition graduate(int rating, int interval) {
    final fsrs = ctx.fsrsNextStates;
    final raw = fsrs == null
        ? interval.toDouble()
        : [
            fsrs.again.interval,
            fsrs.hard.interval,
            fsrs.good.interval,
            fsrs.easy.interval,
          ][rating];
    final allowShort = fsrs != null &&
        ctx.fsrsAllowShortTerm &&
        (ctx.fsrsShortTermWithStepsEnabled || steps.isEmpty) &&
        raw < 0.5 &&
        rating != 3;
    if (allowShort) {
      final shortState = learning(
        rating,
        scheduled: _asU32(_f32(raw * _secondsPerDay.toDouble())),
        preserveElapsed: relearning && rating != 0,
        remaining: rating == 0
            ? count
            : rating == 2 && relearning
                ? goodRemaining(state.remainingSteps)
                : state.remainingSteps,
      );
      if (relearning && review != null) {
        final bounds = _minMax(1, ctx.maximumReviewInterval);
        final days = _withReviewFuzz(
          raw.roundToDouble().clamp(1, double.infinity),
          bounds.$1,
          bounds.$2,
          ctx,
        );
        return LearningCardTransition.relearning(
          shortState.learning!,
          ReviewCardState(
            scheduledDays: days,
            elapsedDays: rating != 3 ? review.elapsedDays : 0,
            easeFactor: review.easeFactor,
            lapses: review.lapses,
            leeched: review.leeched,
            memoryState: memory(rating),
          ),
        );
      }
      return shortState;
    }
    final bounds = _minMax(1, ctx.maximumReviewInterval);
    var min = bounds.$1;
    if (rating == 3 && fsrs != null) {
      min = _withReviewFuzz(fsrs.good.interval, min, bounds.$2, ctx) + 1;
    }
    final fuzzed = _withReviewFuzz(
      raw.roundToDouble().clamp(1, double.infinity),
      min,
      bounds.$2,
      ctx,
    );
    if (relearning && review != null) {
      return LearningCardTransition.review(
        ReviewCardState(
          scheduledDays: fuzzed,
          elapsedDays: fsrs != null && rating != 3 ? review.elapsedDays : 0,
          easeFactor: review.easeFactor,
          lapses: review.lapses,
          leeched: review.leeched,
          memoryState: memory(rating),
        ),
      );
    }
    return LearningCardTransition.review(
      ReviewCardState(
        scheduledDays: fuzzed,
        easeFactor: _initialEaseFactor,
        memoryState: memory(rating),
      ),
    );
  }

  LearningCardTransition answer(int rating) {
    if (rating == 0) {
      if (steps.isNotEmpty)
        return learning(0, scheduled: secs(steps.first), remaining: count);
      return graduate(0, ctx.graduatingIntervalGood);
    }
    if (rating == 1) {
      final d = delayHard(state.remainingSteps);
      if (d != null) {
        return learning(1, scheduled: d, preserveElapsed: relearning);
      }
      if (relearning && review != null && ctx.fsrsNextStates == null) {
        return LearningCardTransition.review(review);
      }
      return graduate(1, ctx.graduatingIntervalGood);
    }
    if (rating == 2) {
      final d = delayGood(state.remainingSteps);
      if (d != null)
        return learning(
          2,
          scheduled: d,
          remaining: goodRemaining(state.remainingSteps),
        );
      if (relearning && review != null && ctx.fsrsNextStates == null) {
        return LearningCardTransition.review(review);
      }
      return graduate(2, ctx.graduatingIntervalGood);
    }
    if (relearning && review != null && ctx.fsrsNextStates == null) {
      return LearningCardTransition.review(
        ReviewCardState(
          scheduledDays: review.scheduledDays + 1,
          elapsedDays: 0,
          easeFactor: review.easeFactor,
          lapses: review.lapses,
          leeched: review.leeched,
        ),
      );
    }
    return graduate(
      3,
      relearning && review != null
          ? review.scheduledDays + 1
          : ctx.graduatingIntervalEasy,
    );
  }

  LearningCardTransition outcome(int rating) {
    if (!relearning) return answer(rating);
    if (rating == 0 && review != null) {
      final againDelay = steps.isEmpty ? null : secs(steps.first);
      final memoryAgain = memory(0);
      final failInterval = review._failingReviewInterval(ctx).$1;
      final againDays = ctx.fsrsNextStates == null
          ? _asU32(failInterval.roundToDouble().clamp(1, double.infinity))
          : steps.isNotEmpty
              ? _asU32(failInterval.roundToDouble().clamp(1, double.infinity))
              : _withReviewFuzz(
                  failInterval.roundToDouble().clamp(1, double.infinity),
                  1,
                  ctx.maximumReviewInterval,
                  ctx,
                );
      final nextReview = ReviewCardState(
        scheduledDays: againDays,
        elapsedDays: steps.isEmpty && ctx.fsrsNextStates != null
            ? review.elapsedDays
            : 0,
        easeFactor: review.easeFactor,
        lapses: review.lapses,
        leeched: review.leeched,
        memoryState: memoryAgain,
      );
      if (againDelay != null)
        return LearningCardTransition.relearning(
          LearningCardState(
            remainingSteps: count,
            scheduledSecs: againDelay,
            elapsedSecs: 0,
            memoryState: memoryAgain,
          ),
          nextReview,
        );
      if (ctx.fsrsNextStates != null &&
          ctx.fsrsAllowShortTerm &&
          (ctx.fsrsShortTermWithStepsEnabled || steps.isEmpty) &&
          failInterval < 0.5) {
        return LearningCardTransition.relearning(
          LearningCardState(
            remainingSteps: count,
            scheduledSecs: _asU32(
              _f32(failInterval * _secondsPerDay.toDouble()),
            ),
            elapsedSecs: 0,
            memoryState: memoryAgain,
          ),
          nextReview,
        );
      }
      return ctx.fsrsNextStates == null
          ? LearningCardTransition.review(review)
          : LearningCardTransition.review(nextReview);
    }
    final res = answer(rating);
    if (res.kind == LearningTransitionKind.learning && review != null) {
      final r = ReviewCardState(
        scheduledDays: review.scheduledDays,
        elapsedDays: 0,
        easeFactor: review.easeFactor,
        lapses: review.lapses,
        leeched: review.leeched,
        memoryState: memory(rating),
      );
      return LearningCardTransition.relearning(res.learning!, r);
    }
    return res;
  }

  return LearningCardSchedulingStates(
    current: relearning && review != null
        ? LearningCardTransition.relearning(state, review)
        : LearningCardTransition.learning(state),
    again: outcome(0),
    hard: outcome(1),
    good: outcome(2),
    easy: outcome(3),
  );
}

(int, int) _minMax(int minimum, int maximum) {
  final max = maximum.clamp(1, _maximumU32).toInt();
  return (minimum.clamp(1, max).toInt(), max);
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
  final bounds = constrainedFuzzBounds(interval, minimum, maximum);
  final width = (1 + bounds.$2 - bounds.$1).toUnsigned(32);
  return _asU32(
    _f32(
      _f32(bounds.$1.toDouble()) +
          _f32(_f32(fuzzFactor) * _f32(width.toDouble())),
    ).floorToDouble(),
  ).clamp(minimum, maximum).toInt();
}

/// Computes Core's inclusive fuzz interval bounds after applying limits.
///
/// The interval and intermediate arithmetic use Float32 precision, and a
/// collapsed range is widened by one day when Core's limits permit it.
(int, int) constrainedFuzzBounds(
  double interval,
  int minimum,
  int maximum,
) {
  minimum = minimum.clamp(0, maximum).toInt();
  final bounded = _f32(
    _f32(interval).clamp(minimum.toDouble(), maximum.toDouble()),
  );
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
    delta = _f32(
      delta +
          _f32(
            range.$3 *
                _f32((interval < range.$2 ? interval : range.$2) - range.$1)
                    .clamp(0, double.infinity),
          ),
    );
  }
  return delta;
}

bool _leechThresholdMet(int lapses, int threshold) {
  if (threshold == 0) return false;
  final halfThreshold = _asU32(
    _f32(_f32(threshold.toDouble()) / 2).ceilToDouble(),
  ).clamp(1, _maximumU32).toInt();
  return lapses >= threshold && (lapses - threshold) % halfThreshold == 0;
}

double _toFloat32(double value) => (ByteData(
      4,
    )..setFloat32(0, value, Endian.little))
        .getFloat32(0, Endian.little);

double _f32(num value) => _toFloat32(value.toDouble());

int _asU32(double value) {
  if (value.isNaN || value <= 0) return 0;
  if (value >= _maximumU32) return _maximumU32;
  return value.toInt();
}

int _asI32(int value) => value.toSigned(32);
