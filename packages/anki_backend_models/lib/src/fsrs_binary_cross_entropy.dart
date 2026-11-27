// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

/// Burn's binary-cross-entropy reduction modes used by FSRS 5.2.0.
enum FsrsBceReduction { mean, sum, auto }

/// Computes weighted FSRS binary cross entropy with Float32 operation order.
///
/// [retrievabilities], [labels], and [weights] are parallel lists. Predictions
/// must be finite values from 0 through 1, labels must be exactly 0 or 1, and
/// weights must be finite, nonnegative Float32 values. Predictions at 0 or 1
/// are not clamped: logarithm endpoints can produce infinity or NaN as in
/// Core's Burn calculation.
///
/// Empty input follows Burn's reductions: `Sum` is 0, while `Mean` and `Auto`
/// produce NaN (0 divided by 0). `Auto` also produces NaN when the total weight
/// is zero. Callers that need a finite loss must handle these source-defined
/// edge results explicitly.
double calculateFsrsBinaryCrossEntropy(
  List<double> retrievabilities,
  List<double> labels,
  List<double> weights, {
  required FsrsBceReduction reduction,
}) {
  if (retrievabilities.length != labels.length ||
      retrievabilities.length != weights.length) {
    throw ArgumentError(
        'retrievabilities, labels, and weights must have equal lengths');
  }

  final storage = Float32List(1);
  double f32(double value) {
    storage[0] = value;
    return storage[0];
  }

  for (var index = 0; index < retrievabilities.length; index++) {
    final prediction = retrievabilities[index];
    if (!prediction.isFinite || prediction < 0.0 || prediction > 1.0) {
      throw ArgumentError.value(
        prediction,
        'retrievabilities[$index]',
        'must be a finite value from 0 through 1',
      );
    }
    final label = labels[index];
    if (label != 0.0 && label != 1.0) {
      throw ArgumentError.value(
        label,
        'labels[$index]',
        'must be exactly 0 or 1',
      );
    }
    final weight = weights[index];
    if (!weight.isFinite || weight < 0.0 || !f32(weight).isFinite) {
      throw ArgumentError.value(
        weight,
        'weights[$index]',
        'must be a finite nonnegative Float32 value',
      );
    }
  }

  var weightedLogLosses = 0.0;
  var totalWeight = 0.0;
  for (var index = 0; index < retrievabilities.length; index++) {
    final prediction = f32(retrievabilities[index]);
    final label = f32(labels[index]);
    final weight = f32(weights[index]);

    // Keep the tensor source's operation order: weighted log terms are summed
    // first, then the selected reduction is negated.
    final logPrediction = f32(math.log(prediction));
    final recalledTerm = f32(label * logPrediction);
    final notLabel = f32(f32(-label) + 1.0);
    final notPrediction = f32(f32(-prediction) + 1.0);
    final logNotPrediction = f32(math.log(notPrediction));
    final forgottenTerm = f32(notLabel * logNotPrediction);
    final logLoss = f32(recalledTerm + forgottenTerm);
    final weightedLogLoss = f32(logLoss * weight);
    weightedLogLosses = f32(weightedLogLosses + weightedLogLoss);
    totalWeight = f32(totalWeight + weight);
  }

  switch (reduction) {
    case FsrsBceReduction.mean:
      final mean =
          f32(weightedLogLosses / f32(retrievabilities.length.toDouble()));
      return f32(-mean);
    case FsrsBceReduction.sum:
      return f32(-weightedLogLosses);
    case FsrsBceReduction.auto:
      final normalized = f32(weightedLogLosses / totalWeight);
      return f32(-normalized);
  }
}
