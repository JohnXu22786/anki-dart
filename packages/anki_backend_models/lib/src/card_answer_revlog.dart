// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as scheduler;

import 'revlog.dart';

/// Derives the revlog result Core records for a supplied [answer].
///
/// [secsUntilDayRollover] is the caller's timing snapshot. This helper does
/// not read the clock or collection and does not apply or persist the answer.
RevlogEntry revlogEntryFromCardAnswer({
  required scheduler.CardAnswer answer,
  required int usn,
  required int secsUntilDayRollover,
}) {
  if (!answer.hasCurrentState() || !answer.hasNewState()) {
    throw ArgumentError.value(
        answer, 'answer', 'current and new states are required');
  }
  if (usn < -0x80000000 || usn > 0x7fffffff) {
    throw ArgumentError.value(usn, 'usn', 'expected an int32');
  }
  _requireUint32(secsUntilDayRollover, 'secsUntilDayRollover');
  _requireUint32(answer.millisecondsTaken, 'answer.millisecondsTaken');

  final current = _stateFor(answer.currentState, 'answer.currentState');
  final next = _stateFor(answer.newState, 'answer.newState');
  final buttonChosen = switch (answer.rating) {
    scheduler.CardAnswer_Rating.AGAIN => 1,
    scheduler.CardAnswer_Rating.HARD => 2,
    scheduler.CardAnswer_Rating.GOOD => 3,
    scheduler.CardAnswer_Rating.EASY => 4,
    _ => throw ArgumentError.value(
        answer.rating,
        'answer.rating',
        'unsupported rating',
      ),
  };

  final easeFactor = _easeFactorFor(next);
  if (!easeFactor.isFinite || easeFactor < 0) {
    throw ArgumentError.value(
        easeFactor, 'answer.newState', 'invalid ease factor');
  }
  final scaledEase = _float32(easeFactor * 1000);
  if (!scaledEase.isFinite || scaledEase > 0xffffffff) {
    throw ArgumentError.value(
        easeFactor, 'answer.newState', 'ease factor exceeds uint32');
  }

  return RevlogEntry(
    id: RevlogId(answer.answeredAtMillis),
    cardId: answer.cardId,
    usn: usn,
    buttonChosen: buttonChosen,
    interval: _revlogInterval(next.interval, secsUntilDayRollover),
    lastInterval: _revlogInterval(current.interval, secsUntilDayRollover),
    easeFactor: _roundToUint32(scaledEase),
    takenMillis: answer.millisecondsTaken,
    reviewKind: current.reviewKind,
  );
}

