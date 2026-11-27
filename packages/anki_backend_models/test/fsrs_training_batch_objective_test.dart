// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('calculateFsrsTrainingBatchObjective', () {
    test('composes the pinned Sum BCE and L2 fixture in Float32', () {
      const initial = [
        0.212,
        1.2931,
        2.3065,
        8.2956,
        6.4133,
        0.8334,
        3.0194,
        0.001,
        1.8722,
        0.1666,
        0.796,
        1.4835,
        0.0614,
        0.2629,
        1.6483,
        0.6014,
        1.8729,
        0.5425,
        0.0912,
        0.0658,
        0.1542,
      ];
      const current = [
        0.252,
        1.3331,
        2.3464994,
        8.2556,
        6.3733,
        0.87340003,
        2.9794,
        0.040999997,
        1.8322,
        0.20660001,
        0.756,
        1.5235,
        0.021400042,
        0.3029,
        1.6882998,
        0.64140004,
        1.8329,
        0.5025,
        0.13119997,
        0.1058,
        0.1142,
      ];
      const stddev = [
        6.43,
        9.66,
        17.58,
        27.85,
        0.57,
        0.28,
        0.6,
        0.12,
        0.39,
        0.18,
        0.33,
        0.3,
        0.09,
        0.16,
        0.57,
        0.25,
        1.03,
        0.31,
        0.32,
        0.14,
        0.27,
      ];
      final predictions = [math.exp(-4.047898)];
      const labels = [1.0];
      const weights = [1.0];

      expect(
        calculateFsrsBinaryCrossEntropy(predictions, labels, weights,
            reduction: FsrsBceReduction.sum),
        4.047897815704346,
      );
      expect(
        calculateFsrsL2Regularization(
          current,
          initial,
          stddev,
          batchSize: 512,
          totalSize: 1000,
          gamma: 2.0,
        ),
        0.6771115064620972,
      );
      expect(
        calculateFsrsTrainingBatchObjective(
          predictions,
          labels,
          weights,
          current,
          initial,
          stddev,
          batchSize: 512,
          totalSize: 1000,
          gamma: 2.0,
        ),
        4.725009441375732,
      );
    });

    test('BCE inputs change the loss without changing parameter regularization',
        () {
      const current = [2.0];
      const initial = [0.0];
      const stddev = [1.0];
      double objective(double prediction, double label, double weight) =>
          calculateFsrsTrainingBatchObjective(
            [prediction],
            [label],
            [weight],
            current,
            initial,
            stddev,
            batchSize: 2,
            totalSize: 10,
            gamma: 0.5,
          );

      final baseline = objective(0.75, 1, 1);
      final baselineBce = calculateFsrsBinaryCrossEntropy(
        [0.75],
        [1],
        [1],
        reduction: FsrsBceReduction.sum,
      );
      final changedPrediction = objective(0.5, 1, 1);
      final changedLabel = objective(0.75, 0, 1);
      final changedWeight = objective(0.75, 1, 2);
      final penalty = calculateFsrsL2Regularization(
        current,
        initial,
        stddev,
        batchSize: 2,
        totalSize: 10,
        gamma: 0.5,
      );

      final expectedBaseline = Float32List(1);
      expectedBaseline[0] = baselineBce + penalty;
      expect(baseline, expectedBaseline[0]);
      expect(changedPrediction, isNot(baseline));
      expect(changedLabel, isNot(baseline));
      expect(changedWeight, isNot(baseline));
      expect(
          changedPrediction -
              calculateFsrsBinaryCrossEntropy(
                [0.5],
                [1],
                [1],
                reduction: FsrsBceReduction.sum,
              ),
          closeTo(penalty, 1e-7));
      expect(
          changedLabel -
              calculateFsrsBinaryCrossEntropy(
                [0.75],
                [0],
                [1],
                reduction: FsrsBceReduction.sum,
              ),
          closeTo(penalty, 1e-7));
      expect(
          changedWeight -
              calculateFsrsBinaryCrossEntropy(
                [0.75],
                [1],
                [2],
                reduction: FsrsBceReduction.sum,
              ),
          closeTo(penalty, 1e-7));
    });

    test('forwards batch size, total size, and gamma to regularization', () {
      const predictions = [0.5];
      const labels = [1.0];
      const weights = [1.0];
      const current = [2.0];
      const initial = [0.0];
      const stddev = [1.0];
      final bce = calculateFsrsBinaryCrossEntropy(
        predictions,
        labels,
        weights,
        reduction: FsrsBceReduction.sum,
      );
      final storage = Float32List(1);
      double f32(double value) {
        storage[0] = value;
        return storage[0];
      }

      for (final values in [
        (2, 10, 0.5),
        (4, 10, 0.5),
        (2, 20, 0.5),
        (2, 10, 1.0)
      ]) {
        final penalty = calculateFsrsL2Regularization(
          current,
          initial,
          stddev,
          batchSize: values.$1,
          totalSize: values.$2,
          gamma: values.$3,
        );
        expect(
          calculateFsrsTrainingBatchObjective(
            predictions,
            labels,
            weights,
            current,
            initial,
            stddev,
            batchSize: values.$1,
            totalSize: values.$2,
            gamma: values.$3,
          ),
          f32(bce + penalty),
        );
      }
    });

    test(
        'preserves helper validation for lengths, values, sizes, and parameters',
        () {
      final Function() mismatchedBce =
          () => calculateFsrsTrainingBatchObjective(
                [0.5],
                [],
                [1],
                [],
                [],
                [],
                batchSize: 1,
                totalSize: 1,
                gamma: 1,
              );
      final Function() mismatchedParameters =
          () => calculateFsrsTrainingBatchObjective(
                [],
                [],
                [],
                [1],
                [],
                [1],
                batchSize: 1,
                totalSize: 1,
                gamma: 1,
              );
      expect(mismatchedBce, throwsArgumentError);
      expect(mismatchedParameters, throwsArgumentError);

      for (final invalid in [
        ([double.nan], [1.0], [1.0]),
        ([0.5], [0.5], [1.0]),
        ([0.5], [1.0], [-1.0]),
      ]) {
        expect(
          () => calculateFsrsTrainingBatchObjective(
            invalid.$1,
            invalid.$2,
            invalid.$3,
            [],
            [],
            [],
            batchSize: 1,
            totalSize: 1,
            gamma: 1,
          ),
          throwsArgumentError,
        );
      }
      for (final values in [
        (-1, 1, 1.0),
        (1, 0, 1.0),
        (1, 1, -1.0),
        (1, 1, double.nan)
      ]) {
        expect(
          () => calculateFsrsTrainingBatchObjective(
            [],
            [],
            [],
            [],
            [],
            [],
            batchSize: values.$1,
            totalSize: values.$2,
            gamma: values.$3,
          ),
          throwsArgumentError,
        );
      }
      for (final vectors in [
        ([double.infinity], [0.0], [1.0]),
        ([1.0], [double.nan], [1.0]),
        ([1.0], [0.0], [0.0]),
      ]) {
        expect(
          () => calculateFsrsTrainingBatchObjective(
            [],
            [],
            [],
            vectors.$1,
            vectors.$2,
            vectors.$3,
            batchSize: 1,
            totalSize: 1,
            gamma: 1,
          ),
          throwsArgumentError,
        );
      }
    });

    test('keeps empty Sum BCE and regularization semantics without mutation',
        () {
      final predictions = [0.75];
      final labels = [1.0];
      final weights = [0.5];
      final current = [2.0];
      final initial = [0.0];
      final stddev = [1.0];
      final originalPredictions = List<double>.of(predictions);
      final originalLabels = List<double>.of(labels);
      final originalWeights = List<double>.of(weights);
      final originalCurrent = List<double>.of(current);
      final originalInitial = List<double>.of(initial);
      final originalStddev = List<double>.of(stddev);

      calculateFsrsTrainingBatchObjective(
        predictions,
        labels,
        weights,
        current,
        initial,
        stddev,
        batchSize: 2,
        totalSize: 10,
        gamma: 0.5,
      );
      expect(predictions, originalPredictions);
      expect(labels, originalLabels);
      expect(weights, originalWeights);
      expect(current, originalCurrent);
      expect(initial, originalInitial);
      expect(stddev, originalStddev);

      expect(
        calculateFsrsTrainingBatchObjective(
          const [],
          const [],
          const [],
          const [2.0],
          const [0.0],
          const [1.0],
          batchSize: 2,
          totalSize: 10,
          gamma: 0.5,
        ),
        calculateFsrsL2Regularization(
          const [2.0],
          const [0.0],
          const [1.0],
          batchSize: 2,
          totalSize: 10,
          gamma: 0.5,
        ),
      );
    });
  });
}
