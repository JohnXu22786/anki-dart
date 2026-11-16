// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sqlite3/common.dart';

import 'lossless_json.dart';

const _defaultFsrs5Decay = 0.5;
const _secondsPerDay = 86400;
const _learningDueThreshold = 365000;

/// Installs Core's FSRS retrievability SQLite functions.
void registerFsrsRetrievabilityFunctions(CommonDatabase database) {
  database.createFunction(
    functionName: 'extract_fsrs_retrievability',
    argumentCount: const AllowedArgumentCount(6),
    deterministic: true,
    directOnly: false,
    function: (arguments) => extractFsrsRetrievability(
      arguments[0],
      arguments[1],
      arguments[2],
      arguments[3],
      arguments[4],
      arguments[5],
    ),
  );
  database.createFunction(
    functionName: 'extract_fsrs_relative_retrievability',
    argumentCount: const AllowedArgumentCount(6),
    deterministic: true,
    directOnly: false,
    function: (arguments) => extractFsrsRelativeRetrievability(
      arguments[0],
      arguments[1],
      arguments[2],
      arguments[3],
      arguments[4],
      arguments[5],
    ),
  );
}

/// Mirrors Core's six-argument `extract_fsrs_retrievability` UDF.
double? extractFsrsRetrievability(
  Object? rawCardData,
  Object? rawDue,
  Object? rawInterval,
  Object? rawToday,
  Object? rawNextDayAt,
  Object? rawNow,
) {
  final data = _FsrsCardData.parse(rawCardData);
  if (data == null) return null;
  final due = _integer(rawDue);
  final now = _integer(rawNow);
  if (due == null || now == null) return null;

  late final BigInt secondsElapsed;
  if (data.lastReviewTime != null) {
    secondsElapsed = _saturatingU32Subtract(now, data.lastReviewTime!);
  } else if (due > BigInt.from(_learningDueThreshold)) {
    final interval = _integer(rawInterval);
    if (interval == null) return null;
    final lastReviewTime = _saturatingU32Subtract(due, interval);
    secondsElapsed = _saturatingU32Subtract(now, lastReviewTime);
  } else {
    final interval = _integer(rawInterval);
    final today = _integer(rawToday);
    if (interval == null || today == null) return null;
    final reviewDay = _saturatingU32Subtract(due, interval);
    secondsElapsed = _u32Multiply(
      _saturatingU32Subtract(today, reviewDay),
      _secondsPerDay,
    );
  }
  final state = data.memoryState;
  if (state == null) return null;
  return _currentRetrievabilitySeconds(
    state.$1,
    secondsElapsed,
    data.decay ?? _defaultFsrs5Decay,
  );
}

/// Mirrors Core's `extract_fsrs_relative_retrievability` UDF.
double? extractFsrsRelativeRetrievability(
  Object? rawCardData,
  Object? rawDue,
  Object? rawInterval,
  Object? rawToday,
  Object? rawNextDayAt,
  Object? rawNow,
) {
  final due = _integer(rawDue);
  final interval = _integer(rawInterval);
  final now = _integer(rawNow);
  if (due == null || interval == null || now == null) return null;

  late final BigInt secondsElapsed;
  if (due > BigInt.from(_learningDueThreshold)) {
    secondsElapsed = _saturatingU32Subtract(now, due);
  } else {
    final today = _integer(rawToday);
    if (today == null) return null;
    final reviewDay = _saturatingI64Subtract(due, interval);
    secondsElapsed = _u32Multiply(
      _saturatingU32Subtract(today, reviewDay),
      _secondsPerDay,
    );
  }

  final data = _FsrsCardData.parse(rawCardData);
  final state = data?.memoryState;
  final desiredRetention = data?.desiredRetention;
  if (data != null && state != null && desiredRetention != null) {
    final decay = data.decay ?? _defaultFsrs5Decay;
    final retention = _f32Max(desiredRetention, 0.0001);
    final current = _f32Max(
      _currentRetrievabilitySeconds(
        state.$1,
        data.lastReviewTime == null
            ? secondsElapsed
            : _saturatingU32Subtract(now, data.lastReviewTime!),
        decay,
      ),
      0.0001,
    );
    final exponent = _f32(-_f32(1.0 / decay));
    final currentTerm = _f32Subtract(_powF32(current, exponent), 1.0);
    final retentionTerm = _f32Subtract(_powF32(retention, exponent), 1.0);
    return _f32(_f32(-currentTerm) / retentionTerm);
  }

  final daysElapsed = (secondsElapsed ~/ BigInt.from(_secondsPerDay)).toInt();
  final numerator = _f32Add(_f32(daysElapsed.toDouble()), 0.001);
  final denominator = _f32Max(losslessJsonFloat32(interval)!, 1.0);
  return _f32(_f32(-numerator) / denominator);
}

