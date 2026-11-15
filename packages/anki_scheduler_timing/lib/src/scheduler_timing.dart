// SPDX-License-Identifier: AGPL-3.0-or-later

/// Day timing returned by [schedTimingTodayV2New].
class SchedTimingToday {
  const SchedTimingToday({
    required this.now,
    required this.daysElapsed,
    required this.nextDayAt,
  });

  /// The supplied current Unix timestamp in seconds.
  final int now;

  /// Number of rollovers since collection creation, clipped at zero.
  final int daysElapsed;

  /// Unix timestamp in seconds of the next rollover.
  final int nextDayAt;
}

/// Computes today's scheduler timing using fixed offsets supplied by the host.
///
/// Offsets are whole minutes west of UTC (for example, UTC-6 is `360`, and
/// UTC+10 is `-600`). Timestamps use Unix seconds. No machine timezone is
/// consulted. The rollover hour follows the source `u8` behavior and wraps
/// modulo 24.
SchedTimingToday schedTimingTodayV2New({
  required int creationSecs,
  required int creationUtcOffsetMinutesWest,
  required int currentSecs,
  required int currentUtcOffsetMinutesWest,
  required int rolloverHour,
}) {
  _validateOffset(creationUtcOffsetMinutesWest);
  _validateOffset(currentUtcOffsetMinutesWest);
  if (rolloverHour < 0 || rolloverHour > 255) {
    throw ArgumentError.value(rolloverHour, 'rolloverHour', 'expected a u8');
  }

  final created = _localDateTime(creationSecs, creationUtcOffsetMinutesWest);
  final now = _localDateTime(currentSecs, currentUtcOffsetMinutesWest);
  final rollover = rolloverHour % 24;
  final rolloverToday = DateTime.utc(now.year, now.month, now.day, rollover);
  final rolloverPassed = !rolloverToday.isAfter(now);
  // Compute the next wall-clock rollover from its civil day number. At the
  // upper DateTime limit, the following day itself cannot be constructed as a
  // DateTime even though its Unix seconds remain exactly representable.
  final nextDayAt =
      (_civilDay(now) + (rolloverPassed ? 1 : 0)) * Duration.secondsPerDay +
      rollover * Duration.secondsPerHour +
      currentUtcOffsetMinutesWest * 60;

  final dateDifference = _civilDay(now) - _civilDay(created);
  final elapsed = (rolloverPassed ? dateDifference : dateDifference - 1)
      .clamp(0, 0xffffffff)
      .toInt();

  return SchedTimingToday(
    now: currentSecs,
    daysElapsed: elapsed,
    nextDayAt: nextDayAt,
  );
}

// Chrono 0.4.41's NaiveDate range is narrower than DateTime's shared VM/JS
// range. DateTime::from_timestamp() rejects values outside these endpoints.
const _minSourceTimestampSeconds = -8334601228800;
const _maxSourceTimestampSeconds = 8210266876799;

void _validateOffset(int minutesWest) {
  if (minutesWest < -1439 || minutesWest > 1439) {
    throw ArgumentError.value(minutesWest, 'minutesWest', 'invalid UTC offset');
  }
}

DateTime _localDateTime(int timestampSecs, int minutesWest) {
  if (timestampSecs < _minSourceTimestampSeconds ||
      timestampSecs > _maxSourceTimestampSeconds) {
    throw ArgumentError.value(
      timestampSecs,
      'timestampSecs',
      'invalid timestamp',
    );
  }
  final offsetSeconds = -minutesWest * 60;
  final localMillis = (timestampSecs + offsetSeconds) * 1000;
  try {
    return DateTime.fromMillisecondsSinceEpoch(localMillis, isUtc: true);
  } on RangeError {
    throw ArgumentError.value(
      timestampSecs,
      'timestampSecs',
      'invalid timestamp',
    );
  }
}

int _civilDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;
