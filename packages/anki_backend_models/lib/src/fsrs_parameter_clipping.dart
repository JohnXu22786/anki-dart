// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

const _parameterCount = 21;
const _stabilityMax = 100.0;
const _difficultyMin = 1.0;
const _difficultyMax = 10.0;

/// Clips FSRS 5.2.0 optimizer parameters to their source-defined ranges.
///
/// Parameters use Float32 precision, and the relearning-step bound for
/// parameters 17 and 18 follows FSRS's Float32 operation and rounding order.
/// Dart's transcendental functions may produce a different final Float32 bit
/// than Rust's platform-dependent `f32::powf`; Rust does not specify that
/// function's precision. Inputs shorter than 21 values retain their length;
/// values after index 20 are preserved after Float32 conversion. The returned
/// snapshot is immutable and the caller's list is not modified.
///
/// When [numRelearningSteps] is greater than one, [parameters] must contain at
/// least 15 values because the source ceiling formula reads indices 11, 13,
/// and 14. Negative step counts are rejected.
List<double> clipFsrsParameters(
  List<double> parameters, {
  required int numRelearningSteps,
  required bool enableShortTerm,
}) {
  if (numRelearningSteps < 0) {
    throw ArgumentError.value(
      numRelearningSteps,
      'numRelearningSteps',
      'must not be negative',
    );
  }
  if (numRelearningSteps > 1 && parameters.length < 15) {
    throw ArgumentError.value(
      parameters.length,
      'parameters',
      'must contain at least 15 values when numRelearningSteps is greater than 1',
    );
  }

  final values = Float32List.fromList(parameters);
  final ceiling = numRelearningSteps > 1
      ? _relearningParameterCeiling(values, numRelearningSteps)
      : 2.0;
  final shortTermFloor = enableShortTerm ? 0.01 : 0.0;
  final limits = <(double, double)>[
    for (var index = 0; index < 4; index++) (0.001, _stabilityMax),
    (_difficultyMin, _difficultyMax),
    (0.001, 4.0),
    (0.001, 4.0),
    (0.001, 0.75),
    (0.0, 4.5),
    (0.0, 0.8),
    (0.001, 3.5),
    (0.001, 5.0),
    (0.001, 0.25),
    (0.001, 0.9),
    (0.0, 4.0),
    (0.0, 1.0),
    (1.0, 6.0),
    (0.0, ceiling),
    (0.0, ceiling),
    (shortTermFloor, 0.8),
    (0.1, 0.8),
  ];

  for (var index = 0;
      index < values.length && index < _parameterCount;
      index++) {
    final (low, high) = limits[index];
    final value = values[index];
    if (value < low) {
      values[index] = low;
    } else if (value > high) {
      values[index] = high;
    }
  }
  return List<double>.unmodifiable(values);
}

double _relearningParameterCeiling(Float32List parameters, int stepCount) {
  // Preserve the f32 rounding after each Rust operation. Rust converts the
  // usize step count to f32 before dividing.
  final w11Log = _f32(math.log(parameters[11]));
  final w13Pow = _f32(math.pow(2.0, parameters[13]).toDouble());
  final powMinusOne = _f32(w13Pow - 1.0);
  final powLog = _f32(math.log(powMinusOne));
  final retentionTerm = _f32(parameters[14] * _f32(0.3));
  final firstSum = _f32(w11Log + powLog);
  final sum = _f32(firstSum + retentionTerm);
  final numerator = _f32(-sum);
  final denominator = _f32(stepCount.toDouble());
  final quotient = _f32(numerator / denominator);
  // Rust f32::max/min return the numeric operand when the other is NaN.
  final floorApplied = quotient.isNaN || quotient < 0.01 ? 0.01 : quotient;
  final root = _f32(math.sqrt(floorApplied));
  return root.isNaN || root > 2.0 ? 2.0 : root;
}

double _f32(double value) {
  final storage = Float32List(1);
  storage[0] = value;
  return storage[0];
}
