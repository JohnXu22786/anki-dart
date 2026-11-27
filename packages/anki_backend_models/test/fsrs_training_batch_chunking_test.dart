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
  group('sortAndChunkFsrsTrainingItemsByReviewLength', () {
    test('sorts by history length before splitting consecutive batches', () {
      final twoReviews = _weighted(2, 0.2);
      final noReviews = _weighted(0, 0.0);
      final threeReviews = _weighted(3, 0.3);
      final oneReview = _weighted(1, 0.1);
      final fourReviews = _weighted(4, 0.4);

      final batches = sortAndChunkFsrsTrainingItemsByReviewLength(
        [twoReviews, noReviews, threeReviews, oneReview, fourReviews],
        batchSize: 2,
      );

      expect(batches, [
        [noReviews, oneReview],
        [twoReviews, threeReviews],
        [fourReviews],
      ]);
    });

    test('keeps stable ties when equal-length items cross a batch boundary',
        () {
      final longer = _weighted(2, 0.2);
      final firstTie = _weighted(1, 0.11);
      final secondTie = _weighted(1, 0.12);
      final thirdTie = _weighted(1, 0.13);

      final batches = sortAndChunkFsrsTrainingItemsByReviewLength(
        [longer, firstTie, secondTie, thirdTie],
        batchSize: 2,
      );

      expect(batches, [
        [firstTie, secondTie],
        [thirdTie, longer],
      ]);
      expect(batches[0][0], same(firstTie));
      expect(batches[0][1], same(secondTie));
      expect(batches[1][0], same(thirdTie));
    });

    test('uses one batch when the batch size exceeds input length', () {
      final second = _weighted(2, 0.2);
      final first = _weighted(1, 0.1);

      final batches = sortAndChunkFsrsTrainingItemsByReviewLength(
        [second, first],
        batchSize: 3,
      );

      expect(batches, [
        [first, second]
      ]);
    });

    test('returns no batches for empty input', () {
      expect(
        sortAndChunkFsrsTrainingItemsByReviewLength([], batchSize: 2),
        isEmpty,
      );
    });

    test('rejects zero and negative batch sizes', () {
      expect(
        () => sortAndChunkFsrsTrainingItemsByReviewLength([], batchSize: 0),
        throwsArgumentError,
      );
      expect(
        () => sortAndChunkFsrsTrainingItemsByReviewLength([], batchSize: -1),
        throwsArgumentError,
      );
    });

    test('returns immutable batches without mutating input or item values', () {
      final longer = _weighted(2, 0.7);
      final shorter = _weighted(1, 0.4);
      final input = <WeightedFsrsTrainingItem>[longer, shorter];
      final originalInput = List<WeightedFsrsTrainingItem>.of(input);
      final originalReviews = List<FsrsTrainingReview>.of(longer.item.reviews);

      final batches = sortAndChunkFsrsTrainingItemsByReviewLength(
        input,
        batchSize: 1,
      );

      expect(input, orderedEquals(originalInput));
      expect(input[0], same(longer));
      expect(input[1], same(shorter));
      expect(longer.item.reviews, orderedEquals(originalReviews));
      expect(longer.weight, 0.7);
      expect(shorter.weight, 0.4);
      expect(batches[0].single, same(shorter));
      expect(batches[1].single, same(longer));
      expect(
        () => batches.add(<WeightedFsrsTrainingItem>[]),
        throwsUnsupportedError,
      );
      expect(
        () => batches[0].add(_weighted(0, 0.1)),
        throwsUnsupportedError,
      );
    });
  });
}
