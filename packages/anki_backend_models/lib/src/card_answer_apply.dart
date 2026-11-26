// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as scheduler;

import 'card.dart';

/// Applies a generated Normal/New [answer] to [card] without mutating either.
///
/// [desiredRetention] is the caller-resolved Core input. A null value clears
/// the Card field, matching Core's optional input behavior.
Card applyNewCardAnswerState({
  required Card card,
  required scheduler.CardAnswer answer,
  required double? desiredRetention,
}) {
  if (answer.cardId != card.id) {
    throw ArgumentError.value(
      answer.cardId,
      'answer.cardId',
      'must match card.id',
    );
  }
  if (!answer.hasNewState() ||
      answer.newState.whichKind() != scheduler.SchedulingState_Kind.normal ||
      answer.newState.normal.whichKind() !=
          scheduler.SchedulingState_Normal_Kind.new_1) {
    throw ArgumentError.value(
      answer.newState,
      'answer.newState',
      'expected a Normal/New state',
    );
  }

  return Card(
    id: card.id,
    noteId: card.noteId,
    deckId: card.deckId,
    templateIdx: card.templateIdx,
    mtimeSecs: card.mtimeSecs,
    usn: card.usn,
    ctype: CardType.newCard,
    queue: CardQueue.newCard,
    due: answer.newState.normal.new_1.position,
    interval: card.interval,
    easeFactorRaw: card.easeFactorRaw,
    reps: card.reps + 1,
    lapses: card.lapses,
    remainingStepsRaw: card.remainingStepsRaw,
    originalDue: card.originalDue,
    originalDeckId: card.originalDeckId,
    flags: card.flags,
    originalPosition: null,
    memoryState: null,
    desiredRetention: desiredRetention,
    decay: card.decay,
    lastReviewTimeSecs: card.lastReviewTimeSecs,
    customData: answer.newState.customData,
  );
}

/// Applies a generated Normal/Learning [answer] to [card] without mutating
/// either input.
///
/// The caller supplies the resolved Learning [queue] and [due] value. Intraday
/// due timestamps use seconds; interday due values use the collection day.
/// Neither value is calculated or classified here. [desiredRetention] is also
/// passed through as a caller-resolved nullable Core input.
Card applyLearningCardAnswerState({
  required Card card,
  required scheduler.CardAnswer answer,
  required CardQueue queue,
  required int due,
  required double? desiredRetention,
}) {
  if (answer.cardId != card.id) {
    throw ArgumentError.value(
      answer.cardId,
      'answer.cardId',
      'must match card.id',
    );
  }
  if (queue != CardQueue.learn && queue != CardQueue.dayLearn) {
    throw ArgumentError.value(
      queue,
      'queue',
      'expected Learning or day Learning queue',
    );
  }
  if (!answer.hasCurrentState() ||
      answer.currentState.whichKind() !=
          scheduler.SchedulingState_Kind.normal ||
      !_supportsLearningCurrentState(answer.currentState.normal)) {
    throw ArgumentError.value(
      answer.currentState,
      'answer.currentState',
      'expected a Normal/New or Normal/Learning state',
    );
  }
  if (!answer.hasNewState() ||
      answer.newState.whichKind() != scheduler.SchedulingState_Kind.normal ||
      answer.newState.normal.whichKind() !=
          scheduler.SchedulingState_Normal_Kind.learning ||
      !answer.newState.normal.learning.hasRemainingSteps()) {
    throw ArgumentError.value(
      answer.newState,
      'answer.newState',
      'expected a Normal/Learning state with remaining steps',
    );
  }

  final currentNormal = answer.currentState.normal;
  final learning = answer.newState.normal.learning;
  return Card(
    id: card.id,
    noteId: card.noteId,
    deckId: card.deckId,
    templateIdx: card.templateIdx,
    mtimeSecs: card.mtimeSecs,
    usn: card.usn,
    ctype: CardType.learn,
    queue: queue,
    due: due,
    interval: card.interval,
    easeFactorRaw: card.easeFactorRaw,
    reps: card.reps + 1,
    lapses: card.lapses,
    remainingStepsRaw: learning.remainingSteps,
    originalDue: card.originalDue,
    originalDeckId: card.originalDeckId,
    flags: card.flags,
    originalPosition: switch (currentNormal.whichKind()) {
      scheduler.SchedulingState_Normal_Kind.new_1 =>
        currentNormal.new_1.position,
      scheduler.SchedulingState_Normal_Kind.learning => card.originalPosition,
      _ => throw StateError('validated current state changed unexpectedly'),
    },
    memoryState: learning.hasMemoryState()
        ? FsrsMemoryState.fromProto(learning.memoryState)
        : null,
    desiredRetention: desiredRetention,
    decay: card.decay,
    lastReviewTimeSecs: card.lastReviewTimeSecs,
    customData: answer.newState.customData,
  );
}

