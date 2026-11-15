// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:anki_backend_protocol/anki/cards.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';

import 'ids.dart';

/// Card type values persisted by Anki Core.
enum CardType {
  newCard(0),
  learn(1),
  review(2),
  relearn(3);

  const CardType(this.value);
  final int value;

  static CardType fromRaw(int raw) => switch (raw) {
        0 => CardType.newCard,
        1 => CardType.learn,
        2 => CardType.review,
        3 => CardType.relearn,
        _ => throw const InvalidModelValue('invalid card type'),
      };
}

/// Card queue values persisted by Anki Core.
enum CardQueue {
  newCard(0),
  learn(1),
  review(2),
  dayLearn(3),
  previewRepeat(4),
  suspended(-1),
  schedBuried(-2),
  userBuried(-3);

  const CardQueue(this.value);
  final int value;

  CardQueueNumber get number => switch (this) {
        CardQueue.newCard => CardQueueNumber.newCard,
        CardQueue.learn || CardQueue.previewRepeat => CardQueueNumber.learning,
        CardQueue.dayLearn || CardQueue.review => CardQueueNumber.review,
        CardQueue.suspended ||
        CardQueue.schedBuried ||
        CardQueue.userBuried =>
          CardQueueNumber.invalid,
      };

  static CardQueue fromRaw(int raw) => switch (raw) {
        0 => CardQueue.newCard,
        1 => CardQueue.learn,
        2 => CardQueue.review,
        3 => CardQueue.dayLearn,
        4 => CardQueue.previewRepeat,
        -1 => CardQueue.suspended,
        -2 => CardQueue.schedBuried,
        -3 => CardQueue.userBuried,
        _ => throw const InvalidModelValue('invalid card queue'),
      };
}

enum CardQueueNumber { newCard, learning, review, invalid }

/// Error raised when an upstream enum value cannot be represented.
class InvalidModelValue implements Exception {
  const InvalidModelValue(this.message);
  final String message;

  @override
  String toString() => message;
}

class FsrsMemoryState {
  FsrsMemoryState({required double stability, required double difficulty})
      : stability = _toFloat32(stability),
        difficulty = _toFloat32(difficulty);

  final double stability;
  final double difficulty;

  factory FsrsMemoryState.fromProto(proto.FsrsMemoryState value) =>
      FsrsMemoryState(stability: value.stability, difficulty: value.difficulty);

  proto.FsrsMemoryState toProto() => proto.FsrsMemoryState(
        stability: stability,
        difficulty: difficulty,
      );
}

/// An Anki card's stored scheduling and review values.
class Card {
  Card({
    Int64 id = Int64.ZERO,
    Int64 noteId = Int64.ZERO,
    Int64 deckId = Int64.ZERO,
    int templateIdx = 0,
    Int64 mtimeSecs = Int64.ZERO,
    int usn = 0,
    CardType ctype = CardType.newCard,
    CardQueue queue = CardQueue.newCard,
    int due = 0,
    int interval = 0,
    int easeFactorRaw = 0,
    int reps = 0,
    int lapses = 0,
    int remainingStepsRaw = 0,
    int originalDue = 0,
    Int64 originalDeckId = Int64.ZERO,
    int flags = 0,
    int? originalPosition,
    FsrsMemoryState? memoryState,
    double? desiredRetention,
    double? decay,
    Int64? lastReviewTimeSecs,
    String customData = '',
  })  : id = id,
        noteId = noteId,
        deckId = deckId,
        templateIdx = templateIdx.toUnsigned(16),
        mtimeSecs = mtimeSecs,
        usn = usn.toSigned(32),
        ctype = ctype,
        queue = queue,
        due = due.toSigned(32),
        interval = interval.toUnsigned(32),
        easeFactorRaw = easeFactorRaw.toUnsigned(16),
        reps = reps.toUnsigned(32),
        lapses = lapses.toUnsigned(32),
        remainingStepsRaw = remainingStepsRaw.toUnsigned(32),
        originalDue = originalDue.toSigned(32),
        originalDeckId = originalDeckId,
        flags = flags.toUnsigned(8),
        originalPosition = originalPosition?.toUnsigned(32),
        memoryState = memoryState,
        desiredRetention =
            desiredRetention == null ? null : _toFloat32(desiredRetention),
        decay = decay == null ? null : _toFloat32(decay),
        lastReviewTimeSecs = lastReviewTimeSecs,
        customData = customData;

