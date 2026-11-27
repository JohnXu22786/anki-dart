// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

FsrsTrainingItem _item(int marker) => FsrsTrainingItem(
      reviews: [FsrsTrainingReview(rating: marker, deltaT: marker)],
    );

void main() {
  group('weightFsrsTrainingItemsByRecency', () {
    test('returns an empty list for empty input', () {
      expect(weightFsrsTrainingItemsByRecency([]), isEmpty);
    });

    test('uses the minimum recency weight for a single item', () {
      final item = _item(1);

      final result = weightFsrsTrainingItemsByRecency([item]);

      expect(result, hasLength(1));
      expect(result.single.item, same(item));
      expect(result.single.weight, 0.25);
    });

    test('matches FSRS 5.2.0 Float32 values at multiple positions', () {
      final result = weightFsrsTrainingItemsByRecency(
        List.generate(4, _item),
      );

      expect(result.map((weighted) => weighted.weight), [
        0.25,
        0.2777777910232544,
        0.472222238779068,
        1.0,
      ]);
    });

    test('preserves the input order and each original item association', () {
      final items = [_item(4), _item(2), _item(3)];

      final result = weightFsrsTrainingItemsByRecency(items);

      expect(result.map((weighted) => weighted.item), items);
      for (var index = 0; index < items.length; index++) {
        expect(result[index].item, same(items[index]));
      }
    });

    test('returns an immutable result list', () {
      final result = weightFsrsTrainingItemsByRecency([_item(1)]);

      expect(
          () => result.add(WeightedFsrsTrainingItem(
                item: _item(2),
                weight: 1.0,
              )),
          throwsUnsupportedError);
    });
  });
}
