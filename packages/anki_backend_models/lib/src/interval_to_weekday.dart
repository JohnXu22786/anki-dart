// SPDX-License-Identifier: AGPL-3.0-or-later
import 'ids.dart';

/// Projects an interval's target timestamp to a Monday-based local weekday.
///
/// [nextDayAt] is the absolute Unix timestamp used by scheduler timing. The
/// interval offset is applied in seconds before the target timestamp is
/// projected to the machine's local timezone, matching Anki Core's
/// `interval_to_weekday()` behavior.
///
/// [interval] must be a nonzero u32. Throws [ArgumentError] otherwise and
/// [RangeError] when the resulting timestamp cannot be represented by Dart's
/// local date-time implementation.
int intervalToWeekday(int interval, TimestampSecs nextDayAt) {
  if (interval < 1 || interval > 0xffffffff) {
    throw ArgumentError.value(interval, 'interval', 'must be a nonzero u32');
  }

  final targetSeconds = BigInt.parse(nextDayAt.toString()) +
      BigInt.from(interval - 1) * BigInt.from(86400);
  final targetMilliseconds = targetSeconds * BigInt.from(1000);
  const maxDateTimeMilliseconds = 8640000000000000;
  final maxMilliseconds = BigInt.from(maxDateTimeMilliseconds);
  if (targetMilliseconds < -maxMilliseconds ||
      targetMilliseconds > maxMilliseconds) {
    throw RangeError('target timestamp is outside the DateTime range');
  }

  try {
    return DateTime.fromMillisecondsSinceEpoch(
          targetMilliseconds.toInt(),
          isUtc: true,
        ).toLocal().weekday -
        1;
  } on RangeError {
    throw RangeError('target timestamp is outside the local DateTime range');
  }
}
