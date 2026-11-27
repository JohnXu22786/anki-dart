// SPDX-License-Identifier: AGPL-3.0-or-later
// Adapted from Burn 0.17.1 burn-core/src/optim/adam.rs (Apache-2.0 OR MIT).
import 'dart:math' as math;
import 'dart:typed_data';

final _fsrsAdamBeta1 = _f32(0.9);
final _fsrsAdamBeta2 = _f32(0.999);
const _maxFsrsAdamTime = 0x7fffffff;
const _fsrsAdamEpsilon = 1e-8;

/// Immutable Float32 snapshot of Burn-compatible Adam optimizer moments.
class FsrsAdamState {
  FsrsAdamState({
    required this.time,
    required List<double> firstMoment,
    required List<double> secondMoment,
  })  : firstMoment = _immutableFiniteFloat32(firstMoment, 'firstMoment'),
        secondMoment = _immutableFiniteFloat32(secondMoment, 'secondMoment') {
    if (time <= 0 || time > _maxFsrsAdamTime) {
      throw ArgumentError.value(time, 'time', 'must be in [1, 2^31 - 1]');
    }
    if (this.firstMoment.length != this.secondMoment.length) {
      throw ArgumentError('Adam moments must have equal lengths');
    }
  }

  /// Number of completed Adam updates represented by this state.
  final int time;

  /// First order moment, stored as an immutable Float32 vector.
  final List<double> firstMoment;

  /// Second order moment, stored as an immutable Float32 vector.
  final List<double> secondMoment;
}

/// Immutable result of one [stepFsrsAdam] update.
class FsrsAdamStepResult {
  FsrsAdamStepResult({
    required List<double> parameters,
    required this.state,
  }) : parameters = _immutableFiniteFloat32(parameters, 'parameters');

  /// Updated Float32 parameter vector.
  final List<double> parameters;

  /// New immutable optimizer state.
  final FsrsAdamState state;
}

/// Applies one pure FSRS-configured Adam update to a vector of parameters.
///
/// This follows Burn 0.17.1's `AdaptiveMomentum::transform()` and `Adam::step()`
/// with FSRS 5.2.0's beta values and epsilon. Inputs are externally computed
/// gradients; this helper does not calculate or clip them, and applies no weight
/// decay. All arithmetic results are rounded to Float32 in operation order.
/// The input lists and optional [state] are never mutated.
FsrsAdamStepResult stepFsrsAdam(
  List<double> parameters,
  List<double> gradients, {
  required double learningRate,
  FsrsAdamState? state,
}) {
  if (parameters.length != gradients.length) {
    throw ArgumentError('Parameters and gradients must have equal lengths');
  }
  if (state != null &&
      (state.firstMoment.length != gradients.length ||
          state.secondMoment.length != gradients.length)) {
    throw ArgumentError(
        'Parameters, gradients, and moments must have equal lengths');
  }
  if (!learningRate.isFinite || learningRate <= 0) {
    throw ArgumentError.value(
      learningRate,
      'learningRate',
      'must be finite and positive',
    );
  }
  _validateFinite(parameters, 'parameters');
  _validateFinite(gradients, 'gradients');

  final time = state == null ? 1 : state.time + 1;
  if (time > _maxFsrsAdamTime) {
    throw ArgumentError.value(time, 'time', 'exceeds Burn Float32 Adam time');
  }
  final moment1 = Float32List(gradients.length);
  final moment2 = Float32List(gradients.length);
  final updated = Float32List(parameters.length);
  final beta1Factor = _f32(_f32(1.0) - _fsrsAdamBeta1);
  final beta2Factor = _f32(_f32(1.0) - _fsrsAdamBeta2);

  for (var index = 0; index < gradients.length; index++) {
    final gradient = _f32(gradients[index]);
    if (state == null) {
      moment1[index] = _f32(gradient * beta1Factor);
      final squaredGradient = _f32(math.pow(gradient, 2).toDouble());
      moment2[index] = _f32(squaredGradient * beta2Factor);
    } else {
      final previousMoment1 = _f32(state.firstMoment[index]);
      final previousMoment2 = _f32(state.secondMoment[index]);
      final weightedMoment1 = _f32(previousMoment1 * _fsrsAdamBeta1);
      final weightedGradient1 = _f32(gradient * beta1Factor);
      moment1[index] = _f32(weightedMoment1 + weightedGradient1);

      final squaredGradient = _f32(math.pow(gradient, 2).toDouble());
      final weightedMoment2 = _f32(previousMoment2 * _fsrsAdamBeta2);
      final weightedGradient2 = _f32(squaredGradient * beta2Factor);
      moment2[index] = _f32(weightedMoment2 + weightedGradient2);
    }
  }

  final beta1Power = _f32(math.pow(_fsrsAdamBeta1, time).toDouble());
  final beta2Power = _f32(math.pow(_fsrsAdamBeta2, time).toDouble());
  final moment1Correction = _f32(1.0 - beta1Power);
  final moment2Correction = _f32(1.0 - beta2Power);
  final floatEpsilon = _f32(_fsrsAdamEpsilon);
  final floatLearningRate = _f32(learningRate);

  for (var index = 0; index < gradients.length; index++) {
    final correctedMoment1 = _f32(moment1[index] / moment1Correction);
    final correctedMoment2 = _f32(moment2[index] / moment2Correction);
    final denominator = _f32(_f32(math.sqrt(correctedMoment2)) + floatEpsilon);
    final normalizedGradient = _f32(correctedMoment1 / denominator);
    final delta = _f32(normalizedGradient * floatLearningRate);
    updated[index] = _f32(_f32(parameters[index]) - delta);
  }

  _validateFinite(moment1, 'firstMoment');
  _validateFinite(moment2, 'secondMoment');
  _validateFinite(updated, 'parameters');
  return FsrsAdamStepResult(
    parameters: updated,
    state: FsrsAdamState(
      time: time,
      firstMoment: moment1,
      secondMoment: moment2,
    ),
  );
}

List<double> _immutableFiniteFloat32(List<double> values, String name) {
  _validateFinite(values, name);
  return List<double>.unmodifiable(Float32List.fromList(values));
}

void _validateFinite(List<double> values, String name) {
  for (var index = 0; index < values.length; index++) {
    if (!values[index].isFinite || !_f32(values[index]).isFinite) {
      throw ArgumentError.value(
          values[index], '$name[$index]', 'must be finite');
    }
  }
}

double _f32(double value) => (Float32List(1)..[0] = value)[0];
