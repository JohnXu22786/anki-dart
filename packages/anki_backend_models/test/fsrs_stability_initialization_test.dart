// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

FsrsTrainingItem _example(int firstRating, int deltaT, bool pass) =>
    FsrsTrainingItem(
      reviews: [
        FsrsTrainingReview(rating: firstRating, deltaT: 0),
        FsrsTrainingReview(rating: pass ? 3 : 1, deltaT: deltaT),
      ],
    );

List<FsrsTrainingItem> _groupedItems(
  Map<int, Map<int, List<int>>> groups,
) =>
    [
      for (final ratingEntry in groups.entries)
        for (final deltaEntry in ratingEntry.value.entries)
          for (final outcome in deltaEntry.value)
            _example(ratingEntry.key, deltaEntry.key, outcome == 1),
    ];

void main() {
  group('initializeFsrsStabilityParameters', () {
    test('matches FSRS 5.2.0 per-rating search golden values', () {
      final items = _groupedItems({
        1: {
          1: [...List.filled(377, 1), ...List.filled(58, 0)],
          2: [...List.filled(88, 1), ...List.filled(9, 0)],
          3: [...List.filled(46, 1), ...List.filled(17, 0)],
          4: [...List.filled(29, 1), ...List.filled(9, 0)],
          5: [...List.filled(19, 1), ...List.filled(9, 0)],
        },
        2: {
          2: [...List.filled(7, 1), ...List.filled(3, 0)]
        },
        3: {
          3: [...List.filled(8, 1), ...List.filled(2, 0)]
        },
        4: {
          4: [...List.filled(9, 1), ...List.filled(1, 0)]
        },
      });

      final result = initializeFsrsStabilityParameters(
        items,
        averageRecall: 0.94302857,
      );

      expect(result.stabilities, hasLength(4));
      // FSRS Rust source test golden for the first rating; the integer group
      // counts above reproduce its pass rates to the shown precision.
      expect(result.stabilities[0], closeTo(0.7355089, 0.0002));
      expect(result.ratingCounts, {1: 661, 2: 10, 3: 10, 4: 10});
    });

    test('aggregates by first rating and first positive deltaT only', () {
      final items = [
        const FsrsTrainingItem(reviews: [
          FsrsTrainingReview(rating: 2, deltaT: 0),
          FsrsTrainingReview(rating: 4, deltaT: 3),
        ]),
        _example(2, 3, false),
        _example(4, 8, true),
      ];

      final result = initializeFsrsStabilityParameters(
        items,
        averageRecall: 0.5,
      );

      expect(result.ratingCounts, {2: 2, 4: 1});
      expect(items.map((item) => item.reviews.first.rating), [2, 2, 4]);
    });

    test('fills missing ratings for one through four observed ratings', () {
      final cases = <List<int>>[
        [1],
        [2],
        [3],
        [4],
        [1, 2],
        [1, 3],
        [1, 4],
        [2, 3],
        [2, 4],
        [3, 4],
        [1, 2, 3],
        [1, 2, 4],
        [1, 3, 4],
        [2, 3, 4],
        [1, 2, 3, 4],
      ];
      for (final ratings in cases) {
        final result = initializeFsrsStabilityParameters(
          [for (final rating in ratings) _example(rating, 3, true)],
          averageRecall: 0.75,
        );
        expect(result.stabilities, hasLength(4), reason: '$ratings');
        expect(result.stabilities,
            orderedEquals(result.stabilities.toList()..sort()),
            reason: '$ratings must remain monotonic');
      }
    });

    test('uses source count tie behavior when correcting monotonic values', () {
      final moreEasy = initializeFsrsStabilityParameters([
        ...List.generate(20, (_) => _example(1, 1, true)),
        _example(2, 100, false),
      ], averageRecall: 0.5);
      final moreHard = initializeFsrsStabilityParameters([
        _example(1, 1, true),
        ...List.generate(20, (_) => _example(2, 100, false)),
      ], averageRecall: 0.5);
      final tied = initializeFsrsStabilityParameters([
        _example(1, 100, true),
        _example(2, 1, false),
      ], averageRecall: 0.5);
      expect(
          moreEasy.stabilities[0], lessThanOrEqualTo(moreEasy.stabilities[1]));
      expect(
          moreHard.stabilities[0], lessThanOrEqualTo(moreHard.stabilities[1]));
      expect(moreEasy.stabilities[0], moreEasy.stabilities[1]);
      expect(moreHard.stabilities[0], moreHard.stabilities[1]);
      expect(tied.stabilities[0], tied.stabilities[1]);
    });

    test('clamps the output to FSRS stability bounds', () {
      final result = initializeFsrsStabilityParameters([
        for (var index = 0; index < 5; index++) _example(1, 1, false),
      ], averageRecall: 0.0);
      expect(
          result.stabilities.every((value) => value >= 0.001 && value <= 100),
          isTrue);
    });

    test('reports insufficient initialization data as a state error', () {
      expect(
        () => initializeFsrsStabilityParameters([], averageRecall: 0.5),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects malformed histories and ratings at the boundary', () {
      final malformed = <FsrsTrainingItem>[
        const FsrsTrainingItem(reviews: []),
        const FsrsTrainingItem(
            reviews: [FsrsTrainingReview(rating: 1, deltaT: 0)]),
        const FsrsTrainingItem(reviews: [
          FsrsTrainingReview(rating: 5, deltaT: 0),
          FsrsTrainingReview(rating: 2, deltaT: 1),
        ]),
        const FsrsTrainingItem(reviews: [
          FsrsTrainingReview(rating: 1, deltaT: 0),
          FsrsTrainingReview(rating: 0, deltaT: 1),
        ]),
        const FsrsTrainingItem(reviews: [
          FsrsTrainingReview(rating: 1, deltaT: 1),
          FsrsTrainingReview(rating: 2, deltaT: 2),
        ]),
        const FsrsTrainingItem(reviews: [
          FsrsTrainingReview(rating: 1, deltaT: 0),
          FsrsTrainingReview(rating: 2, deltaT: 1),
          FsrsTrainingReview(rating: 3, deltaT: 0),
        ]),
        const FsrsTrainingItem(reviews: [
          FsrsTrainingReview(rating: 1, deltaT: 0),
          FsrsTrainingReview(rating: 2, deltaT: -1),
        ]),
      ];
      for (final item in malformed) {
        expect(
          () => initializeFsrsStabilityParameters([item], averageRecall: 0.5),
          throwsA(isA<ArgumentError>()),
        );
      }
    });

    test('rejects average recall outside the unit interval', () {
      for (final averageRecall in [-0.1, 1.1, double.nan, double.infinity]) {
        expect(
          () => initializeFsrsStabilityParameters(
            [_example(1, 2, true)],
            averageRecall: averageRecall,
          ),
          throwsA(isA<ArgumentError>()),
        );
      }
    });

    test('returns immutable values and rating counts', () {
      final result = initializeFsrsStabilityParameters(
        [_example(2, 3, true)],
        averageRecall: 0.5,
      );
      expect(() => result.stabilities.add(5), throwsUnsupportedError);
      expect(() => result.ratingCounts[2] = 8, throwsUnsupportedError);
    });
  });
}