/// Applies a generated Normal/Review [answer] to [card] without mutating
/// either input. The caller supplies the already-resolved Review due day.
/// [desiredRetention] is the caller-resolved nullable Core input.
Card applyReviewCardAnswerState({
  required Card card,
  required scheduler.CardAnswer answer,
  required int dueDay,
  required double? desiredRetention,
}) {
  if (answer.cardId != card.id) {
    throw ArgumentError.value(
      answer.cardId,
      'answer.cardId',
      'must match card.id',
    );
  }
  if (!answer.hasCurrentState() ||
      answer.currentState.whichKind() !=
          scheduler.SchedulingState_Kind.normal ||
      !_supportsReviewCurrentState(answer.currentState.normal)) {
    throw ArgumentError.value(
      answer.currentState,
      'answer.currentState',
      'expected a Normal/New, Normal/Learning, Normal/Review, or '
          'Normal/Relearning state',
    );
  }
  if (!answer.hasNewState() ||
      answer.newState.whichKind() != scheduler.SchedulingState_Kind.normal ||
      answer.newState.normal.whichKind() !=
          scheduler.SchedulingState_Normal_Kind.review) {
    throw ArgumentError.value(
      answer.newState,
      'answer.newState',
      'expected a Normal/Review state',
    );
  }

  final review = answer.newState.normal.review;
  if (!review.hasScheduledDays() ||
      !review.hasEaseFactor() ||
      !review.hasLapses()) {
    throw ArgumentError.value(
      review,
      'answer.newState.normal.review',
      'must include scheduled days, ease factor, and lapses',
    );
  }

  final currentNormal = answer.currentState.normal;
  return Card(
    id: card.id,
    noteId: card.noteId,
    deckId: card.deckId,
    templateIdx: card.templateIdx,
    mtimeSecs: card.mtimeSecs,
    usn: card.usn,
    ctype: CardType.review,
    queue: CardQueue.review,
    due: dueDay,
    interval: review.scheduledDays,
    easeFactorRaw: (review.easeFactor * 1000).round(),
    reps: card.reps + 1,
    lapses: review.lapses,
    remainingStepsRaw: 0,
    originalDue: card.originalDue,
    originalDeckId: card.originalDeckId,
    flags: card.flags,
    originalPosition: switch (currentNormal.whichKind()) {
      scheduler.SchedulingState_Normal_Kind.new_1 =>
        currentNormal.new_1.position,
      scheduler.SchedulingState_Normal_Kind.learning ||
      scheduler.SchedulingState_Normal_Kind.review ||
      scheduler.SchedulingState_Normal_Kind.relearning =>
        card.originalPosition,
      _ => throw StateError('validated current state changed unexpectedly'),
    },
    memoryState: review.hasMemoryState()
        ? FsrsMemoryState.fromProto(review.memoryState)
        : null,
    desiredRetention: desiredRetention,
    decay: card.decay,
    lastReviewTimeSecs: card.lastReviewTimeSecs,
    customData: answer.newState.hasCustomData()
        ? answer.newState.customData
        : card.customData,
  );
}

