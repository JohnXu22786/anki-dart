// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

FsrsTrainingItem _item(int currentRating) => FsrsTrainingItem(
      reviews: [
        const FsrsTrainingReview(rating: 1, deltaT: 0),
        FsrsTrainingReview(rating: currentRating, deltaT: 1),
      ],
    );

void main() {
  group('calculateAverageFsrsRecall', () {
    test('returns zero for empty input', () {
      expect(calculateAverageFsrsRecall([]), 0.0);
    });

    test('counts current rating 1 as a miss', () {
      expect(calculateAverageFsrsRecall([_item(1), _item(1)]), 0.0);
    });

    test('counts current ratings 2 through 4 as recalls', () {
      expect(calculateAverageFsrsRecall([_item(2), _item(3), _item(4)]), 1.0);
    });

    test('returns mixed recall ratio rounded to Core Float32', () {
      expect(
        calculateAverageFsrsRecall([_item(1), _item(2), _item(4)]),
        0.6666666865348816,
      );
    });

    test('is independent of item order', () {
      final items = [_item(1), _item(2), _item(4), _item(3)];

      expect(calculateAverageFsrsRecall(items), 0.75);
      expect(calculateAverageFsrsRecall(items.reversed.toList()), 0.75);
    });

    test('rejects items without a current review', () {
      expect(
        () => calculateAverageFsrsRecall([
          _item(2),
          const FsrsTrainingItem(reviews: []),
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains(
                'each FSRS training item must contain at least one review'),
          ),
        ),
      );
    });
  });
}
