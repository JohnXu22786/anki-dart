// SPDX-License-Identifier: AGPL-3.0-or-later

/// Identifies the parameters selected by the FSRS training branch decision.
enum FsrsTrainingParameterSource { defaults, initialized, optimizer }

/// The result of selecting the early-return branch in FSRS training.
///
/// A `null` [parameters] value with [FsrsTrainingParameterSource.optimizer]
/// means the caller must continue into optimizer training. This result only
/// represents the branch decision; it does not prepare data, initialize model
/// parameters, or train a model.
class FsrsTrainingParameterSelection {
  FsrsTrainingParameterSelection._({
    required this.source,
    required List<double>? parameters,
  }) : parameters = parameters == null ? null : List.unmodifiable(parameters);

  /// The selected result branch.
  final FsrsTrainingParameterSource source;

  /// An immutable snapshot of the selected parameters, or `null` when
  /// optimizer training is required.
  final List<double>? parameters;
}

/// Selects the FSRS 5.2.0 training result branch from already-computed inputs.
///
/// Fewer than eight retained training items select [defaultParameters].
/// Otherwise, equal training and initialization counts or fewer than 64
/// retained items select [initializedParameters]. Remaining cases require
/// optimizer training and return no parameters. Both 21-value parameter
/// vectors must contain only finite values; they are validated regardless of
/// which branch is selected. This helper makes the result-selection decision
/// only and does not perform training-data preparation, initialization, or
/// optimization.
FsrsTrainingParameterSelection selectFsrsTrainingParameters({
  required int trainingItemCount,
  required int initializationItemCount,
  required List<double> defaultParameters,
  required List<double> initializedParameters,
}) {
  if (trainingItemCount < 0) {
    throw ArgumentError.value(trainingItemCount, 'trainingItemCount');
  }
  if (initializationItemCount < 0) {
    throw ArgumentError.value(
        initializationItemCount, 'initializationItemCount');
  }
  _validateParameters(defaultParameters, 'defaultParameters');
  _validateParameters(initializedParameters, 'initializedParameters');

  if (trainingItemCount < 8) {
    return FsrsTrainingParameterSelection._(
      source: FsrsTrainingParameterSource.defaults,
      parameters: defaultParameters,
    );
  }
  if (trainingItemCount == initializationItemCount || trainingItemCount < 64) {
    return FsrsTrainingParameterSelection._(
      source: FsrsTrainingParameterSource.initialized,
      parameters: initializedParameters,
    );
  }
  return FsrsTrainingParameterSelection._(
    source: FsrsTrainingParameterSource.optimizer,
    parameters: null,
  );
}

void _validateParameters(List<double> parameters, String name) {
  if (parameters.length != 21) {
    throw ArgumentError.value(parameters.length, '$name.length', 'must be 21');
  }
  for (var index = 0; index < parameters.length; index++) {
    if (!parameters[index].isFinite) {
      throw ArgumentError.value(
          parameters[index], '$name[$index]', 'must be finite');
    }
  }
}
