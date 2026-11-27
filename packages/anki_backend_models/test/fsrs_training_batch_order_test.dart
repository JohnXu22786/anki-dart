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
  group('orderFsrsTrainingBatchesByIndices', () {
    test('returns batches in identity and supplied permutation order', () {
      final first = _batch(10);
      final second = _batch(20);
      final third = _batch(30);
      final batches = [first, second, third];

      final identity = orderFsrsTrainingBatchesByIndices(
        batches: batches,
        indices: [0, 1, 2],
      );
      final shuffled = orderFsrsTrainingBatchesByIndices(
        batches: batches,
        indices: [2, 0, 1],
      );

      expect(identity, [first, second, third]);
      expect(shuffled, [third, first, second]);
      expect(shuffled[0], same(third));
      expect(shuffled[1], same(first));
      expect(shuffled[2], same(second));
      expect(batches, [first, second, third]);
    });

    test('returns immutable empty and singleton results', () {
      final empty = orderFsrsTrainingBatchesByIndices(
        batches: [],
        indices: [],
      );
      final batch = _batch(10);
      final single = orderFsrsTrainingBatchesByIndices(
        batches: [batch],
        indices: [0],
      );

      expect(empty, isEmpty);
      expect(() => empty.add(batch), throwsUnsupportedError);
      expect(single, [batch]);
      expect(single.single, same(batch));
      expect(() => single[0] = batch, throwsUnsupportedError);
    });

    test('preserves mutable source lists and returns a separate result', () {
      final first = _batch(10);
      final second = _batch(20);
      final batches = [first, second];
      final indices = [1, 0];

      final ordered = orderFsrsTrainingBatchesByIndices(
        batches: batches,
        indices: indices,
      );

      expect(identical(ordered, batches), isFalse);
      expect(ordered, [second, first]);
      expect(batches, [first, second]);
      expect(indices, [1, 0]);
      expect(() => ordered.add(first), throwsUnsupportedError);
      expect(() => ordered[0] = first, throwsUnsupportedError);
    });

    test(
        'rejects incomplete, duplicate, negative, high, and wrong-length indexes',
        () {
      final batches = [_batch(10), _batch(20), _batch(30)];

      for (final malformed in [
        [0, 1],
        [0, 1, 1],
        [-1, 1, 2],
        [0, 1, 3],
        [0, 1, 2, 0],
      ]) {
        expect(
          () => orderFsrsTrainingBatchesByIndices(
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
