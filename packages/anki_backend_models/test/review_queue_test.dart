// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

Card _card({
  int id = 1,
  CardQueue queue = CardQueue.learn,
  int due = 0,
  int reps = 0,
}) =>
    Card(
      id: Int64(id),
      mtimeSecs: Int64(id * 10),
      queue: queue,
      due: due,
      reps: reps,
    );

LearningQueueEntry _learning({
  required int id,
  required int due,
  int reps = 0,
}) =>
    LearningQueueEntry(
      id: Int64(id),
      due: Int64(due),
      mtime: Int64(id * 10),
      reps: reps,
    );

void main() {
  group('ReviewQueueEntry', () {
    test('maps queue kinds and excludes suspended or buried cards', () {
      expect(ReviewQueueEntry.fromCard(_card(queue: CardQueue.learn)).kind,
          ReviewQueueEntryKind.learning);
      expect(
          ReviewQueueEntry.fromCard(_card(queue: CardQueue.previewRepeat)).kind,
          ReviewQueueEntryKind.learning);
      expect(ReviewQueueEntry.fromCard(_card(queue: CardQueue.newCard)).kind,
          ReviewQueueEntryKind.newCard);
      expect(ReviewQueueEntry.fromCard(_card(queue: CardQueue.review)).kind,
          ReviewQueueEntryKind.review);
      expect(ReviewQueueEntry.fromCard(_card(queue: CardQueue.dayLearn)).kind,
          ReviewQueueEntryKind.review);
      for (final queue in [
        CardQueue.suspended,
        CardQueue.schedBuried,
        CardQueue.userBuried,
      ]) {
        expect(() => ReviewQueueEntry.fromCard(_card(queue: queue)),
            throwsArgumentError);
      }
    });
  });

  group('LearningQueue', () {
    test('prioritizes attempted cards and applies inclusive cutoffs', () {
      final queue = LearningQueue(
        nowSecs: 100,
        learningCutoffSecs: 100,
        learnAheadSecs: 20,
        nextDayAtSecs: 1000,
        entries: [
          _learning(id: 4, due: 100),
          _learning(id: 3, due: 110),
          _learning(id: 2, due: 90, reps: 1),
          _learning(id: 1, due: 90, reps: 2),
        ],
      );

      expect(queue.entries.map((entry) => entry.id.toInt()), [1, 2, 4, 3]);
      expect(queue.intradayNow.map((entry) => entry.id.toInt()), [1, 2, 4]);
      expect(queue.intradayAhead.map((entry) => entry.id.toInt()), [3]);
    });

    test('requeues eligible cards and defers immediate repeats when collapsed',
        () {
      final queue = LearningQueue(
        nowSecs: 100,
        learningCutoffSecs: 100,
        learnAheadSecs: 30,
        nextDayAtSecs: 200,
        mainQueueIsEmpty: true,
        entries: [_learning(id: 2, due: 101, reps: 1)],
      );

      final requeued = queue.requeueAnswered(_card(
        id: 1,
        queue: CardQueue.learn,
        due: 101,
        reps: 2,
      ));
      expect(requeued?.due.toInt(), 102);
      expect(requeued?.reps, 2);
      expect(queue.learningCount, 2);
      expect(queue.entries.map((entry) => entry.id.toInt()), [2, 1]);

      expect(
        queue.requeueAnswered(_card(
          id: 3,
          queue: CardQueue.previewRepeat,
          due: 200,
          reps: 3,
        )),
        isNull,
      );
      expect(
        queue.requeueAnswered(_card(
          id: 4,
          queue: CardQueue.review,
          due: 110,
          reps: 3,
        )),
        isNull,
      );
      expect(queue.learningCount, 2);
    });

    test('preserves exact requeue due when queue is not collapsed', () {
      final queue = LearningQueue(
        nowSecs: 100,
        learningCutoffSecs: 100,
        learnAheadSecs: 10,
        nextDayAtSecs: 200,
        mainQueueIsEmpty: false,
        entries: [],
      );
      expect(
        queue.requeueAnswered(_card(due: 105, reps: 1))?.due,
        Int64(105),
      );
      expect(queue.learningCount, 1);
    });
  });

  group('interspersedQueues', () {
    test('matches Core selection for equal, longer, shorter, and uneven lists',
        () {
      expect(
          interspersedQueues([1, 2, 3], [11, 22, 33]), [1, 11, 2, 22, 3, 33]);
      expect(interspersedQueues([1, 2, 3], [11, 22]), [1, 11, 2, 22, 3]);
      expect(interspersedQueues([1, 2, 3], [11, 22, 33, 44, 55, 66]),
          [11, 1, 22, 33, 2, 44, 55, 3, 66]);
      expect(interspersedQueues([1, 2, 3], [11, 22, 33, 44, 55, 66, 77, 88]),
          [11, 22, 1, 33, 44, 2, 55, 66, 3, 77, 88]);
    });

    test('returns the other list when either queue is empty', () {
      expect(interspersedQueues<int>([], []), isEmpty);
      expect(interspersedQueues([1, 2, 3], []), [1, 2, 3]);
      expect(interspersedQueues([], [11, 22]), [11, 22]);
    });
  });
}