  factory Card.newCard({
    required Int64 noteId,
    required int templateIdx,
    required Int64 deckId,
    required int due,
  }) =>
      Card(
        noteId: noteId,
        templateIdx: templateIdx,
        deckId: deckId,
        due: due,
      );

  final CardId id;
  final NoteId noteId;
  final Int64 deckId;
  final int templateIdx;
  final Int64 mtimeSecs;
  final int usn;
  final CardType ctype;
  final CardQueue queue;
  final int due;
  final int interval;
  final int easeFactorRaw;
  final int reps;
  final int lapses;
  final int remainingStepsRaw;
  final int originalDue;
  final Int64 originalDeckId;
  final int flags;
  final int? originalPosition;
  final FsrsMemoryState? memoryState;
  final double? desiredRetention;
  final double? decay;
  final Int64? lastReviewTimeSecs;
  final String customData;

  int get remainingSteps => remainingStepsRaw % 1000;
  double get easeFactor => _toFloat32(easeFactorRaw / 1000.0);
  bool get isIntradayLearning =>
      queue == CardQueue.learn || queue == CardQueue.previewRepeat;

  factory Card.fromProto(proto.Card value) {
    final ctype = CardType.fromRaw(value.ctype % 256);
    final queueByte = value.queue % 256;
    final queue =
        CardQueue.fromRaw(queueByte >= 128 ? queueByte - 256 : queueByte);
    return Card(
      id: value.id,
      noteId: value.noteId,
      deckId: value.deckId,
      templateIdx: value.templateIdx & 0xffff,
      mtimeSecs: value.mtimeSecs,
      usn: value.usn,
      ctype: ctype,
      queue: queue,
      due: value.due,
      interval: value.interval,
      easeFactorRaw: value.easeFactor & 0xffff,
      reps: value.reps,
      lapses: value.lapses,
      remainingStepsRaw: value.remainingSteps,
      originalDue: value.originalDue,
      originalDeckId: value.originalDeckId,
      flags: value.flags & 0xff,
      originalPosition:
          value.hasOriginalPosition() ? value.originalPosition : null,
      memoryState: value.hasMemoryState()
          ? FsrsMemoryState.fromProto(value.memoryState)
          : null,
      desiredRetention:
          value.hasDesiredRetention() ? value.desiredRetention : null,
      decay: value.hasDecay() ? value.decay : null,
      lastReviewTimeSecs:
          value.hasLastReviewTimeSecs() ? value.lastReviewTimeSecs : null,
      customData: value.customData,
    );
  }

  proto.Card toProto() {
    final value = proto.Card(
      id: id,
      noteId: noteId,
      deckId: deckId,
      templateIdx: templateIdx,
      mtimeSecs: mtimeSecs,
      usn: usn,
      ctype: ctype.value,
      queue: queue.value,
      due: due,
      interval: interval,
      easeFactor: easeFactorRaw,
      reps: reps,
      lapses: lapses,
      remainingSteps: remainingStepsRaw,
      originalDue: originalDue,
      originalDeckId: originalDeckId,
      flags: flags,
      customData: customData,
    );
    if (originalPosition != null) value.originalPosition = originalPosition!;
    if (memoryState != null) value.memoryState = memoryState!.toProto();
    if (desiredRetention != null) value.desiredRetention = desiredRetention!;
    if (decay != null) value.decay = decay!;
    if (lastReviewTimeSecs != null) {
      value.lastReviewTimeSecs = lastReviewTimeSecs!;
    }
    return value;
  }
}

double _toFloat32(double value) {
  final singlePrecision = Float32List(1);
  singlePrecision[0] = value;
  return singlePrecision[0];
}
