// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'card.dart';
import 'ids.dart';
import 'package:fixnum/fixnum.dart';

enum ReviewQueueEntryKind { newCard, learning, review }

/// A queue entry that keeps only the scheduling values needed by the queue.
class ReviewQueueEntry {
  const ReviewQueueEntry({
    required this.id,
    required this.mtime,
    required this.kind,
    this.due,
    this.reps = 0,
  });

  factory ReviewQueueEntry.fromCard(Card card) {
    final kind = switch (card.queue) {
      CardQueue.learn ||
      CardQueue.previewRepeat =>
        ReviewQueueEntryKind.learning,
      CardQueue.newCard => ReviewQueueEntryKind.newCard,
      CardQueue.review || CardQueue.dayLearn => ReviewQueueEntryKind.review,
      CardQueue.suspended ||
      CardQueue.schedBuried ||
      CardQueue.userBuried =>
        throw ArgumentError.value(card.queue, 'card.queue',
            'suspended and buried cards cannot enter a review queue'),
    };

    return ReviewQueueEntry(
      id: card.id,
      mtime: card.mtimeSecs,
      kind: kind,
      due: kind == ReviewQueueEntryKind.learning ? Int64(card.due) : null,
      reps: kind == ReviewQueueEntryKind.learning ? card.reps : 0,
    );
  }

  final CardId id;
  final TimestampSecs mtime;
  final ReviewQueueEntryKind kind;
  final TimestampSecs? due;
  final int reps;
}

/// The intraday portion of the review queue, with all time inputs supplied by
/// the caller so the model has no clock or collection dependency.
class LearningQueueEntry {
  const LearningQueueEntry({
    required this.due,
    required this.id,
    required this.mtime,
    required this.reps,
  });

  final TimestampSecs due;
  final CardId id;
  final TimestampSecs mtime;
  final int reps;
}

class LearningQueue {
  LearningQueue({
    required int nowSecs,
    required int learningCutoffSecs,
    required this.learnAheadSecs,
    required int nextDayAtSecs,
    required Iterable<LearningQueueEntry> entries,
    this.mainQueueIsEmpty = false,
  })  : nowSecs = Int64(nowSecs),
        learningCutoffSecs = Int64(learningCutoffSecs),
        nextDayAtSecs = Int64(nextDayAtSecs),
        entries = List.of(entries)..sort(_compareLearningEntries) {
    learningCount =
        this.entries.where((entry) => entry.due <= learnAheadCutoffSecs).length;
  }

  final TimestampSecs nowSecs;
  TimestampSecs learningCutoffSecs;
  final int learnAheadSecs;
  final TimestampSecs nextDayAtSecs;
  final bool mainQueueIsEmpty;
  final List<LearningQueueEntry> entries;
  late int learningCount;

  TimestampSecs get learnAheadCutoffSecs =>
      learningCutoffSecs + Int64(learnAheadSecs);

  Iterable<LearningQueueEntry> get intradayNow =>
      entries.where((entry) => entry.due <= learningCutoffSecs);

  Iterable<LearningQueueEntry> get intradayAhead => entries.where(
        (entry) =>
            entry.due > learningCutoffSecs && entry.due <= learnAheadCutoffSecs,
      );

  /// Requeues an answered intraday learning card when it remains due today.
  /// Returns the inserted entry, or null if the card is not intraday learning
  /// or its due time reaches the next-day boundary.
  LearningQueueEntry? requeueAnswered(Card card) {
    if (!card.isIntradayLearning || Int64(card.due) >= nextDayAtSecs) {
      return null;
    }

    var entry = LearningQueueEntry(
      due: Int64(card.due),
      id: card.id,
      mtime: card.mtimeSecs,
      reps: card.reps,
    );
    if (entry.due <= learnAheadCutoffSecs &&
        mainQueueIsEmpty &&
        entries.isNotEmpty) {
      final next = entries.first;
      final nextDuePlusOne = next.due + Int64.ONE;
      if (next.due >= entry.due && nextDuePlusOne < learnAheadCutoffSecs) {
        entry = LearningQueueEntry(
          due: nextDuePlusOne,
          id: entry.id,
          mtime: entry.mtime,
          reps: entry.reps,
        );
      }
    }

    final index = entries.indexWhere(
      (existing) => _compareLearningEntries(existing, entry) > 0,
    );
    if (entry.due <= learnAheadCutoffSecs) {
      learningCount++;
    }
    entries.insert(index < 0 ? entries.length : index, entry);
    return entry;
  }
}

int _compareLearningEntries(LearningQueueEntry one, LearningQueueEntry two) {
  final oneNeverAttempted = one.reps == 0;
  final twoNeverAttempted = two.reps == 0;
  if (oneNeverAttempted != twoNeverAttempted) {
    return oneNeverAttempted ? 1 : -1;
  }
  final dueComparison = one.due.compareTo(two.due);
  return dueComparison != 0 ? dueComparison : one.id.compareTo(two.id);
}

/// Mixes two queues using Core's ratio-based selection and Float32 arithmetic.
List<T> interspersedQueues<T>(List<T> one, List<T> two) {
  final result = <T>[];
  final ratio = _float32(
    _float32((one.length + 1).toDouble()) /
        _float32((two.length + 1).toDouble()),
  );
  var oneIndex = 0;
  var twoIndex = 0;

  while (oneIndex < one.length && twoIndex < two.length) {
    final relativeTwoIndex =
        _float32(_float32((twoIndex + 1).toDouble()) * ratio);
    final relativeOneIndex = _float32((oneIndex + 1).toDouble());
    if (relativeTwoIndex < relativeOneIndex) {
      result.add(two[twoIndex++]);
    } else {
      result.add(one[oneIndex++]);
    }
  }
  result
    ..addAll(one.skip(oneIndex))
    ..addAll(two.skip(twoIndex));
  return result;
}

double _float32(double value) {
  final narrowed = Float32List(1)..[0] = value;
  return narrowed[0];
}
