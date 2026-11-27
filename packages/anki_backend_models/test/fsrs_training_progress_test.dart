// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

FsrsTrainingSplitProgress _split({
  required int epoch,
  required int epochTotal,
  required int itemsProcessed,
  required int itemsTotal,
}) =>
    FsrsTrainingSplitProgress(
      epoch: epoch,
      epochTotal: epochTotal,
      itemsProcessed: itemsProcessed,
      itemsTotal: itemsTotal,
    );

void main() {
  group('FSRS training progress projection', () {
    test('calculates current progress at epoch zero, one, and later epochs',
        () {
      expect(
        _split(epoch: 0, epochTotal: 5, itemsProcessed: 3, itemsTotal: 10)
            .current,
        3,
      );
      expect(
        _split(epoch: 1, epochTotal: 5, itemsProcessed: 3, itemsTotal: 10)
            .current,
        3,
      );
      expect(
        _split(epoch: 4, epochTotal: 5, itemsProcessed: 3, itemsTotal: 10)
            .current,
        33,
      );
    });

    test('calculates total from epoch and item totals, including zero totals',
        () {
      expect(
        _split(epoch: 2, epochTotal: 5, itemsProcessed: 3, itemsTotal: 10)
            .total,
        50,
      );
      expect(
        _split(epoch: 2, epochTotal: 5, itemsProcessed: 0, itemsTotal: 0).total,
        0,
      );
    });

    test('aggregates multiple splits and retains their input order', () {
      final splits = [
        _split(epoch: 2, epochTotal: 5, itemsProcessed: 3, itemsTotal: 10),
        _split(epoch: 1, epochTotal: 4, itemsProcessed: 2, itemsTotal: 7),
      ];

      final progress = FsrsTrainingProgress(splits: splits, finished: false);

      expect(progress.splits, orderedEquals(splits));
      expect(progress.current, 15);
      expect(progress.total, 78);
    });

    test('empty split lists have zero current progress and total', () {
      final progress = FsrsTrainingProgress(splits: [], finished: false);

      expect(progress.current, 0);
      expect(progress.total, 0);
    });

    test('passes through the explicit finished flag', () {
      expect(FsrsTrainingProgress(splits: [], finished: true).finished, isTrue);
      expect(
          FsrsTrainingProgress(splits: [], finished: false).finished, isFalse);
    });

    test('copies caller splits and exposes immutable split values', () {
      final splits = [
        _split(epoch: 1, epochTotal: 2, itemsProcessed: 1, itemsTotal: 4),
      ];
      final progress = FsrsTrainingProgress(splits: splits, finished: false);
      splits.clear();

      expect(progress.splits, hasLength(1));
      expect(() => progress.splits.clear(), throwsUnsupportedError);
      expect(progress.splits.single.epoch, 1);
    });

    test('rejects negative and non-integer counts with ArgumentError', () {
      expect(
        () => FsrsTrainingSplitProgress(
          epoch: -1,
          epochTotal: 1,
          itemsProcessed: 0,
          itemsTotal: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => FsrsTrainingSplitProgress(
          epoch: 0,
          epochTotal: 1,
          itemsProcessed: 0,
          itemsTotal: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => FsrsTrainingSplitProgress(
          epoch: 0,
          epochTotal: 1,
          itemsProcessed: 0.5,
          itemsTotal: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
