// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('calculateFsrsBinaryCrossEntropy', () {
    test('matches the three weighted reductions for mixed labels and weights',
        () {
      const predictions = [0.25, 0.75, 0.4];
      const labels = [1.0, 0.0, 1.0];
      const weights = [0.5, 2.0, 1.25];

      expect(
        calculateFsrsBinaryCrossEntropy(
          predictions,
          labels,
          weights,
          reduction: FsrsBceReduction.mean,
        ),
        1.5370330810546875,
      );
      expect(
        calculateFsrsBinaryCrossEntropy(
          predictions,
          labels,
          weights,
          reduction: FsrsBceReduction.sum,
        ),
        4.6110992431640625,
      );
      expect(
        calculateFsrsBinaryCrossEntropy(
          predictions,
          labels,
          weights,
          reduction: FsrsBceReduction.auto,
        ),
        1.2296264171600342,
      );
    });

    test('preserves exact Float32 operation results for a singleton', () {
      expect(
        calculateFsrsBinaryCrossEntropy(
          [0.3],
          [1.0],
          [0.7],
          reduction: FsrsBceReduction.sum,
        ),
        0.8427809476852417,
      );
    });

    test('uses source-compatible results for empty reductions', () {
      expect(
        calculateFsrsBinaryCrossEntropy(
          [],
          [],
          [],
          reduction: FsrsBceReduction.sum,
        ),
        0.0,
      );
      expect(
        calculateFsrsBinaryCrossEntropy(
          [],
          [],
          [],
          reduction: FsrsBceReduction.mean,
        ).isNaN,
        isTrue,
      );
      expect(
        calculateFsrsBinaryCrossEntropy(
          [],
          [],
          [],
          reduction: FsrsBceReduction.auto,
        ).isNaN,
        isTrue,
      );
    });

    test('preserves logarithm endpoint behavior without clamping', () {
      expect(
        calculateFsrsBinaryCrossEntropy(
          [0.0],
          [1.0],
          [1.0],
          reduction: FsrsBceReduction.sum,
        ),
        double.infinity,
      );
      expect(
        calculateFsrsBinaryCrossEntropy(
          [1.0],
          [0.0],
          [1.0],
          reduction: FsrsBceReduction.sum,
        ),
        double.infinity,
      );
      expect(
        calculateFsrsBinaryCrossEntropy(
          [0.0],
          [0.0],
          [1.0],
          reduction: FsrsBceReduction.sum,
        ).isNaN,
        isTrue,
      );
      expect(
        calculateFsrsBinaryCrossEntropy(
          [1.0],
          [1.0],
          [1.0],
          reduction: FsrsBceReduction.sum,
        ).isNaN,
        isTrue,
      );
    });

    test('returns NaN for Auto reduction when the total weight is zero', () {
      expect(
        calculateFsrsBinaryCrossEntropy(
          [0.5],
          [1.0],
          [0.0],
          reduction: FsrsBceReduction.auto,
        ).isNaN,
        isTrue,
      );
    });

    test('rejects mismatched parallel input lengths', () {
      expect(
        () => calculateFsrsBinaryCrossEntropy(
          [0.5],
          [],
          [1.0],
          reduction: FsrsBceReduction.sum,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculateFsrsBinaryCrossEntropy(
          [0.5],
          [1.0],
          [],
          reduction: FsrsBceReduction.sum,
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid predictions, binary labels, and weights', () {
      for (final prediction in [-0.1, 1.1, double.nan, double.infinity]) {
        expect(
          () => calculateFsrsBinaryCrossEntropy(
            [prediction],
            [1.0],
            [1.0],
            reduction: FsrsBceReduction.sum,
          ),
          throwsArgumentError,
        );
      }
      for (final label in [-1.0, 0.5, 2.0, double.nan]) {
        expect(
          () => calculateFsrsBinaryCrossEntropy(
            [0.5],
            [label],
            [1.0],
            reduction: FsrsBceReduction.sum,
          ),
          throwsArgumentError,
        );
      }
      for (final weight in [-0.1, double.nan, double.infinity]) {
        expect(
          () => calculateFsrsBinaryCrossEntropy(
            [0.5],
            [1.0],
            [weight],
            reduction: FsrsBceReduction.sum,
          ),
          throwsArgumentError,
        );
      }
    });

    test('does not mutate caller lists', () {
      final predictions = [0.2, 0.8];
      final labels = [1.0, 0.0];
      final weights = [0.25, 2.0];
      final originalPredictions = List<double>.of(predictions);
      final originalLabels = List<double>.of(labels);
      final originalWeights = List<double>.of(weights);

      calculateFsrsBinaryCrossEntropy(
        predictions,
        labels,
        weights,
        reduction: FsrsBceReduction.sum,
      );

      expect(predictions, originalPredictions);
      expect(labels, originalLabels);
      expect(weights, originalWeights);
    });
  });
}
