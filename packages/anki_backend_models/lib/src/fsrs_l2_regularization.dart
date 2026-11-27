// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

/// Computes the FSRS 5.2.0 L2 penalty with Float32 tensor arithmetic.
///
/// The parameter lists are parallel and are read in their supplied order.
/// [gamma], [batchSize], and [totalSize] determine the Float64 scale that is
/// applied to the accumulated Float32 tensor value. Inputs are not modified.
double calculateFsrsL2Regularization(
  List<double> currentParameters,
  List<double> initialParameters,
  List<double> parameterStddevs, {
  required int batchSize,
  required int totalSize,
  required double gamma,
}) {
  if (currentParameters.length != initialParameters.length ||
      currentParameters.length != parameterStddevs.length) {
    throw ArgumentError(
      'currentParameters, initialParameters, and parameterStddevs must have equal lengths',
    );
  }
  if (batchSize < 0) {
    throw ArgumentError.value(batchSize, 'batchSize', 'must be nonnegative');
  }
  if (totalSize < 0) {
    throw ArgumentError.value(totalSize, 'totalSize', 'must be nonnegative');
  }
  if (totalSize == 0) {
    throw ArgumentError.value(
        totalSize, 'totalSize', 'must be greater than zero');
  }
  if (!gamma.isFinite || gamma < 0.0) {
    throw ArgumentError.value(gamma, 'gamma', 'must be finite and nonnegative');
  }

  final storage = Float32List(1);
  double f32(double value) {
    storage[0] = value;
    return storage[0];
  }

  for (var index = 0; index < currentParameters.length; index++) {
    _validateFloat32(
        currentParameters[index], 'currentParameters[$index]', f32);
    _validateFloat32(
        initialParameters[index], 'initialParameters[$index]', f32);
    final stddev = _validateFloat32(
      parameterStddevs[index],
      'parameterStddevs[$index]',
      f32,
    );
    if (stddev <= 0.0) {
      throw ArgumentError.value(
        parameterStddevs[index],
        'parameterStddevs[$index]',
        'must be positive when represented as Float32',
      );
    }
  }

  final scale = gamma * batchSize.toDouble() / totalSize.toDouble();
  if (!scale.isFinite || !f32(scale).isFinite) {
    throw ArgumentError.value(
      scale,
      'gamma * batchSize / totalSize',
      'must be finite when represented as Float32',
    );
  }
  if (batchSize == 0) return 0.0;

  final terms = <double>[];
  for (var index = 0; index < currentParameters.length; index++) {
    final difference = f32(
      f32(currentParameters[index]) - f32(initialParameters[index]),
    );
    final squaredDifference = f32(difference * difference);
    final stddev = f32(parameterStddevs[index]);
    final squaredStddev = f32(stddev * stddev);
    final normalizedSquare = f32(squaredDifference / squaredStddev);
    terms.add(normalizedSquare);
  }

  // Burn's tensor reduction uses an order-preserving pairwise Float32 sum.
  double sumRange(int start, int end) {
    final length = end - start;
    if (length == 0) return 0.0;
    if (length == 1) return terms[start];
    final middle = start + length ~/ 2;
    return f32(sumRange(start, middle) + sumRange(middle, end));
  }

  final sum = sumRange(0, terms.length);
  return f32(sum * f32(scale));
}

double _validateFloat32(
  double value,
  String name,
  double Function(double) f32,
) {
  if (!value.isFinite || !f32(value).isFinite) {
    throw ArgumentError.value(value, name, 'must be finite as a Float32 value');
  }
  return f32(value);
}
