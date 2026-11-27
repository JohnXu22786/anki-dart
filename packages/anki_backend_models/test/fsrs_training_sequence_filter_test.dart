// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

WeightedFsrsTrainingItem _weighted(int reviewCount, double weight) =>
    WeightedFsrsTrainingItem(
      item: FsrsTrainingItem(
        reviews: List<FsrsTrainingReview>.generate(
          reviewCount,
          (index) => FsrsTrainingReview(rating: index + 1, deltaT: index),
        ),
      ),
      weight: weight,
    );

void main() {
  group('filterFsrsTrainingItemsByMaxSequenceLength', () {
    test('filters boundaries while preserving identity, order, and weights',
        () {
      final exactLimitFirst = _weighted(3, 0.25);
      final overLimit = _weighted(4, 0.5);
      final shorter = _weighted(1, 0.75);
      final exactLimitSecond = _weighted(3, 1.0);

      final result = filterFsrsTrainingItemsByMaxSequenceLength([
        exactLimitFirst,
        overLimit,
        shorter,
        exactLimitSecond,
      ], maxSequenceLength: 3);
      expect(result[0], same(exactLimitFirst));
      expect(result[1], same(shorter));
      expect(result[2], same(exactLimitSecond));
      expect(result.map((item) => item.weight), [0.25, 0.75, 1.0]);

      final short = _weighted(1, 0.1);
      final long = _weighted(3, 0.3);
      expect(filterFsrsTrainingItemsByMaxSequenceLength([]), isEmpty);
      expect(
        filterFsrsTrainingItemsByMaxSequenceLength([short, long],
            maxSequenceLength: 3),
        [short, long],
      );
      expect(
        filterFsrsTrainingItemsByMaxSequenceLength([long],
            maxSequenceLength: 1),
        isEmpty,
      );
      expect(
        filterFsrsTrainingItemsByMaxSequenceLength(
                [_weighted(64, 0.64), _weighted(65, 0.65)])
            .map((item) => item.item.reviews.length),
        [64],
      );
    });

    test('rejects nonpositive limits and returns immutable copies', () {
      final item = _weighted(2, 0.5);
      final input = <WeightedFsrsTrainingItem>[item];
      final originalInput = List<WeightedFsrsTrainingItem>.of(input);

      expect(
        () => filterFsrsTrainingItemsByMaxSequenceLength(input,
            maxSequenceLength: 0),
        throwsArgumentError,
      );
      expect(
        () => filterFsrsTrainingItemsByMaxSequenceLength(input,
            maxSequenceLength: -1),
        throwsArgumentError,
      );

      final result = filterFsrsTrainingItemsByMaxSequenceLength(input);
      expect(input, orderedEquals(originalInput));
      expect(input.single, same(item));
      expect(item.weight, 0.5);
      expect(() => result.add(_weighted(1, 0.25)), throwsUnsupportedError);
    });
  });
}
