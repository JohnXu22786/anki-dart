// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

import 'fsrs_training_batch.dart';

const _trainingParameterCount = 21;
const _stabilityMin = 0.001;
const _stabilityMax = 36500.0;
const _difficultyMin = 1.0;
const _difficultyMax = 10.0;

/// Predicts the current-review retrievability for each item in a packed FSRS
/// training batch using exactly 21 FSRS 5.2.0 training parameters.
///
/// History rows are processed in sequence-major order and padding rating zero
/// retains the clamped state. The immutable Float32 result is suitable for
/// composition with [calculateFsrsBinaryCrossEntropy]; this function applies
/// no loss/reduction or optimizer step and does not affect scheduler inference.
/// With no history, the source model's zero initial stability is preserved.
///
/// Throws [ArgumentError] for malformed batch shapes or nonfinite/out-of-domain
/// inputs.
List<double> predictFsrsTrainingBatchRetrievability(
  FsrsTrainingBatch batch,
  List<double> parameters,
) {
  if (parameters.length != _trainingParameterCount) {
    throw ArgumentError.value(
      parameters.length,
      'parameters.length',
      'must contain exactly $_trainingParameterCount FSRS training values',
    );
  }
  final weights = Float32List(_trainingParameterCount);
  for (var index = 0; index < parameters.length; index++) {
    final value = parameters[index];
    if (!value.isFinite || !_f32(value).isFinite) {
      throw ArgumentError.value(
        value,
        'parameters[$index]',
        'must be finite as a Float32 value',
      );
    }
    weights[index] = value;
  }
  if (weights[20] <= 0) {
    throw ArgumentError.value(
      parameters[20],
      'parameters[20]',
      'must be positive for the FSRS power forgetting curve',
    );
  }

  final batchSize = batch.deltaTs.length;
  if (batchSize == 0) {
    throw ArgumentError.value(
        batchSize, 'batch.deltaTs.length', 'must not be zero');
  }
  if (batch.labels.length != batchSize || batch.weights.length != batchSize) {
    throw ArgumentError(
      'batch deltaTs, labels, and weights must have equal lengths',
    );
  }
  if (batch.timeHistories.length != batch.ratingHistories.length) {
    throw ArgumentError(
      'batch timeHistories and ratingHistories must have equal row counts',
    );
  }
  for (var rowIndex = 0; rowIndex < batch.timeHistories.length; rowIndex++) {
    final timeRow = batch.timeHistories[rowIndex];
    final ratingRow = batch.ratingHistories[rowIndex];
    if (timeRow.length != batchSize || ratingRow.length != batchSize) {
      throw ArgumentError.value(
        rowIndex,
        'batch history row',
        'each sequence-major history row must have $batchSize values',
      );
    }
  }

  for (var item = 0; item < batchSize; item++) {
    _validateNonnegative(batch.deltaTs[item], 'batch.deltaTs[$item]');
    final label = batch.labels[item];
    if (label != 0 && label != 1) {
      throw ArgumentError.value(
        label,
        'batch.labels[$item]',
        'must be exactly 0 or 1',
      );
    }
    _validateNonnegative(batch.weights[item], 'batch.weights[$item]');
    if (!_f32(batch.weights[item]).isFinite) {
      throw ArgumentError.value(
        batch.weights[item],
        'batch.weights[$item]',
        'must be finite as a Float32 value',
      );
    }
  }
  for (var row = 0; row < batch.timeHistories.length; row++) {
    for (var item = 0; item < batchSize; item++) {
      _validateNonnegative(
        batch.timeHistories[row][item],
        'batch.timeHistories[$row][$item]',
      );
      final rating = batch.ratingHistories[row][item];
      if (!rating.isFinite ||
          rating < 0 ||
          rating > 4 ||
          rating != rating.roundToDouble()) {
        throw ArgumentError.value(
          rating,
          'batch.ratingHistories[$row][$item]',
          'must be a finite FSRS rating from 0 through 4',
        );
      }
    }
  }

  final stability = List<double>.filled(batchSize, 0);
  final difficulty = List<double>.filled(batchSize, 0);
  for (var row = 0; row < batch.timeHistories.length; row++) {
    for (var item = 0; item < batchSize; item++) {
      final lastS = _clamp32(stability[item], _stabilityMin, _stabilityMax);
      final lastD = _clamp32(difficulty[item], _difficultyMin, _difficultyMax);
      final deltaT = _f32(batch.timeHistories[row][item]);
      final rating = _f32(batch.ratingHistories[row][item]);
      var newS = _trainingStepStability(weights, lastS, lastD, deltaT, rating);
      var newD = _trainingStepDifficulty(weights, lastD, rating);
      if (row == 0 && stability[item] == 0) {
        final initRating = rating.clamp(1, 4);
        newS = weights[initRating.toInt() - 1];
        newD = _clamp32(
          _add32(_sub32(weights[4], _exp32(_mul32(weights[5], initRating - 1))),
              1),
          _difficultyMin,
          _difficultyMax,
        );
      }
      if (rating == 0) {
        // Padding preserves the current state, including its zero initial
        // value, rather than initializing a card from a padded row.
        newS = stability[item] == 0 ? stability[item] : lastS;
        newD = difficulty[item] == 0 ? difficulty[item] : lastD;
      }
      stability[item] = rating == 0 && stability[item] == 0
          ? 0
          : _clamp32(newS, _stabilityMin, _stabilityMax);
      difficulty[item] = rating == 0 && difficulty[item] == 0
          ? 0
          : _clamp32(newD, _difficultyMin, _difficultyMax);
    }
  }

  final result = <double>[];
  for (var item = 0; item < batchSize; item++) {
    result.add(_trainingPowerForgettingCurve(
      weights,
      _f32(batch.deltaTs[item]),
      stability[item],
    ));
  }
  return List<double>.unmodifiable(result);
}

