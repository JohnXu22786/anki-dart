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
  group('sortFsrsTrainingItemsByReviewLength', () {
    test('sorts ascending and keeps equal-length item identities stable', () {
      final twoReviewsFirst = _weighted(2, 0.2);
      final oneReview = _weighted(1, 0.1);
      final twoReviewsSecond = _weighted(2, 0.22);
      final threeReviews = _weighted(3, 0.3);

      final sorted = sortFsrsTrainingItemsByReviewLength([
        twoReviewsFirst,
        oneReview,
        twoReviewsSecond,
        threeReviews,
      ]);

      expect(
          sorted, [oneReview, twoReviewsFirst, twoReviewsSecond, threeReviews]);
      expect(sorted.map((item) => item.item.reviews.length), [1, 2, 2, 3]);
      expect(sorted.map((item) => item.weight), [0.1, 0.2, 0.22, 0.3]);
      expect(sorted[1], same(twoReviewsFirst));
      expect(sorted[2], same(twoReviewsSecond));
    });

    test('preserves sorted input and orders reverse-sorted input', () {
      final short = _weighted(1, 0.1);
      final middle = _weighted(2, 0.2);
      final long = _weighted(3, 0.3);

      expect(sortFsrsTrainingItemsByReviewLength([short, middle, long]),
          [short, middle, long]);
      expect(sortFsrsTrainingItemsByReviewLength([long, middle, short]),
          [short, middle, long]);
    });

    test('handles empty and singleton input', () {
      final item = _weighted(1, 0.1);

      expect(sortFsrsTrainingItemsByReviewLength([]), isEmpty);
      final result = sortFsrsTrainingItemsByReviewLength([item]);
      expect(result, hasLength(1));
      expect(result.single, same(item));
    });

    test('returns an immutable copy without changing caller input', () {
      final longer = _weighted(3, 0.3);
      final shorter = _weighted(1, 0.1);
      final input = <WeightedFsrsTrainingItem>[longer, shorter];
      final originalInput = List<WeightedFsrsTrainingItem>.of(input);
      final originalLongReviews =
          List<FsrsTrainingReview>.of(longer.item.reviews);
      final originalShortReviews =
          List<FsrsTrainingReview>.of(shorter.item.reviews);

      final result = sortFsrsTrainingItemsByReviewLength(input);

      expect(input, orderedEquals(originalInput));
      expect(input[0], same(longer));
      expect(input[1], same(shorter));
      expect(longer.item.reviews, orderedEquals(originalLongReviews));
      expect(shorter.item.reviews, orderedEquals(originalShortReviews));
      expect(longer.weight, 0.3);
      expect(shorter.weight, 0.1);
      expect(() => result.add(_weighted(1, 0.4)), throwsUnsupportedError);
    });
  });
}
