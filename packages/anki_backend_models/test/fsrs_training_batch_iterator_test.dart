// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

FsrsTrainingBatch _batch(double deltaT) => FsrsTrainingBatch(
      timeHistories: const [],
      ratingHistories: const [],
      deltaTs: [deltaT],
      labels: const [1],
      weights: const [1],
    );

void main() {
  group('FsrsTrainingBatchIterator', () {
    test('traverses in supplied permutation order and reports cursor progress',
        () {
      final first = _batch(10);
      final second = _batch(20);
      final third = _batch(30);
      final iterator = FsrsTrainingBatchIterator(
        batches: [first, second, third],
        indices: [2, 0, 1],
      );

      expect(iterator.progress.itemsProcessed, 0);
      expect(iterator.progress.itemsTotal, 3);
      expect(iterator.progress.isComplete, isFalse);
      expect(iterator.nextBatch(), same(third));
      expect(iterator.progress.itemsProcessed, 1);
      expect(iterator.progress.itemsTotal, 3);
      expect(iterator.nextBatch(), same(first));
      expect(iterator.progress.itemsProcessed, 2);
      expect(iterator.nextBatch(), same(second));
      expect(iterator.progress.itemsProcessed, 3);
      expect(iterator.progress.isComplete, isTrue);
    });

    test('remains exhausted after repeated nextBatch calls', () {
      final batch = _batch(10);
      final iterator = FsrsTrainingBatchIterator(
        batches: [batch],
        indices: [0],
      );

      expect(iterator.nextBatch(), same(batch));
      expect(iterator.nextBatch(), isNull);
      expect(iterator.nextBatch(), isNull);
      expect(iterator.progress.itemsProcessed, 1);
      expect(iterator.progress.itemsTotal, 1);
      expect(iterator.progress.isComplete, isTrue);
    });

    test('empty and singleton inputs have correct initial progress', () {
      final empty = FsrsTrainingBatchIterator(batches: [], indices: []);
      expect(empty.progress.itemsProcessed, 0);
      expect(empty.progress.itemsTotal, 0);
      expect(empty.progress.isComplete, isTrue);
      expect(empty.nextBatch(), isNull);

      final batch = _batch(10);
      final single = FsrsTrainingBatchIterator(
        batches: [batch],
        indices: [0],
      );
      expect(single.progress.itemsProcessed, 0);
      expect(single.progress.itemsTotal, 1);
      expect(single.progress.isComplete, isFalse);
    });

    test('uses immutable snapshots without mutating caller lists or batches',
        () {
      final first = _batch(10);
      final second = _batch(20);
      final batches = [first, second];
      final indices = [1, 0];
      final iterator = FsrsTrainingBatchIterator(
        batches: batches,
        indices: indices,
      );
      final initialProgress = iterator.progress;

      expect(batches, [first, second]);
      expect(indices, [1, 0]);
      batches[0] = _batch(99);
      indices[0] = 0;

      expect(iterator.nextBatch(), same(second));
      expect(initialProgress.itemsProcessed, 0);
      expect(iterator.progress.itemsProcessed, 1);
      expect(iterator.nextBatch(), same(first));
      expect(iterator.progress.itemsTotal, 2);
      expect(indices, [0, 0]);
    });

    test('rejects invalid batch permutations', () {
      final batches = [_batch(10), _batch(20), _batch(30)];
      for (final malformed in [
        [0, 1],
        [0, 1, 1],
        [-1, 1, 2],
        [0, 1, 3],
        [0, 1, 2, 0],
      ]) {
        expect(
          () => FsrsTrainingBatchIterator(
            batches: batches,
            indices: malformed,
          ),
          throwsArgumentError,
          reason: 'indices $malformed must not be accepted',
        );
      }
    });
  });
}
