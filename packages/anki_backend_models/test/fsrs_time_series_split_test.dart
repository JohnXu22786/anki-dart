// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

FsrsTrainingItem _item(int marker) => FsrsTrainingItem(
      reviews: [FsrsTrainingReview(rating: marker, deltaT: marker)],
    );

void main() {
  group('splitFsrsTrainingItemsByTimeSeries', () {
    test('returns no folds for empty, zero-split, or undersized input', () {
      expect(splitFsrsTrainingItemsByTimeSeries([], nSplits: 2), isEmpty);
      expect(
        splitFsrsTrainingItemsByTimeSeries([_item(1), _item(2)], nSplits: 0),
        isEmpty,
      );
      expect(
        splitFsrsTrainingItemsByTimeSeries([_item(1)], nSplits: 2),
        isEmpty,
      );
    });

    test('uses expanding training prefixes and exact validation boundaries',
        () {
      final items = List.generate(8, _item);

      final folds = splitFsrsTrainingItemsByTimeSeries(items, nSplits: 3);

      expect(folds, hasLength(3));
      expect(folds[0].trainingItems, items.sublist(0, 2));
      expect(folds[0].validationItems, items.sublist(2, 4));
      expect(folds[1].trainingItems, items.sublist(0, 4));
      expect(folds[1].validationItems, items.sublist(4, 6));
      expect(folds[2].trainingItems, items.sublist(0, 6));
      expect(folds[2].validationItems, items.sublist(6, 8));
    });

    test('assigns the final fold all remaining items', () {
      final items = List.generate(10, _item);

      final folds = splitFsrsTrainingItemsByTimeSeries(items, nSplits: 3);

      expect(folds.last.trainingItems, items.sublist(0, 6));
      expect(folds.last.validationItems, items.sublist(6, 10));
    });

    test('preserves item order and original item instances', () {
      final items = [_item(4), _item(1), _item(3), _item(2)];

      final folds = splitFsrsTrainingItemsByTimeSeries(items, nSplits: 1);

      expect(folds.single.trainingItems, [items[0], items[1]]);
      expect(folds.single.validationItems, [items[2], items[3]]);
      expect(folds.single.trainingItems[0], same(items[0]));
      expect(folds.single.validationItems[1], same(items[3]));
    });

    test('returns immutable fold and item lists', () {
      final folds = splitFsrsTrainingItemsByTimeSeries(
        List.generate(4, _item),
        nSplits: 1,
      );

      expect(
        () => folds.add(folds.single),
        throwsUnsupportedError,
      );
      expect(
        () => folds.single.trainingItems.add(_item(5)),
        throwsUnsupportedError,
      );
      expect(
        () => folds.single.validationItems[0] = _item(5),
        throwsUnsupportedError,
      );
    });
  });
}
