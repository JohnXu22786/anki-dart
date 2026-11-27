// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

FsrsTrainingItem _item(int rating, List<int> deltas) => FsrsTrainingItem(
      reviews: List.unmodifiable([
        for (var index = 0; index < deltas.length; index++)
          FsrsTrainingReview(
            rating: index == 0 ? rating : (rating % 4) + 1,
            deltaT: deltas[index],
          ),
      ]),
    );

List<FsrsTrainingItem> _group(int rating, int delta, int count,
        {bool longHistory = false}) =>
    [
      for (var index = 0; index < count; index++)
        _item(rating, longHistory ? [0, delta, 1] : [0, delta]),
    ];

void main() {
  group('prepareFsrsTrainingData', () {
    test('partitions exactly one-long-term-review initialization items', () {
      final oneLongTerm = _item(3, [0, 5]);
      final twoLongTerm = _item(4, [0, 5, 2]);
      final items = [oneLongTerm, twoLongTerm];

      final result = prepareFsrsTrainingData(items, filterOutliers: false);

      expect(result.initializationItems, [oneLongTerm]);
      expect(result.trainingItems, [twoLongTerm]);
    });

    test('bypasses outlier filtering explicitly when false', () {
      final items = [
        ..._group(1, 1, 2),
        ..._group(1, 101, 20),
        _item(2, [0, 4, 2]),
      ];

      final result = prepareFsrsTrainingData(items, filterOutliers: false);

      expect(result.initializationItems, hasLength(22));
      expect(result.trainingItems, hasLength(1));
      expect(result.trainingItems.single.reviews, hasLength(3));
    });

    test('uses minimum 20 as the boundary for subgroup removal', () {
      final items = [..._group(1, 1, 19), ..._group(1, 2, 21)];

      final result = prepareFsrsTrainingData(items, filterOutliers: true);

      // Core retains the eligible subgroup that crosses the removal target.
      expect(result.initializationItems, hasLength(21));
      expect(
          result.initializationItems
              .every((item) => item.reviews[1].deltaT == 2),
          isTrue);
    });

    test('uses the floor of five percent when it exceeds 20', () {
      final items = [..._group(1, 101, 21), ..._group(1, 2, 399)];

      final result = prepareFsrsTrainingData(items, filterOutliers: true);

      expect(result.initializationItems, hasLength(399));
      expect(
          result.initializationItems
              .every((item) => item.reviews[1].deltaT == 2),
          isTrue);
    });

    test('retains six-item groups only within rating-specific delta limits',
        () {
      final items = [
        ..._group(1, 1, 5),
        ..._group(1, 2, 5),
        ..._group(1, 3, 5),
        ..._group(1, 4, 5),
        ..._group(1, 100, 6),
        ..._group(1, 101, 6),
        ..._group(4, 1, 5),
        ..._group(4, 2, 5),
        ..._group(4, 3, 5),
        ..._group(4, 4, 5),
        ..._group(4, 365, 6),
        ..._group(4, 366, 6),
      ];

      final result = prepareFsrsTrainingData(items, filterOutliers: true);

      expect(result.initializationItems, hasLength(12));
      expect(
        result.initializationItems
            .map((item) => (item.reviews.first.rating, item.reviews[1].deltaT))
            .toSet(),
        {(1, 100), (4, 365)},
      );
    });

    test(
        'removes matching rating and first long-term delta pairs from training',
        () {
      final filteredGroup = _group(2, 101, 20);
      final retainedGroup = _group(2, 5, 20);
      final otherRating = _group(3, 5, 20);
      final longHistory = _item(2, [0, 5, 2]);
      final items = [
        ...filteredGroup,
        ...retainedGroup,
        ...otherRating,
        longHistory
      ];

      final result = prepareFsrsTrainingData(items, filterOutliers: true);

      expect(result.trainingItems, [
        ...retainedGroup,
        ...otherRating,
        longHistory,
      ]);
    });

    test('accepts an empty dataset and rejects malformed items clearly', () {
      expect(
          prepareFsrsTrainingData([], filterOutliers: true).initializationItems,
          isEmpty);
      expect(
        () => prepareFsrsTrainingData(
          [const FsrsTrainingItem(reviews: [])],
          filterOutliers: false,
        ),
        throwsArgumentError,
      );
      expect(
        () => prepareFsrsTrainingData(
          [
            _item(2, [0, 5, 0])
          ],
          filterOutliers: false,
        ),
        throwsArgumentError,
      );
      final result = prepareFsrsTrainingData(
        [
          _item(2, [0, 1])
        ],
        filterOutliers: false,
      );
      expect(() => result.initializationItems.add(_item(3, [0, 1])),
          throwsUnsupportedError);
    });

    test('is deterministic and keeps source ordering within retained groups',
        () {
      final deltaTwo = _group(1, 2, 20);
      final deltaOne = _group(1, 1, 20);
      final items = [...deltaTwo, ...deltaOne];

      final first = prepareFsrsTrainingData(items, filterOutliers: true);
      final second = prepareFsrsTrainingData(items, filterOutliers: true);

      expect(first.initializationItems, second.initializationItems);
      expect(first.initializationItems, [...deltaOne, ...deltaTwo]);
      expect(first.trainingItems, second.trainingItems);
      expect(first.trainingItems, items);
    });
  });
}
