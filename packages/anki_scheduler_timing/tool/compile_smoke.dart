// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_scheduler_timing/anki_scheduler_timing.dart';

void main() {
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
}
