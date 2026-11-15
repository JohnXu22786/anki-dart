// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_scheduler_timing/anki_scheduler_timing.dart';

void main() {
  if (currentDueDay(daysElapsed: 0xffffffff, delta: 2) != 1 ||
      currentDueDay(daysElapsed: 0x80000000, delta: 0x7fffffff) != 0 ||
      currentDueDay(daysElapsed: 0x7fffffff, delta: 1) != 0) {
    throw StateError('due-day signed conversion is incorrect');
  }
  if (isUnixEpochTimestamp(1000000000) || !isUnixEpochTimestamp(1000000001)) {
    throw StateError('epoch due threshold is incorrect');
  }

  const now = 8_000_000_000_000;
  final result = schedTimingTodayV2New(
    creationSecs: now - 86400,
    creationUtcOffsetMinutesWest: 0,
    currentSecs: now,
    currentUtcOffsetMinutesWest: 0,
    rolloverHour: 0,
  );
  if (result.now != now || result.daysElapsed != 1) {
    throw StateError('large timestamp lost precision');
  }
  final boundary = schedTimingTodayV2New(
    creationSecs: 0,
    creationUtcOffsetMinutesWest: 0,
    currentSecs: 8_210_266_794_000,
    currentUtcOffsetMinutesWest: 0,
    rolloverHour: 4,
  );
  if (boundary.nextDayAt != 8_210_266_804_800) {
    throw StateError(
      'next rollover at the source timestamp limit is incorrect',
    );
  }
  const yearOneEpoch = -62135596800;
  final ancient = schedTimingTodayV2New(
    creationSecs: yearOneEpoch + 2 * 3600,
    creationUtcOffsetMinutesWest: 0,
    currentSecs: yearOneEpoch + 86400 + 4 * 3600,
    currentUtcOffsetMinutesWest: 0,
    rolloverHour: 4,
  );
  if (ancient.daysElapsed != 1 ||
      ancient.nextDayAt != yearOneEpoch + 2 * 86400 + 4 * 3600) {
    throw StateError('year 1 Gregorian rollover is incorrect');
  }

  final legacy = schedTimingTodayV1(creationSecs: -86400, currentSecs: 0);
  if (legacy.daysElapsed != 1 || legacy.nextDayAt != 86400) {
    throw StateError('legacy v1 elapsed-day calculation is incorrect');
  }
  final dispatched = schedTimingToday(
    creationSecs: 1533564000,
    currentSecs: 1584491078,
    currentUtcOffsetMinutesWest: -600,
    rolloverHour: 0,
  );
  if (dispatched.daysElapsed != 589 || dispatched.nextDayAt != 1584540000) {
    throw StateError('legacy scheduler dispatch is incorrect');
  }
}
