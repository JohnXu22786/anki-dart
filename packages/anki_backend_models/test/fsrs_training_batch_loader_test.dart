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

List<FsrsTrainingBatch> _drain(FsrsTrainingBatchIterator iterator) {
  final batches = <FsrsTrainingBatch>[];
  while (true) {
    final batch = iterator.nextBatch();
    if (batch == null) break;
    batches.add(batch);
  }
  return batches;
}

void main() {
  group('FsrsTrainingBatchLoader', () {
    test('uses successive permutations from one seeded shuffle stream', () {
      final batches = List.generate(8, (index) => _batch(index.toDouble()));
      final loader = FsrsTrainingBatchLoader(batches, BigInt.from(42));
      final expectedShuffle = FsrsTrainingBatchShuffle(BigInt.from(42));

      for (var iteration = 0; iteration < 2; iteration++) {
        final expectedIndices = expectedShuffle.nextPermutation(batches.length);
        final actual = _drain(loader.iterator());

        expect(actual.length, batches.length);
        for (var index = 0; index < expectedIndices.length; index++) {
          expect(actual[index], same(batches[expectedIndices[index]]));
        }
      }
    });

    test('each iterator has independent cursor and exhaustion state', () {
      final batches = [_batch(1), _batch(2), _batch(3)];
      final loader = FsrsTrainingBatchLoader(batches, BigInt.from(7));
      final first = loader.iterator();
      final second = loader.iterator();

      expect(first.progress.itemsProcessed, 0);
      expect(second.progress.itemsProcessed, 0);
      expect(first.nextBatch(), isNotNull);
      expect(first.progress.itemsProcessed, 1);
      expect(second.progress.itemsProcessed, 0);

      _drain(first);
      expect(first.nextBatch(), isNull);
      expect(first.progress.isComplete, isTrue);
      expect(second.progress.itemsProcessed, 0);
      expect(_drain(second), hasLength(batches.length));
      expect(second.nextBatch(), isNull);
      expect(second.progress.isComplete, isTrue);
    });

    test('empty and singleton datasets produce valid identity traversals', () {
      final seed = BigInt.from(91);
      final batches = [_batch(12)];
      final loader = FsrsTrainingBatchLoader(batches, seed);
      final expectedShuffle = FsrsTrainingBatchShuffle(seed)
        ..nextPermutation(0)
        ..nextPermutation(1)
        ..nextPermutation(0)
        ..nextPermutation(1);

      for (var iteration = 0; iteration < 4; iteration++) {
        final iterator = loader.iterator();
        expect(iterator.nextBatch(), same(batches.single));
        expect(iterator.nextBatch(), isNull);
      }
      expect(
        expectedShuffle.nextPermutation(8),
        FsrsTrainingBatchShuffle(seed).nextPermutation(8),
      );

      final emptyLoader = FsrsTrainingBatchLoader([], seed);
      final empty = emptyLoader.iterator();
      expect(empty.progress.itemsTotal, 0);
      expect(empty.progress.isComplete, isTrue);
      expect(empty.nextBatch(), isNull);
      expect(emptyLoader.iterator().nextBatch(), isNull);
    });

    test('snapshots the caller list and never mutates batch values', () {
      final first = _batch(10);
      final second = _batch(20);
      final callerBatches = [first, second];
      final loader = FsrsTrainingBatchLoader(callerBatches, BigInt.from(3));

      callerBatches
        ..clear()
        ..add(_batch(99));

      final traversal = _drain(loader.iterator());
      expect(traversal, hasLength(2));
      expect(traversal, contains(same(first)));
      expect(traversal, contains(same(second)));
      expect(first.deltaTs, [10]);
      expect(second.deltaTs, [20]);
    });
  });
}