/// Applies a generated Normal/Relearning [answer] to [card] without mutating
/// either input. The caller supplies the resolved Relearning queue and due
/// value: intraday timestamps use seconds and interday values use collection
/// days. [desiredRetention] is the caller-resolved nullable Core input.
Card applyRelearningCardAnswerState({
  required Card card,
  required scheduler.CardAnswer answer,
  required CardQueue queue,
  required int due,
  required double? desiredRetention,
}) {
  if (answer.cardId != card.id) {
    throw ArgumentError.value(
      answer.cardId,
      'answer.cardId',
      'must match card.id',
    );
  }
  if (queue != CardQueue.learn && queue != CardQueue.dayLearn) {
    throw ArgumentError.value(
      queue,
      'queue',
      'expected Relearning or day Relearning queue',
    );
  }
  if (!answer.hasCurrentState() ||
      answer.currentState.whichKind() !=
          scheduler.SchedulingState_Kind.normal ||
      !_supportsReviewCurrentState(answer.currentState.normal)) {
    throw ArgumentError.value(
      answer.currentState,
      'answer.currentState',
      'expected a Normal/New, Normal/Learning, Normal/Review, or '
          'Normal/Relearning state',
    );
  }
  if (!answer.hasNewState() ||
      answer.newState.whichKind() != scheduler.SchedulingState_Kind.normal ||
      answer.newState.normal.whichKind() !=
          scheduler.SchedulingState_Normal_Kind.relearning) {
    throw ArgumentError.value(
      answer.newState,
      'answer.newState',
      'expected a Normal/Relearning state',
    );
  }

  final relearning = answer.newState.normal.relearning;
  if (!relearning.hasReview() || !relearning.hasLearning()) {
    throw ArgumentError.value(
      relearning,
      'answer.newState.normal.relearning',
      'must include paired Review and Learning states',
    );
  }
  final review = relearning.review;
  final learning = relearning.learning;
  if (!review.hasScheduledDays() ||
      !review.hasEaseFactor() ||
      !review.hasLapses()) {
    throw ArgumentError.value(
      review,
      'answer.newState.normal.relearning.review',
      'must include scheduled days, ease factor, and lapses',
    );
  }
  if (!learning.hasRemainingSteps()) {
    throw ArgumentError.value(
      learning,
      'answer.newState.normal.relearning.learning',
      'must include remaining steps',
    );
  }

  final currentNormal = answer.currentState.normal;
  return Card(
    id: card.id,
    noteId: card.noteId,
    deckId: card.deckId,
    templateIdx: card.templateIdx,
    mtimeSecs: card.mtimeSecs,
    usn: card.usn,
    ctype: CardType.relearn,
    queue: queue,
    due: due,
    interval: review.scheduledDays,
    easeFactorRaw: (review.easeFactor * 1000).round(),
    reps: card.reps + 1,
    lapses: review.lapses,
    remainingStepsRaw: learning.remainingSteps,
    originalDue: card.originalDue,
    originalDeckId: card.originalDeckId,
    flags: card.flags,
    originalPosition:
        currentNormal.whichKind() == scheduler.SchedulingState_Normal_Kind.new_1
            ? currentNormal.new_1.position
            : card.originalPosition,
    memoryState: learning.hasMemoryState()
        ? FsrsMemoryState.fromProto(learning.memoryState)
        : null,
    desiredRetention: desiredRetention,
    decay: card.decay,
    lastReviewTimeSecs: card.lastReviewTimeSecs,
    customData: answer.newState.hasCustomData()
        ? answer.newState.customData
        : card.customData,
  );
}

bool _supportsLearningCurrentState(scheduler.SchedulingState_Normal normal) =>
    normal.whichKind() == scheduler.SchedulingState_Normal_Kind.new_1 ||
    normal.whichKind() == scheduler.SchedulingState_Normal_Kind.learning;

bool _supportsReviewCurrentState(scheduler.SchedulingState_Normal normal) =>
    normal.whichKind() == scheduler.SchedulingState_Normal_Kind.new_1 ||
    normal.whichKind() == scheduler.SchedulingState_Normal_Kind.learning ||
    normal.whichKind() == scheduler.SchedulingState_Normal_Kind.review ||
    normal.whichKind() == scheduler.SchedulingState_Normal_Kind.relearning;
