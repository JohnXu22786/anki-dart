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
  group('FSRS training progress split updates', () {
    FsrsTrainingProgress progressFor(List<FsrsTrainingSplitProgress> splits,
            {bool finished = false}) =>
        FsrsTrainingProgress(splits: splits, finished: finished);

    FsrsTrainingProgress update(
      FsrsTrainingProgress progress,
      int splitIndex, {
      required int epoch,
      required int epochTotal,
      required int itemsProcessed,
      required int itemsTotal,
    }) =>
        updateFsrsTrainingProgressSplit(
          progress: progress,
          splitIndex: splitIndex,
          epoch: epoch,
          epochTotal: epochTotal,
          itemsProcessed: itemsProcessed,
          itemsTotal: itemsTotal,
        );

    test('replaces the first, middle, and last split without changing others',
        () {
      final originalSplits = [
        _split(epoch: 1, epochTotal: 2, itemsProcessed: 1, itemsTotal: 5),
        _split(epoch: 2, epochTotal: 3, itemsProcessed: 2, itemsTotal: 7),
        _split(epoch: 3, epochTotal: 4, itemsProcessed: 3, itemsTotal: 11),
      ];
      final original = progressFor(originalSplits, finished: true);

      for (final index in [0, 1, 2]) {
        final updated = update(
          original,
          index,
          epoch: 4,
          epochTotal: 6,
          itemsProcessed: 8,
          itemsTotal: 13,
        );

        expect(updated, isNot(same(original)));
        expect(updated.splits, hasLength(3));
        expect(updated.finished, isTrue);
        expect(updated.splits[index].epoch, 4);
        expect(updated.splits[index].epochTotal, 6);
        expect(updated.splits[index].itemsProcessed, 8);
        expect(updated.splits[index].itemsTotal, 13);
        for (var other = 0; other < 3; other++) {
          if (other != index) {
            expect(updated.splits[other], same(original.splits[other]));
          }
        }
        expect(original.splits, orderedEquals(originalSplits));
      }
    });

    test('copies the source list and exposes an immutable updated snapshot',
        () {
      final sourceSplits = [
        _split(epoch: 1, epochTotal: 2, itemsProcessed: 1, itemsTotal: 4),
        _split(epoch: 2, epochTotal: 3, itemsProcessed: 2, itemsTotal: 5),
      ];
      final original = progressFor(sourceSplits);
      final updated = update(
        original,
        1,
        epoch: 3,
        epochTotal: 4,
        itemsProcessed: 3,
        itemsTotal: 6,
      );
      final updatedSnapshot =
          List<FsrsTrainingSplitProgress>.of(updated.splits);

      sourceSplits.clear();
      expect(original.splits, hasLength(2));
      expect(updated.splits, orderedEquals(updatedSnapshot));
      expect(() => updated.splits.clear(), throwsUnsupportedError);
      expect(
          () => updated.splits[0] = original.splits[0], throwsUnsupportedError);
    });

    test('recalculates aggregate current and total from updated values', () {
      final original = progressFor([
        _split(epoch: 2, epochTotal: 5, itemsProcessed: 3, itemsTotal: 10),
        _split(epoch: 1, epochTotal: 4, itemsProcessed: 2, itemsTotal: 7),
      ]);
      final updated = update(
        original,
        0,
        epoch: 4,
        epochTotal: 6,
        itemsProcessed: 8,
        itemsTotal: 13,
      );

      expect(updated.current, 49);
      expect(updated.total, 106);
    });

    test('rejects negative counts through split value validation', () {
      final original = progressFor([
        _split(epoch: 1, epochTotal: 2, itemsProcessed: 1, itemsTotal: 4),
      ]);

      expect(
        () => update(original, 0,
            epoch: -1, epochTotal: 2, itemsProcessed: 1, itemsTotal: 4),
        throwsArgumentError,
      );
      expect(
        () => update(original, 0,
            epoch: 1, epochTotal: 2, itemsProcessed: 1, itemsTotal: -4),
        throwsArgumentError,
      );
      expect(original.splits.single.epoch, 1);
    });

    test('reports negative and high split indexes as range errors', () {
      final original = progressFor([
        _split(epoch: 1, epochTotal: 2, itemsProcessed: 1, itemsTotal: 4),
      ]);

      expect(
        () => update(original, -1,
            epoch: 2, epochTotal: 3, itemsProcessed: 2, itemsTotal: 5),
        throwsRangeError,
      );
      expect(
        () => update(original, 1,
            epoch: 2, epochTotal: 3, itemsProcessed: 2, itemsTotal: 5),
        throwsRangeError,
      );
      expect(original.splits.single.epoch, 1);
    });
  });
}
