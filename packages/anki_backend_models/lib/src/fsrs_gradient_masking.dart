// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

const _fsrsParameterCount = 21;

/// Applies FSRS 5.2.0's training gradient freeze projections.
///
/// Initial-stability gradients occupy indices `[0, 4)` and short-term
/// stability gradients occupy `[17, 20)`. Values are converted using the
/// package's Float32 vector representation. The input is not modified.
Float32List maskFsrsParameterGradients(
  List<double> gradients, {
  required bool freezeInitialStability,
  required bool freezeShortTermStability,
}) {
  if (gradients.length != _fsrsParameterCount) {
    throw ArgumentError.value(
      gradients.length,
      'gradients.length',
      'must be $_fsrsParameterCount',
    );
  }

  final masked = Float32List.fromList(gradients);
  if (freezeInitialStability) {
    masked.fillRange(0, 4, 0.0);
  }
  if (freezeShortTermStability) {
    masked.fillRange(17, 20, 0.0);
  }
  return masked;
}
