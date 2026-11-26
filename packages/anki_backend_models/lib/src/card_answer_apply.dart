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
