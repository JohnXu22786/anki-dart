// SPDX-License-Identifier: AGPL-3.0-or-later

/// An immutable snapshot of an FSRS model and its validation loss.
///
/// The caller supplies model parameters and validation loss that it has
/// already computed.
class FsrsBestModelSnapshot {
  FsrsBestModelSnapshot({
    required this.validationLoss,
    required List<double> parameters,
  }) : parameters = List<double>.unmodifiable(parameters);

  final double validationLoss;
  final List<double> parameters;
}

/// Returns a snapshot of the model with the lower validation loss.
///
/// Candidate selection uses strict floating-point comparison, so equal,
/// greater, and NaN candidate losses preserve [currentBest].
FsrsBestModelSnapshot selectFsrsBestModel({
  required FsrsBestModelSnapshot currentBest,
  required FsrsBestModelSnapshot candidate,
}) {
  final selected = candidate.validationLoss < currentBest.validationLoss
      ? candidate
      : currentBest;
  return FsrsBestModelSnapshot(
    validationLoss: selected.validationLoss,
    parameters: selected.parameters,
  );
}
