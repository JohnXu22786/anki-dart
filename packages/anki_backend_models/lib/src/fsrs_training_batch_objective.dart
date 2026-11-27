// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'fsrs_binary_cross_entropy.dart';
import 'fsrs_l2_regularization.dart';

/// Composes the scalar FSRS training batch objective in Float32 arithmetic.
///
/// The result is the Sum-reduced weighted binary cross entropy over the
/// already-computed [retrievabilities] plus the batch-scaled L2 penalty over
/// the model parameter vectors. This calculates only a scalar objective; it
/// does not calculate gradients or update an optimizer.
double calculateFsrsTrainingBatchObjective(
  List<double> retrievabilities,
  List<double> labels,
  List<double> weights,
  List<double> currentParameters,
  List<double> initialParameters,
  List<double> parameterStddevs, {
  required int batchSize,
  required int totalSize,
  required double gamma,
}) {
  final loss = calculateFsrsBinaryCrossEntropy(
    retrievabilities,
    labels,
    weights,
    reduction: FsrsBceReduction.sum,
  );
  final penalty = calculateFsrsL2Regularization(
    currentParameters,
    initialParameters,
    parameterStddevs,
    batchSize: batchSize,
    totalSize: totalSize,
    gamma: gamma,
  );
  final storage = Float32List(1);
  storage[0] = loss + penalty;
  return storage[0];
}
