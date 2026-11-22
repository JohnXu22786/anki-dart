// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'card.dart';
import 'ids.dart';
import 'revlog.dart';

const _fsrs5DefaultDecay = 0.5;
const _fsrs6DefaultDecay = 0.1542;
const _sMin = 0.001;
const _sMax = 36500.0;
const _dMin = 1.0;
const _dMax = 10.0;

/// Returns the decay that Core stores with cards for the selected parameter set.
double fsrsDecayFromParams(List<double> params) => _f32(
      params.isEmpty
          ? _fsrs6DefaultDecay
          : params.length < 21
              ? _fsrs5DefaultDecay
              : params[20],
    );

/// Computes a card's current FSRS memory state from its ordered review history.
///
/// [revlogs] must be the card's entries in ascending timestamp order, as returned
/// by Core's revlog query. [nextDayAt] and every revlog id use Unix seconds and
/// milliseconds respectively. No clock or storage access is performed here.
FsrsMemoryState? computeFsrsMemoryState({
  required List<RevlogEntry> revlogs,
  required TimestampSecs nextDayAt,
  required List<double> params,
  required double historicalRetention,
  required Int64 ignoreRevlogsBefore,
}) {
  final weights = _parameters(params);
  final projection = _reviewsForFsrs(
    revlogs,
    nextDayAt,
    weights,
    historicalRetention,
    ignoreRevlogsBefore,
  );
  if (projection == null) return null;

  var startingState = projection.startingState;
  for (var index = 0; index < projection.reviews.length; index++) {
    final review = projection.reviews[index];
    final state = startingState ?? const _Memory(0, 0);
    startingState = _step(weights, state, review.deltaT, review.rating, index);
  }
  final result = startingState!;
  if (!result.stability.isFinite || !result.difficulty.isFinite) {
    throw const InvalidModelValue('invalid FSRS memory state');
  }
  return FsrsMemoryState(
    stability: result.stability,
    difficulty: result.difficulty,
  );
}

List<double> _parameters(List<double> input) {
  final p = input.map(_f32).toList();
  if (p.isEmpty) {
    return <double>[
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
      _fsrs6DefaultDecay,
    ].map(_f32).toList();
  } else if (p.length == 17) {
    p[4] = _fma(p[5], 2, p[4]);
    p[5] = _div(_log(_fma(p[5], 3, 1)), 3);
    p[6] = _add(p[6], 0.5);
    p.addAll([0, 0, 0, _fsrs5DefaultDecay]);
  } else if (p.length == 19) {
    p.addAll([0, _fsrs5DefaultDecay]);
  } else if (p.length != 21) {
    throw const InvalidModelValue('invalid FSRS parameter length');
  }
  if (p.any((value) => !value.isFinite)) {
    throw const InvalidModelValue('invalid FSRS parameters');
  }

  final w17w18Ceiling =
      p.length > 17 ? 2.0 : 2.0; // FSRS inference uses one relearning step.
  final clamps = <(double, double)>[
    (_sMin, 100.0),
    (_sMin, 100.0),
    (_sMin, 100.0),
    (_sMin, 100.0),
    (_dMin, _dMax),
    (0.001, 4),
    (0.001, 4),
    (0.001, 0.75),
    (0, 4.5),
    (0, 0.8),
    (0.001, 3.5),
    (0.001, 5),
    (0.001, 0.25),
    (0.001, 0.9),
    (0, 4),
    (0, 1),
    (1, 6),
    (0, w17w18Ceiling),
    (0, w17w18Ceiling),
    (0, 0.8),
    (0.1, 0.8),
  ];
  for (var i = 0; i < p.length; i++) {
    p[i] = _f32(p[i].clamp(clamps[i].$1, clamps[i].$2));
  }
  return p;
}

class _Review {
  const _Review(this.rating, this.deltaT);
  final int rating;
  final int deltaT;
}

class _Projection {
  const _Projection(this.reviews, this.startingState);
  final List<_Review> reviews;
  final _Memory? startingState;
}

