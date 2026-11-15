// SPDX-License-Identifier: AGPL-3.0-or-later

/// Day timing returned by a scheduler timing function.
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

/// Returns the current scheduler due day after applying a signed day offset.
///
/// This follows Anki Core's `((days_elapsed as i32) + delta).max(0) as u32`
/// conversion: elapsed days are first reinterpreted as signed 32-bit, then
/// the signed delta is added with 32-bit wrapping and the result is floored at
/// zero.
int currentDueDay({required int daysElapsed, required int delta}) {
  if (daysElapsed < 0 || daysElapsed > 0xffffffff) {
    throw ArgumentError.value(daysElapsed, 'daysElapsed', 'expected a u32');
  }
  if (delta < -0x80000000 || delta > 0x7fffffff) {
    throw ArgumentError.value(delta, 'delta', 'expected an i32');
  }
  final elapsedSigned = daysElapsed.toSigned(32);
  return (elapsedSigned + delta).toSigned(32).clamp(0, 0xffffffff).toInt();
}

/// Returns whether [due] is a seconds-based Unix timestamp.
///
/// Anki Core identifies these values with the strict threshold `due >
/// 1_000_000_000`; the argument is an i32 in the source API.
bool isUnixEpochTimestamp(int due) {
  if (due < -0x80000000 || due > 0x7fffffff) {
    throw ArgumentError.value(due, 'due', 'expected an i32');
  }
  return due > 1_000_000_000;
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

/// Scheduler timing for the legacy v1 scheduler.
///
/// This version counts fixed 86,400-second periods from collection creation;
/// timezone offsets and daylight saving transitions do not affect its days.
SchedTimingToday schedTimingTodayV1({
  required int creationSecs,
  required int currentSecs,
}) {
  final daysElapsed = (currentSecs - creationSecs) ~/ Duration.secondsPerDay;
  return SchedTimingToday(
    now: currentSecs,
    daysElapsed: daysElapsed.toUnsigned(32),
    nextDayAt: creationSecs + (daysElapsed + 1) * Duration.secondsPerDay,
  );
}

/// Builds the legacy v2 fixed offset, clamping whole minutes west of UTC to
/// the range accepted by Chrono's `FixedOffset::west_opt` call path.
int fixedOffsetFromMinutes(int minutesWest) => minutesWest.clamp(-1380, 1380);

/// Computes legacy v2 timing using the current UTC offset for both collection
/// creation and current time. This preserves the original cutoff behavior.
SchedTimingToday schedTimingTodayV2Legacy({
  required int creationSecs,
  required int rolloverHour,
  required int currentSecs,
  required int currentUtcOffsetMinutesWest,
}) {
  _validateOffset(currentUtcOffsetMinutesWest);
  _validateRolloverHour(rolloverHour);

  final offset = currentUtcOffsetMinutesWest;
  final created = _localDateTime(creationSecs, offset);
  final now = _localDateTime(currentSecs, offset);
  final rollover = rolloverHour % 24;
  final creationRollover = _rolloverTimestamp(created, rollover, offset);
  final daysElapsed =
      ((currentSecs - creationRollover) ~/ Duration.secondsPerDay).toUnsigned(
        32,
      );
  var nextDayAt = _rolloverTimestamp(now, rollover, offset);
  if (nextDayAt < currentSecs) {
    nextDayAt += Duration.secondsPerDay;
  }

  return SchedTimingToday(
    now: currentSecs,
    daysElapsed: daysElapsed,
    nextDayAt: nextDayAt,
  );
}

/// Selects the scheduler timing implementation from the collection settings.
///
/// Supply the UTC offsets in minutes west of UTC from the platform's timezone
/// adapter. The scheduler calculation itself does not inspect machine-local
/// timezone state.
SchedTimingToday schedTimingToday({
  required int creationSecs,
  required int currentSecs,
  int? creationUtcOffsetMinutesWest,
  required int currentUtcOffsetMinutesWest,
  int? rolloverHour,
}) {
  if (rolloverHour == null) {
    return schedTimingTodayV1(
      creationSecs: creationSecs,
      currentSecs: currentSecs,
    );
  }
  if (creationUtcOffsetMinutesWest == null) {
    return schedTimingTodayV2Legacy(
      creationSecs: creationSecs,
      rolloverHour: rolloverHour,
      currentSecs: currentSecs,
      currentUtcOffsetMinutesWest: currentUtcOffsetMinutesWest,
    );
  }
  return schedTimingTodayV2New(
    creationSecs: creationSecs,
    creationUtcOffsetMinutesWest: creationUtcOffsetMinutesWest,
    currentSecs: currentSecs,
    currentUtcOffsetMinutesWest: currentUtcOffsetMinutesWest,
    rolloverHour: rolloverHour,
  );
}

/// Returns the v1 collection creation cutoff using the supplied local offset.
///
/// Pass the platform-provided local offset in minutes west of UTC; this
/// function does not query the host timezone.
int v1CreationDate({
  required int nowSecs,
  required int localUtcOffsetMinutesWest,
}) {
  final offset = fixedOffsetFromMinutes(localUtcOffsetMinutesWest);
  final now = _localDateTime(nowSecs, offset);
  final rolloverAt = _rolloverTimestamp(now, 4, offset);
  return rolloverAt > nowSecs
      ? rolloverAt - Duration.secondsPerDay
      : rolloverAt;
}

int _rolloverTimestamp(DateTime localDate, int rolloverHour, int minutesWest) {
  final localMillis = DateTime.utc(
    localDate.year,
    localDate.month,
    localDate.day,
    rolloverHour,
  ).millisecondsSinceEpoch;
  return localMillis ~/ Duration.millisecondsPerSecond + minutesWest * 60;
}

void _validateRolloverHour(int rolloverHour) {
  if (rolloverHour < 0 || rolloverHour > 255) {
    throw ArgumentError.value(rolloverHour, 'rolloverHour', 'expected a u8');
  }
}
