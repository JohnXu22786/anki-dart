// SPDX-License-Identifier: AGPL-3.0-or-later
import 'fsrs_training_batch.dart';
import 'fsrs_training_batch_objective.dart';
import 'fsrs_training_predictions.dart';

/// Calculates the FSRS 5.2.0 validation loss for caller-ordered [batches].
///
/// Each batch contributes its Sum BCE and L2 penalty scaled by that batch's
/// item count and the training set's [totalSize]. The Float32 batch objectives
/// are accumulated as Float64 and divided by the total number of validation
/// items. An empty batch list returns NaN, matching the source's `0 / 0` result.
///
/// This is validation scoring only: it does not shuffle batches, select or copy
/// the best model, report progress, or update parameters. Inputs are not
/// modified. Malformed batches and invalid model inputs are rejected by the
/// prediction and objective helpers.
double calculateFsrsValidationLoss(
  List<FsrsTrainingBatch> batches,
  List<double> currentParameters,
  List<double> initialParameters,
  List<double> parameterStddevs, {
  required int totalSize,
  required double gamma,
}) {
  var totalLoss = 0.0;
  var validationItemCount = 0;
  for (final batch in batches) {
    final retrievabilities =
        predictFsrsTrainingBatchRetrievability(batch, currentParameters);
    final batchSize = batch.deltaTs.length;
    final loss = calculateFsrsTrainingBatchObjective(
      retrievabilities,
      batch.labels.map((label) => label.toDouble()).toList(),
      batch.weights,
      currentParameters,
      initialParameters,
      parameterStddevs,
      batchSize: batchSize,
      totalSize: totalSize,
      gamma: gamma,
    );
    totalLoss += loss;
    validationItemCount += batchSize;
  }

  if (validationItemCount == 0) return double.nan;
  return totalLoss / validationItemCount;
}