BigInt? _integer(Object? value) {
  if (value is int) return BigInt.from(value);
  if (value is BigInt &&
      value >= BigInt.parse('-9223372036854775808') &&
      value <= BigInt.parse('9223372036854775807')) {
    return value;
  }
  return null;
}

BigInt _u32(BigInt value) => value & BigInt.from(0xffffffff);

BigInt _saturatingU32Subtract(BigInt left, BigInt right) {
  final lhs = _u32(left);
  final rhs = _u32(right);
  return lhs > rhs ? lhs - rhs : BigInt.zero;
}

BigInt _u32Multiply(BigInt left, int right) =>
    (left * BigInt.from(right)) & BigInt.from(0xffffffff);

BigInt _saturatingI64Subtract(BigInt left, BigInt right) {
  final difference = left - right;
  final minimum = BigInt.parse('-9223372036854775808');
  final maximum = BigInt.parse('9223372036854775807');
  if (difference < minimum) return minimum;
  if (difference > maximum) return maximum;
  return difference;
}

double _currentRetrievabilitySeconds(
  double stability,
  BigInt secondsElapsed,
  double decay,
) {
  final daysElapsed = _f32(_f32(secondsElapsed.toDouble()) / _f32(86400));
  final exponentForFactor = _f32(1.0 / _f32(-decay));
  final factor = _f32Subtract(_powF32(0.9, exponentForFactor), 1.0);
  final elapsedOverStability = _f32(daysElapsed / stability);
  final base = _f32Add(_f32(elapsedOverStability * factor), 1.0);
  return _powF32(base, _f32(-decay));
}

double _powF32(double base, double exponent) =>
    _f32(math.pow(_f32(base), _f32(exponent)).toDouble());

double _f32(double value) {
  final bytes = ByteData(4)..setFloat32(0, value);
  return bytes.getFloat32(0);
}

double _f32Add(double left, double right) => _f32(_f32(left) + _f32(right));

double _f32Subtract(double left, double right) =>
    _f32(_f32(left) - _f32(right));

double _f32Max(double left, double right) {
  if (left.isNaN) return right;
  if (right.isNaN) return left;
  return left > right ? left : right;
}

final class _FsrsCardData {
  const _FsrsCardData({
    required this.stability,
    required this.difficulty,
    required this.desiredRetention,
    required this.decay,
    required this.lastReviewTime,
  });

  final double? stability;
  final double? difficulty;
  final double? desiredRetention;
  final double? decay;
  final BigInt? lastReviewTime;

  (double, double)? get memoryState {
    final stability = this.stability;
    final difficulty = this.difficulty;
    if (stability == null || difficulty == null) return null;
    return (stability, difficulty);
  }

  static _FsrsCardData? parse(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      final decoded = parseLosslessCardData(raw);
      if (decoded is! Map<String, Object?> ||
          (decoded.containsKey('cd') && decoded['cd'] is! String)) {
        return const _FsrsCardData(
          stability: null,
          difficulty: null,
          desiredRetention: null,
          decay: null,
          lastReviewTime: null,
        );
      }
      return _FsrsCardData(
        stability: _cardFloat(decoded['s']),
        difficulty: _cardFloat(decoded['d']),
        desiredRetention: _cardFloat(decoded['dr']),
        decay: _cardFloat(decoded['decay']),
        lastReviewTime: _cardI64(decoded['lrt']),
      );
    } on FormatException {
      return const _FsrsCardData(
        stability: null,
        difficulty: null,
        desiredRetention: null,
        decay: null,
        lastReviewTime: null,
      );
    }
  }
}

double? _cardFloat(Object? value) {
  return losslessJsonFloat32(value);
}

BigInt? _cardI64(Object? value) {
  final integer = losslessJsonInteger(value);
  if (integer == null ||
      integer < BigInt.parse('-9223372036854775808') ||
      integer > BigInt.parse('9223372036854775807')) {
    return null;
  }
  return integer;
}
