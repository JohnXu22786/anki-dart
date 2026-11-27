// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

const _defaultFsrsTrainingParameters = <double>[
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

/// Projects optional initial stabilities into a Float32 FSRS training model
/// initialization vector using FSRS 5.2.0 defaults for the remaining weights.
///
/// When [initialStability] is supplied, it must contain exactly four values.
/// If [freezeShortTermStability] is true, weights 17 through 19 are set to
/// zero. The returned 21-value snapshot is immutable and does not modify the
/// input list.
List<double> initializeFsrsTrainingModelParameters({
  List<double>? initialStability,
  required bool freezeShortTermStability,
}) {
  if (initialStability != null && initialStability.length != 4) {
    throw ArgumentError.value(
      initialStability.length,
      'initialStability.length',
      'must contain exactly four values',
    );
  }

  final parameters = Float32List.fromList(_defaultFsrsTrainingParameters);
  if (initialStability != null) {
    for (var index = 0; index < 4; index++) {
      parameters[index] = initialStability[index];
    }
  }
  if (freezeShortTermStability) {
    parameters[17] = 0;
    parameters[18] = 0;
    parameters[19] = 0;
  }
  return List<double>.unmodifiable(parameters);
}
