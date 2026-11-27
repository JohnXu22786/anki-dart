// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  final initial = initializeFsrsTrainingModelParameters(
    freezeShortTermStability: false,
  );
  final current = [
    ...initial,
  ]..[0] += 0.25;
  final stddev = List<double>.filled(21, 1);

  FsrsTrainingBatch batch({
    required List<double> deltaTs,
    required List<int> labels,
    required List<double> weights,
    List<List<double>> timeHistories = const [],
    List<List<double>> ratingHistories = const [],
  }) =>
      FsrsTrainingBatch(
        timeHistories: timeHistories,
        ratingHistories: ratingHistories,
        deltaTs: deltaTs,
        labels: labels,
        weights: weights,
      );

  double batchObjective(FsrsTrainingBatch value, {required int totalSize}) {
    final predictions = predictFsrsTrainingBatchRetrievability(value, current);
    return calculateFsrsTrainingBatchObjective(
      predictions,
      value.labels.map((label) => label.toDouble()).toList(),
      value.weights,
      current,
      initial,
      stddev,
      batchSize: value.deltaTs.length,
      totalSize: totalSize,
      gamma: 2,
    );
  }

  test('averages source-ordered batch objectives over validation items', () {
    final first = batch(
      deltaTs: [2, 7],
      labels: [1, 0],
      weights: [1, 0.5],
      timeHistories: [
        [0, 2],
      ],
      ratingHistories: [
        [3, 2],
      ],
    );
    final finalBatch = batch(
      deltaTs: [4],
      labels: [1],
      weights: [1],
      timeHistories: [
        [0],
      ],
      ratingHistories: [
        [4],
      ],
    );
    final values = [first, finalBatch];
    final expected = (batchObjective(first, totalSize: 100) +
            batchObjective(finalBatch, totalSize: 100)) /
        3;

    expect(
      calculateFsrsValidationLoss(
        values,
        current,
        initial,
        stddev,
        totalSize: 100,
        gamma: 2,
      ),
      expected,
    );
  });

  test('one batch matches its batch objective divided by its item count', () {
    final value = batch(
      deltaTs: [2, 7, 4],
      labels: [1, 0, 1],
      weights: [1, 0.5, 1],
      timeHistories: [
        [0, 2, 1],
      ],
      ratingHistories: [
        [3, 2, 4],
      ],
    );
    final expected = batchObjective(value, totalSize: 100) / 3;

    expect(
      calculateFsrsValidationLoss(
        [value],
        current,
        initial,
        stddev,
        totalSize: 100,
        gamma: 2,
      ),
      expected,
    );
  });

  test('uses caller batch order and total validation item count', () {
    final values = [
      batch(
        deltaTs: [2],
        labels: [1],
        weights: [1],
        timeHistories: [
          [0],
        ],
        ratingHistories: [
          [3],
        ],
      ),
      batch(
        deltaTs: [4, 5],
        labels: [0, 1],
        weights: [1, 1],
        timeHistories: [
          [2, 1],
        ],
        ratingHistories: [
          [1, 4],
        ],
      ),
    ];
    final reversed = values.reversed.toList();
    double expectedFor(List<FsrsTrainingBatch> ordered) {
      var sum = 0.0;
      for (final value in ordered) {
        sum += batchObjective(value, totalSize: 100);
      }
      return sum / 3;
    }

    expect(
      calculateFsrsValidationLoss(
        values,
        current,
        initial,
        stddev,
        totalSize: 100,
        gamma: 2,
      ),
      expectedFor(values),
    );
    expect(
      calculateFsrsValidationLoss(
        reversed,
        current,
        initial,
        stddev,
        totalSize: 100,
        gamma: 2,
      ),
      expectedFor(reversed),
    );
  });

  test('empty batch list follows source zero-over-zero behavior', () {
    expect(
      calculateFsrsValidationLoss(
        const [],
        current,
        initial,
        stddev,
        totalSize: 100,
        gamma: 2,
      ).isNaN,
      isTrue,
    );
  });

  test('does not mutate batches or parameters and rejects invalid inputs', () {
    final deltas = [2.0];
    final labels = [1];
    final weights = [1.0];
    final histories = [
      [0.0],
    ];
    final ratings = [
      [3.0],
    ];
    final value = batch(
      deltaTs: deltas,
      labels: labels,
      weights: weights,
      timeHistories: histories,
      ratingHistories: ratings,
    );
    final values = [value];
    final currentBefore = [...current];
    calculateFsrsValidationLoss(
      values,
      current,
      initial,
      stddev,
      totalSize: 10,
      gamma: 1,
    );
    expect(values, [same(value)]);
    expect(deltas, [2]);
    expect(labels, [1]);
    expect(weights, [1]);
    expect(histories, [
      [0],
    ]);
    expect(ratings, [
      [3],
    ]);
    expect(current, currentBefore);

    expect(
      () => calculateFsrsValidationLoss(
        values,
        current,
        initial,
        stddev,
        totalSize: 0,
        gamma: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => calculateFsrsValidationLoss(
        values,
        current,
        initial,
        stddev,
        totalSize: -1,
        gamma: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => calculateFsrsValidationLoss(
        [batch(deltaTs: [], labels: [], weights: [])],
        current,
        initial,
        stddev,
        totalSize: 10,
        gamma: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => calculateFsrsValidationLoss(
        values,
        current,
        initial,
        stddev,
        totalSize: 10,
        gamma: double.nan,
      ),
      throwsArgumentError,
    );
    expect(
      () => calculateFsrsValidationLoss(
        values,
        current.take(20).toList(),
        initial,
        stddev,
        totalSize: 10,
        gamma: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => calculateFsrsValidationLoss(
        [
          batch(deltaTs: [2], labels: [2], weights: [1])
        ],
        current,
        initial,
        stddev,
        totalSize: 10,
        gamma: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => calculateFsrsValidationLoss(
        [
          batch(deltaTs: [2], labels: [1], weights: [1])
        ],
        current,
        initial,
        stddev,
        totalSize: 10,
        gamma: -1,
      ),
      throwsArgumentError,
    );
  });
}
