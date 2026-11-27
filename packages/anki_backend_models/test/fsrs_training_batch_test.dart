// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

FsrsTrainingReview _review(int rating, double deltaT) =>
    FsrsTrainingReview(rating: rating, deltaT: deltaT.toInt());

WeightedFsrsTrainingItem _weighted(List<FsrsTrainingReview> reviews,
        {double weight = 1}) =>
    WeightedFsrsTrainingItem(
      item: FsrsTrainingItem(reviews: reviews),
      weight: weight,
    );

void main() {
  group('packFsrsTrainingBatch', () {
    test('pads histories into sequence-major rows and preserves item order',
        () {
      final first = _weighted([_review(1, 0), _review(2, 1)]);
      final second = _weighted([
        _review(2, 0),
        _review(3, 2),
        _review(4, 3),
        _review(1, 99),
      ]);

      final batch = packFsrsTrainingBatch([first, second]);

      expect(batch.deltaTs, [1, 99]);
      expect(batch.timeHistories, [
        [0, 0],
        [0, 2],
        [0, 3],
      ]);
      expect(batch.ratingHistories, [
        [1, 2],
        [0, 3],
        [0, 4],
      ]);
      expect(batch.weights, [1, 1]);
      expect(() => batch.timeHistories.first[0] = 1, throwsUnsupportedError);
    });

    test('rounds values to Float32 and maps Again versus other ratings', () {
      final batch = packFsrsTrainingBatch([
        _weighted([
          _review(1, 0),
          _review(3, 16777217),
          _review(4, 16777219),
        ], weight: 1.00000006),
        _weighted([
          _review(4, 0),
          _review(2, 16777219),
          _review(1, 16777217),
        ], weight: 0.10000000149),
      ]);

      expect(batch.timeHistories, [
        [0, 0],
        [
          Float32List.fromList([16777217]).single,
          Float32List.fromList([16777219]).single
        ],
      ]);
      expect(batch.ratingHistories, [
        [1, 4],
        [3, 2],
      ]);
      expect(batch.deltaTs, [
        Float32List.fromList([16777219]).single,
        Float32List.fromList([16777217]).single,
      ]);
      expect(batch.weights, Float32List.fromList([1.00000006, 0.10000000149]));
      expect(batch.labels, [1, 0]);
    });

    test('supports a singleton one-review batch with immutable empty histories',
        () {
      final reviews = <FsrsTrainingReview>[_review(3, 7)];
      final item = _weighted(reviews, weight: 0.3);

      final batch = packFsrsTrainingBatch([item]);

      expect(batch.timeHistories, isEmpty);
      expect(batch.ratingHistories, isEmpty);
      expect(batch.deltaTs, [7]);
      expect(batch.labels, [1]);
      expect(batch.weights, [
        Float32List.fromList([0.3]).single
      ]);
      expect(item.item.reviews, same(reviews));
      expect(reviews, hasLength(1));
      expect(() => batch.timeHistories.add([1]), throwsUnsupportedError);
      expect(() => batch.deltaTs[0] = 0, throwsUnsupportedError);
    });

    test('rejects an empty batch and items without reviews clearly', () {
      expect(
        () => packFsrsTrainingBatch([]),
        throwsA(isA<ArgumentError>().having(
          (error) => error.message.toString(),
          'message',
          contains('batch'),
        )),
      );
      expect(
        () => packFsrsTrainingBatch([
          _weighted([]),
        ]),
        throwsA(isA<ArgumentError>().having(
          (error) => error.message.toString(),
          'message',
          contains('review'),
        )),
      );
    });
  });
}
