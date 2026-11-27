// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('calculateFsrsTrainingIterationCount', () {
    test('preserves the extra slot for an empty dataset', () {
      expect(
        calculateFsrsTrainingIterationCount(
          itemsTotal: 0,
          batchSize: 4,
          epochTotal: 3,
        ),
        3,
      );
    });

    test('counts one slot for fewer than one batch of items', () {
      expect(
        calculateFsrsTrainingIterationCount(
          itemsTotal: 3,
          batchSize: 4,
          epochTotal: 2,
        ),
        2,
      );
    });

    test('preserves the extra slot for exact batch multiples', () {
      expect(
        calculateFsrsTrainingIterationCount(
          itemsTotal: 8,
          batchSize: 4,
          epochTotal: 2,
        ),
        6,
      );
    });

    test('counts the partial final batch plus the extra slot', () {
      expect(
        calculateFsrsTrainingIterationCount(
          itemsTotal: 9,
          batchSize: 4,
          epochTotal: 3,
        ),
        9,
      );
    });

    test('returns zero iterations for zero epochs', () {
      expect(
        calculateFsrsTrainingIterationCount(
          itemsTotal: 9,
          batchSize: 4,
          epochTotal: 0,
        ),
        0,
      );
    });

    test('rejects negative item and epoch counts', () {
      expect(
        () => calculateFsrsTrainingIterationCount(
          itemsTotal: -1,
          batchSize: 4,
          epochTotal: 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => calculateFsrsTrainingIterationCount(
          itemsTotal: 1,
          batchSize: 4,
          epochTotal: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a zero batch size', () {
      expect(
        () => calculateFsrsTrainingIterationCount(
          itemsTotal: 1,
          batchSize: 0,
          epochTotal: 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