_Projection? _reviewsForFsrs(
  List<RevlogEntry> input,
  TimestampSecs nextDayAt,
  List<double> weights,
  double historicalRetention,
  Int64 cutoff,
) {
  final entries = List<RevlogEntry>.of(input);
  int? firstLearn;
  int? firstUserGrade;
  var complete = false;
  for (var index = entries.length - 1; index >= 0; index--) {
    final entry = entries[index];
    if (entry.isCramming) continue;
    final withinCutoff = entry.id.value > cutoff;
    final userGraded = entry.hasRating;
    final interday = entry.interval >= 1 || entry.interval <= -86400;
    if (userGraded && withinCutoff && interday) firstUserGrade = index;
    if (userGraded && entry.reviewKind == RevlogReviewKind.learning) {
      firstLearn = index;
      complete = true;
    } else if (entry.isReset) {
      if (firstLearn != null) {
        complete = true;
        break;
      } else if (firstUserGrade != null) {
        complete = false;
        break;
      } else {
        return null;
      }
    } else if (firstLearn != null) {
      break;
    }
  }

  if (firstLearn != null &&
      entries[firstLearn].id.value < cutoff &&
      firstLearn < entries.length - 1) {
    complete = false;
    firstLearn = null;
  }
  if (firstLearn != null) {
    entries.removeRange(0, firstLearn);
  } else if (firstUserGrade != null) {
    entries.removeRange(0, firstUserGrade);
  } else {
    return null;
  }
  entries.removeWhere((entry) => !entry.hasRatingAndAffectsScheduling);
  if (entries.isEmpty) return null;

  final reviews = <_Review>[];
  var previousDays = 0;
  for (var i = 0; i < entries.length; i++) {
    final secs = entries[i].id.asSecs();
    final elapsed = (nextDayAt - secs).toInt();
    final days = elapsed <= 0 ? 0 : elapsed ~/ 86400;
    reviews.add(
      _Review(entries[i].buttonChosen, i == 0 ? 0 : previousDays - days),
    );
    previousDays = days;
  }
  if (reviews.isEmpty) return null;
  if (complete) return _Projection(reviews, null);

  final first = entries.first;
  final interval = _f32(first.interval < 1 ? 1 : first.interval);
  final ease = _div(first.easeFactor == 0 ? 2500 : first.easeFactor, 1000);
  var start = _memoryFromSm2(weights, ease, interval, historicalRetention);
  if (ease <= 1.1) {
    start = _Memory(start.stability, _add(_mul(_sub(ease, 0.1), 9), 1));
  }
  // This first grade is represented by the inferred initial state instead.
  if (reviews.isNotEmpty) reviews.removeAt(0);
  return _Projection(reviews, start);
}

class _Memory {
  const _Memory(this.stability, this.difficulty);
  final double stability;
  final double difficulty;
}

_Memory _memoryFromSm2(
  List<double> w,
  double ease,
  double interval,
  double retention,
) {
  final decay = -w[20];
  final factor = _sub(_pow(0.9, _div(1, decay)), 1);
  final stability = _div(
    _mul(interval < _sMin ? _sMin : interval, factor),
    _sub(_pow(retention, _div(1, decay)), 1),
  );
  final difficulty = _sub(
    11,
    _div(
      _sub(ease, 1),
      _mul(
        _mul(_exp(w[8]), _pow(stability, -w[9])),
        _expm1(_mul(_sub(1, retention), w[10])),
      ),
    ),
  );
  if (!stability.isFinite || !difficulty.isFinite) {
    throw const InvalidModelValue('invalid FSRS memory state');
  }
  return _Memory(stability, _f32(difficulty.clamp(_dMin, _dMax)));
}

_Memory _step(List<double> w, _Memory state, int deltaT, int rating, int nth) {
  final s = _f32(state.stability.clamp(_sMin, _sMax));
  final d = _f32(state.difficulty.clamp(_dMin, _dMax));
  final factor = _sub(
    _exp(_mul(_div(1, -w[20]), _log(0.9))),
    1,
  );
  final r = _pow(
    _add(_mul(_div(deltaT, s), factor), 1),
    -w[20],
  );
  var successBonus = 1.0;
  if (rating == 2) successBonus = w[15];
  if (rating == 4) successBonus = w[16];
  var success = _mul(
    s,
    _add(
      _mul(
        _mul(
          _mul(_mul(_exp(w[8]), _sub(11, d)), _pow(s, -w[9])),
          _sub(_exp(_mul(_sub(1, r), w[10])), 1),
        ),
        successBonus,
      ),
      1,
    ),
  );
  final fail = _maxF32(
    _mul(
      _mul(_mul(w[11], _pow(d, -w[12])), _sub(_pow(_add(s, 1), w[13]), 1)),
      _exp(_mul(_sub(1, r), w[14])),
    ),
    _div(s, _exp(_mul(w[17], w[18]))),
  );
  var shortFactor = _mul(
    _exp(_mul(w[17], _add(rating - 3, w[18]))),
    _pow(s, -w[19]),
  );
  if (rating >= 3) shortFactor = _maxF32(shortFactor, 1);
  final shortTerm = _mul(s, shortFactor);
  var newS = rating == 1 ? fail : success;
  if (deltaT == 0) newS = shortTerm;

  final deltaD = _mul(-w[6], rating - 3);
  final updatedD = _add(d, _mul(_sub(10, d), _div(deltaD, 9)));
  var newD = _f32(
    _add(
      _mul(
        w[7],
        _sub(_add(_sub(w[4], _exp(_mul(w[5], 3))), 1), updatedD),
      ),
      updatedD,
    ).clamp(_dMin, _dMax),
  );
  if (nth == 0 && state.stability == 0) {
    final initRating = rating.clamp(1, 4);
    newS = w[initRating - 1];
    newD = _f32(
      _sub(
        _sub(w[4], _exp(_mul(w[5], initRating - 1))),
        -1,
      ).clamp(_dMin, _dMax),
    );
  }
  return _Memory(
    _f32(newS.clamp(_sMin, _sMax)),
    _f32(newD.clamp(_dMin, _dMax)),
  );
}

