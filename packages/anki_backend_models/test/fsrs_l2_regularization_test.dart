// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('calculateFsrsL2Regularization', () {
    test('matches the pinned FSRS 5.2.0 loss fixture', () {
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
    });

    test('returns zero when current parameters equal initial parameters', () {
      expect(
        calculateFsrsL2Regularization(
          [1.25, -2],
          [1.25, -2],
          [0.5, 3],
          batchSize: 4,
          totalSize: 8,
          gamma: 10,
        ),
        0.0,
      );
    });

    test('matches Float32 singleton and mixed-vector operation order', () {
      expect(
        calculateFsrsL2Regularization(
          [1.5],
          [0.5],
          [2],
          batchSize: 1,
          totalSize: 3,
          gamma: 0.1,
        ),
        0.008333333767950535,
      );
      expect(
        calculateFsrsL2Regularization(
          [1.5, -1.25, 4.75],
          [0.5, 0.75, 5.0],
          [2, 0.5, 4],
          batchSize: 2,
          totalSize: 3,
          gamma: 0.7,
        ),
        7.585156440734863,
      );
    });

    test('scales by gamma and batch size and returns zero for an empty batch',
        () {
      double penalty(int batchSize, double gamma) =>
          calculateFsrsL2Regularization(
            [2],
            [0],
            [1],
            batchSize: batchSize,
            totalSize: 10,
            gamma: gamma,
          );

      expect(penalty(2, 0.5), 0.4000000059604645);
      expect(penalty(4, 0.5), 0.800000011920929);
      expect(penalty(2, 1), 0.800000011920929);
      expect(penalty(0, 1), 0.0);
    });

    test('returns zero for empty parameter vectors', () {
      expect(
        calculateFsrsL2Regularization(
          [],
          [],
          [],
          batchSize: 0,
          totalSize: 1,
          gamma: 1,
        ),
        0.0,
      );
    });

    test('rejects mismatched vectors and zero standard deviations', () {
      expect(
        () => calculateFsrsL2Regularization(
          [1],
          [],
          [1],
          batchSize: 1,
          totalSize: 1,
          gamma: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculateFsrsL2Regularization(
          [1],
          [0],
          [],
          batchSize: 1,
          totalSize: 1,
          gamma: 1,
        ),
        throwsArgumentError,
      );
      for (final stddev in [0.0, -0.0, -1.0]) {
        expect(
          () => calculateFsrsL2Regularization(
            [1],
            [0],
            [stddev],
            batchSize: 1,
            totalSize: 1,
            gamma: 1,
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects nonfinite or non-Float32-finite scalar and element values',
        () {
      for (final gamma in [
        double.nan,
        double.infinity,
        -double.infinity,
        -1.0,
        1e100,
      ]) {
        expect(
          () => calculateFsrsL2Regularization(
            [1],
            [0],
            [1],
            batchSize: 1,
            totalSize: 1,
            gamma: gamma,
          ),
          throwsArgumentError,
        );
      }
      for (final value in [
        double.nan,
        double.infinity,
        -double.infinity,
        1e100
      ]) {
        expect(
          () => calculateFsrsL2Regularization(
            [value],
            [0],
            [1],
            batchSize: 1,
            totalSize: 1,
            gamma: 1,
          ),
          throwsArgumentError,
        );
        expect(
          () => calculateFsrsL2Regularization(
            [1],
            [value],
            [1],
            batchSize: 1,
            totalSize: 1,
            gamma: 1,
          ),
          throwsArgumentError,
        );
        expect(
          () => calculateFsrsL2Regularization(
            [1],
            [0],
            [value],
            batchSize: 1,
            totalSize: 1,
            gamma: 1,
          ),
          throwsArgumentError,
        );
      }

      expect(
        calculateFsrsL2Regularization(
          [3e38],
          [-3e38],
          [1],
          batchSize: 0,
          totalSize: 1,
          gamma: 1,
        ),
        0.0,
      );
    });

    test('rejects negative sizes and zero total size', () {
      for (final sizes in [(-1, 1), (1, -1), (0, 0)]) {
        expect(
          () => calculateFsrsL2Regularization(
            [],
            [],
            [],
            batchSize: sizes.$1,
            totalSize: sizes.$2,
            gamma: 1,
          ),
          throwsArgumentError,
        );
      }
    });

    test('does not mutate caller-owned lists', () {
      final current = [1.5, -1.25];
      final initial = [0.5, 0.75];
      final stddev = [2.0, 0.5];
      final originalCurrent = List<double>.of(current);
      final originalInitial = List<double>.of(initial);
      final originalStddev = List<double>.of(stddev);

      calculateFsrsL2Regularization(
        current,
        initial,
        stddev,
        batchSize: 1,
        totalSize: 2,
        gamma: 1,
      );

      expect(current, originalCurrent);
      expect(initial, originalInitial);
      expect(stddev, originalStddev);
    });
  });
}