_SchedulingState _stateFor(scheduler.SchedulingState state, String name) {
  switch (state.whichKind()) {
    case scheduler.SchedulingState_Kind.normal:
      final normal = state.normal;
      return switch (normal.whichKind()) {
        scheduler.SchedulingState_Normal_Kind.new_1 => _SchedulingState(
            interval: const _Interval.seconds(0),
            reviewKind: RevlogReviewKind.learning,
          ),
        scheduler.SchedulingState_Normal_Kind.learning => _SchedulingState(
            interval: _Interval.seconds(
              _uint32StateValue(normal.learning.scheduledSecs, name),
            ),
            reviewKind: RevlogReviewKind.learning,
            memoryDifficulty: normal.learning.hasMemoryState()
                ? normal.learning.memoryState.difficulty
                : null,
          ),
        scheduler.SchedulingState_Normal_Kind.review => _SchedulingState(
            interval: _Interval.days(normal.review.scheduledDays),
            reviewKind: normal.review.elapsedDays < normal.review.scheduledDays
                ? RevlogReviewKind.filtered
                : RevlogReviewKind.review,
            easeFactor: normal.review.easeFactor,
            memoryDifficulty: normal.review.hasMemoryState()
                ? normal.review.memoryState.difficulty
                : null,
          ),
        scheduler.SchedulingState_Normal_Kind.relearning => () {
            final relearning = normal.relearning;
            if (!relearning.hasReview() || !relearning.hasLearning()) {
              throw ArgumentError.value(
                state,
                name,
                'relearning state must contain review and learning values',
              );
            }
            return _SchedulingState(
              interval: _Interval.seconds(
                _uint32StateValue(relearning.learning.scheduledSecs, name),
              ),
              reviewKind: RevlogReviewKind.relearning,
              easeFactor: relearning.review.easeFactor,
              memoryDifficulty: relearning.learning.hasMemoryState()
                  ? relearning.learning.memoryState.difficulty
                  : null,
            );
          }(),
        scheduler.SchedulingState_Normal_Kind.notSet =>
          throw ArgumentError.value(
            state,
            name,
            'normal state must contain a state variant',
          ),
      };
    case scheduler.SchedulingState_Kind.filtered:
      final filtered = state.filtered;
      return switch (filtered.whichKind()) {
        scheduler.SchedulingState_Filtered_Kind.preview => _SchedulingState(
            interval: _Interval.seconds(
              _uint32StateValue(filtered.preview.scheduledSecs, name),
            ),
            reviewKind: RevlogReviewKind.filtered,
          ),
        scheduler.SchedulingState_Filtered_Kind.rescheduling => () {
            if (!filtered.rescheduling.hasOriginalState()) {
              throw ArgumentError.value(
                state,
                name,
                'rescheduling state must contain an original state',
              );
            }
            return _stateFor(
              scheduler.SchedulingState(
                  normal: filtered.rescheduling.originalState),
              name,
            );
          }(),
        scheduler.SchedulingState_Filtered_Kind.notSet =>
          throw ArgumentError.value(
            state,
            name,
            'filtered state must contain a state variant',
          ),
      };
    case scheduler.SchedulingState_Kind.notSet:
      throw ArgumentError.value(
        state,
        name,
        'state must contain a normal or filtered wrapper',
      );
  }
}

class _SchedulingState {
  const _SchedulingState({
    required this.interval,
    required this.reviewKind,
    this.easeFactor,
    this.memoryDifficulty,
  });

  final _Interval interval;
  final RevlogReviewKind reviewKind;
  final double? easeFactor;
  final double? memoryDifficulty;
}

class _Interval {
  const _Interval.days(this.value) : isSeconds = false;
  const _Interval.seconds(this.value) : isSeconds = true;

  final int value;
  final bool isSeconds;
}

double _easeFactorFor(_SchedulingState state) {
  if (state.memoryDifficulty case final difficulty?) {
    if (!difficulty.isFinite || difficulty < 1 || difficulty > 10) {
      throw ArgumentError.value(
        difficulty,
        'answer.newState.memoryState.difficulty',
        'expected a finite FSRS difficulty from 1 through 10',
      );
    }
    return _float32(_float32(difficulty) + _float32(0.1));
  }
  return state.easeFactor ?? 0;
}

int _uint32StateValue(int value, String name) {
  _requireUint32(value, name);
  return value;
}

void _requireUint32(int value, String name) {
  if (value < 0 || value > 0xffffffff) {
    throw ArgumentError.value(value, name, 'expected a uint32');
  }
}

int _revlogInterval(_Interval interval, int secsUntilRollover) {
  if (!interval.isSeconds) {
    if (interval.value > 0x7fffffff) {
      throw ArgumentError.value(
          interval.value, 'interval', 'expected an int32');
    }
    return interval.value;
  }
  final seconds = interval.value;
  if (seconds >= secsUntilRollover) {
    final days = ((seconds - secsUntilRollover) ~/ 86400) + 1;
    return days;
  }
  return -(seconds > 0x7fffffff ? 0x7fffffff : seconds);
}

int _roundToUint32(double value) {
  final rounded = value.round();
  if (rounded < 0 || rounded > 0xffffffff) {
    throw ArgumentError.value(value, 'easeFactor', 'expected a uint32');
  }
  return rounded;
}

double _float32(double value) => (Float32List(1)..[0] = value)[0];