void _validateNonnegative(double value, String name) {
  if (!value.isFinite || value < 0 || !_f32(value).isFinite) {
    throw ArgumentError.value(
        value, name, 'must be a finite nonnegative Float32 value');
  }
}

double _trainingStepStability(
  List<double> w,
  double s,
  double d,
  double deltaT,
  double rating,
) {
  final factor = _sub32(_exp32(_mul32(_div32(1, -w[20]), _log32(0.9))), 1);
  final retrievability = _pow32(
    _add32(_mul32(_div32(deltaT, s), factor), 1),
    -w[20],
  );
  var successBonus = 1.0;
  if (rating == 2) successBonus = w[15];
  if (rating == 4) successBonus = w[16];
  final success = _mul32(
    s,
    _add32(
      _mul32(
        _mul32(
          _mul32(_mul32(_exp32(w[8]), _sub32(11, d)), _pow32(s, -w[9])),
          _sub32(_exp32(_mul32(_sub32(1, retrievability), w[10])), 1),
        ),
        successBonus,
      ),
      1,
    ),
  );
  final failure = _max32(
    _mul32(
      _mul32(
        _mul32(w[11], _pow32(d, -w[12])),
        _sub32(_pow32(_add32(s, 1), w[13]), 1),
      ),
      _exp32(_mul32(_sub32(1, retrievability), w[14])),
    ),
    _div32(s, _exp32(_mul32(w[17], w[18]))),
  );
  var shortFactor = _mul32(
    _exp32(_mul32(w[17], _add32(rating - 3, w[18]))),
    _pow32(s, -w[19]),
  );
  if (rating >= 3) shortFactor = _max32(shortFactor, 1);
  final shortTerm = _mul32(s, shortFactor);
  return deltaT == 0
      ? shortTerm
      : rating == 1
          ? failure
          : success;
}

double _trainingStepDifficulty(List<double> w, double d, double rating) {
  final deltaD = _mul32(-w[6], rating - 3);
  final updatedD = _add32(d, _mul32(_sub32(10, d), _div32(deltaD, 9)));
  final initialDifficulty = _add32(
    _sub32(w[4], _exp32(_mul32(w[5], 3))),
    1,
  );
  return _clamp32(
    _add32(_mul32(w[7], _sub32(initialDifficulty, updatedD)), updatedD),
    _difficultyMin,
    _difficultyMax,
  );
}

double _trainingPowerForgettingCurve(List<double> w, double t, double s) {
  final decay = -w[20];
  final factor = _sub32(
    _exp32(_mul32(_div32(1, decay), _log32(0.9))),
    1,
  );
  return _pow32(_add32(_mul32(_div32(t, s), factor), 1), decay);
}

double _f32(num value) => (Float32List(1)..[0] = value.toDouble())[0];
double _add32(num a, num b) => _f32(_f32(a) + _f32(b));
double _sub32(num a, num b) => _f32(_f32(a) - _f32(b));
double _mul32(num a, num b) => _f32(_f32(a) * _f32(b));
double _div32(num a, num b) => _f32(_f32(a) / _f32(b));
double _pow32(num a, num b) => _f32(math.pow(_f32(a), _f32(b)));
double _exp32(num value) => _f32(math.exp(_f32(value)));
double _log32(num value) => _f32(math.log(_f32(value)));
double _max32(num a, num b) {
  final left = _f32(a);
  final right = _f32(b);
  return _f32(left > right ? left : right);
}

double _clamp32(num value, num min, num max) =>
    _f32(_f32(value).clamp(_f32(min), _f32(max)));