double _f32(num value) => (Float32List(1)..[0] = value.toDouble())[0];
double _add(num a, num b) => _f32(_f32(a) + _f32(b));
double _fma(num a, num b, num c) {
  final left = _dyadic(_f32(a));
  final right = _dyadic(_f32(b));
  final addend = _dyadic(_f32(c));
  if (left == null || right == null || addend == null) {
    return _f32(_f32(a) * _f32(b) + _f32(c));
  }
  final productSignificand = left.significand * right.significand;
  final productExponent = left.exponent + right.exponent;
  final commonExponent = math.min(productExponent, addend.exponent);
  final exact = (productSignificand << (productExponent - commonExponent)) +
      (addend.significand << (addend.exponent - commonExponent));
  return _roundDyadicToFloat32(exact, commonExponent);
}

class _Dyadic {
  const _Dyadic(this.significand, this.exponent);
  final BigInt significand;
  final int exponent;
}

_Dyadic? _dyadic(double value) {
  if (!value.isFinite) return null;
  final bytes = ByteData(4)..setFloat32(0, value, Endian.host);
  final bits = bytes.getUint32(0, Endian.host);
  final sign = bits >> 31 == 0 ? BigInt.one : -BigInt.one;
  final exponent = (bits >> 23) & 0xff;
  final fraction = bits & 0x7fffff;
  if (exponent == 0) {
    return _Dyadic(sign * BigInt.from(fraction), -149);
  }
  return _Dyadic(
    sign * BigInt.from((1 << 23) | fraction),
    exponent - 127 - 23,
  );
}

double _roundDyadicToFloat32(BigInt significand, int exponent) {
  if (significand == BigInt.zero) return 0;
  final negative = significand.isNegative;
  final magnitude = significand.abs();
  var topExponent = magnitude.bitLength - 1 + exponent;
  if (topExponent > 127)
    return negative ? double.negativeInfinity : double.infinity;

  if (topExponent >= -126) {
    final shift = magnitude.bitLength - 24;
    var rounded =
        shift > 0 ? _roundShiftToEven(magnitude, shift) : magnitude << -shift;
    if (rounded.bitLength > 24) {
      rounded >>= 1;
      topExponent++;
      if (topExponent > 127) {
        return negative ? double.negativeInfinity : double.infinity;
      }
    }
    final value = rounded.toDouble() * math.pow(2, topExponent - 23);
    return _f32(negative ? -value : value);
  }

  final shift = -(exponent + 149);
  final rounded =
      shift > 0 ? _roundShiftToEven(magnitude, shift) : magnitude << -shift;
  final value = rounded.toDouble() * math.pow(2, -149);
  return _f32(negative ? -value : value);
}

BigInt _roundShiftToEven(BigInt value, int shift) {
  final roundedDown = value >> shift;
  final remainder = value - (roundedDown << shift);
  final halfway = BigInt.one << (shift - 1);
  if (remainder > halfway || (remainder == halfway && roundedDown.isOdd)) {
    return roundedDown + BigInt.one;
  }
  return roundedDown;
}

double _sub(num a, num b) => _f32(_f32(a) - _f32(b));
double _mul(num a, num b) => _f32(_f32(a) * _f32(b));
double _div(num a, num b) => _f32(_f32(a) / _f32(b));
double _pow(num a, num b) => _f32(math.pow(_f32(a), _f32(b)));
double _exp(num a) => _f32(math.exp(_f32(a)));
double _log(num a) => _f32(math.log(_f32(a)));
double _expm1(num a) => _f32(math.exp(_f32(a)) - 1);
double _maxF32(double a, double b) => _f32(a >= b ? a : b);
