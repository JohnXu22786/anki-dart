// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('predictFsrsTrainingBatchRetrievability', () {
    final parameters = initializeFsrsTrainingModelParameters(
      freezeShortTermStability: false,
    );

    test('matches the pinned training model with sequence-major padding', () {
      final batch = FsrsTrainingBatch(
        timeHistories: [
          [0, 0, 0],
          [2, 2, 1],
          [0, 3, 0],
        ],
        ratingHistories: [
          [3, 2, 4],
          [0, 3, 1],
          [0, 4, 0],
        ],
        deltaTs: [5, 10, 4],
        labels: [1, 1, 1],
        weights: [1, 1, 1],
      );

      final result = predictFsrsTrainingBatchRetrievability(batch, parameters);

      expect(result, hasLength(3));
      expect(
        result,
        [0.8388614058494568, 0.9450342655181885, 0.9397124648094177],
      );
    });

    test('preserves the zero initial state for empty history', () {
      final batch = FsrsTrainingBatch(
        timeHistories: const [],
        ratingHistories: const [],
        deltaTs: const [3],
        labels: const [1],
        weights: const [1],
      );

      expect(
        predictFsrsTrainingBatchRetrievability(batch, parameters),
        [0.0],
      );

      final zeroIntervalBatch = FsrsTrainingBatch(
        timeHistories: const [],
        ratingHistories: const [],
        deltaTs: const [0],
        labels: const [1],
        weights: const [1],
      );
      expect(
        predictFsrsTrainingBatchRetrievability(zeroIntervalBatch, parameters)
            .single
            .isNaN,
        isTrue,
      );

      final paddedEmptyHistoryBatch = FsrsTrainingBatch(
        timeHistories: const [
          [0, 0],
        ],
        ratingHistories: const [
          [0, 3],
        ],
        deltaTs: const [0, 0],
        labels: const [1, 1],
        weights: const [1, 1],
      );
      // A padded column with no prior reviews keeps the zero initial state.
      expect(
        predictFsrsTrainingBatchRetrievability(
          paddedEmptyHistoryBatch,
          parameters,
        ),
        [isNaN, 1],
      );
    });

    test('returns an immutable Float32 snapshot without mutating inputs', () {
      final time = <List<double>>[
        [0, 0],
      ];
      final ratings = <List<double>>[
        [1, 4],
      ];
      final deltas = <double>[2, 7];
      final batch = FsrsTrainingBatch(
        timeHistories: time,
        ratingHistories: ratings,
        deltaTs: deltas,
        labels: const [1, 1],
        weights: const [1, 1],
      );

      final result = predictFsrsTrainingBatchRetrievability(batch, parameters);

      expect(result, hasLength(2));
      expect(() => result[0] = 0, throwsUnsupportedError);
      expect(() => result.add(0), throwsUnsupportedError);
      expect(time, [
        [0, 0]
      ]);
      expect(ratings, [
        [1, 4]
      ]);
      expect(deltas, [2, 7]);
      expect(
          result, result.map((value) => Float32List.fromList([value]).single));
    });

    test('composes with BCE without folding loss into prediction', () {
      final batch = FsrsTrainingBatch(
        timeHistories: [
          [0],
        ],
        ratingHistories: [
          [3],
        ],
        deltaTs: const [0],
        labels: const [1],
        weights: const [1],
      );
      final predictions =
          predictFsrsTrainingBatchRetrievability(batch, parameters);

      expect(
        calculateFsrsBinaryCrossEntropy(
          predictions,
          batch.labels.map((label) => label.toDouble()).toList(),
          batch.weights,
          reduction: FsrsBceReduction.mean,
        ),
        isA<double>(),
      );
    });

    test('rejects malformed parameter, matrix, batch, and numeric inputs', () {
      final valid = FsrsTrainingBatch(
        timeHistories: [
          [0],
        ],
        ratingHistories: [
          [3],
        ],
        deltaTs: const [1],
        labels: const [1],
        weights: const [1],
      );
      expect(
        () => predictFsrsTrainingBatchRetrievability(
            valid, parameters.take(20).toList()),
        throwsArgumentError,
      );
      expect(
        () => predictFsrsTrainingBatchRetrievability(
          FsrsTrainingBatch(
            timeHistories: [
              [0],
            ],
            ratingHistories: const [],
            deltaTs: const [1],
            labels: const [1],
            weights: const [1],
          ),
          parameters,
        ),
        throwsArgumentError,
      );
      expect(
        () => predictFsrsTrainingBatchRetrievability(
          FsrsTrainingBatch(
            timeHistories: const [],
            ratingHistories: const [],
            deltaTs: const [1],
            labels: const [],
            weights: const [1],
          ),
          parameters,
        ),
        throwsArgumentError,
      );
      expect(
        () => predictFsrsTrainingBatchRetrievability(
          FsrsTrainingBatch(
            timeHistories: [
              [double.nan],
            ],
            ratingHistories: [
              [3],
            ],
            deltaTs: const [1],
            labels: const [1],
            weights: const [1],
          ),
          parameters,
        ),
        throwsArgumentError,
      );
      expect(
        () => predictFsrsTrainingBatchRetrievability(
          valid,
          [...parameters.take(20), double.infinity],
        ),
        throwsArgumentError,
      );
    });
  });
}
