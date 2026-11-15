// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_scheduler_timing/anki_scheduler_timing.dart';
import 'package:test/test.dart';

int _stamp(int year, int month, int day, int hour, {int west = 0}) =>
    DateTime.utc(year, month, day, hour).millisecondsSinceEpoch ~/ 1000 +
    west * 60;

void main() {
  group('scheduler timing helpers', () {
    test('current due day casts elapsed u32 to i32 before applying delta', () {
      expect(currentDueDay(daysElapsed: 8, delta: -3), 5);
      expect(currentDueDay(daysElapsed: 2, delta: -3), 0);
      // Rust's `u32 as i32` cast keeps the low 32 bits, then interprets them
      // as signed before adding the delta.
      expect(currentDueDay(daysElapsed: 0x80000000, delta: 0x7fffffff), 0);
      expect(currentDueDay(daysElapsed: 0xffffffff, delta: 2), 1);
      // The source addition is i32 arithmetic, so release builds wrap before
      // applying max(0).
      expect(currentDueDay(daysElapsed: 0x7fffffff, delta: 1), 0);
    });

    test('epoch due detection uses a strict threshold', () {
      expect(isUnixEpochTimestamp(999999999), isFalse);
      expect(isUnixEpochTimestamp(1000000000), isFalse);
      expect(isUnixEpochTimestamp(1000000001), isTrue);
      expect(isUnixEpochTimestamp(0x7fffffff), isTrue);
    });
  });

  group('today timing', () {
    test(
      'v1 uses fixed elapsed days and preserves signed conversion behavior',
      () {
        const created = 1_577_617_200; // 2019-12-01 03:00 UTC
        final sameDay = schedTimingTodayV1(
          creationSecs: created,
          currentSecs: created + 86_399,
        );
        expect(sameDay.daysElapsed, 0);
        expect(sameDay.nextDayAt, created + 86_400);

        final nextDay = schedTimingTodayV1(
          creationSecs: created,
          currentSecs: created + 86_400,
        );
        expect(nextDay.daysElapsed, 1);
        expect(nextDay.nextDayAt, created + 172_800);

        final preEpoch = schedTimingTodayV1(
          creationSecs: -86_400,
          currentSecs: 0,
        );
        expect(preEpoch.daysElapsed, 1);
        expect(preEpoch.nextDayAt, 86_400);

        // Rust signed division truncates toward zero before the result is cast
        // to u32, including for timestamps before the Unix epoch/creation.
        final beforeCreation = schedTimingTodayV1(
          creationSecs: created,
          currentSecs: created - 86_400,
        );
        expect(beforeCreation.daysElapsed, 0xffffffff);
        expect(beforeCreation.nextDayAt, created);
      },
    );

    test('v2 legacy uses current offset and an exclusive next rollover', () {
      const now = 1_584_491_078;
      final atRollover = schedTimingTodayV2Legacy(
        creationSecs: 1_533_564_000,
        rolloverHour: 0,
        currentSecs: now,
        currentUtcOffsetMinutesWest: -600,
      );
      expect(atRollover.daysElapsed, 589);
      expect(atRollover.nextDayAt, 1_584_540_000);

      final fourAm = schedTimingTodayV2Legacy(
        creationSecs: 1_524_038_400,
        rolloverHour: 4,
        currentSecs: now,
        currentUtcOffsetMinutesWest: -600,
      );
      expect(fourAm.daysElapsed, 700);
      expect(fourAm.nextDayAt, 1_584_554_400);

      final before = schedTimingTodayV2Legacy(
        creationSecs: _stamp(2018, 8, 6, 3, west: 360),
        rolloverHour: 4,
        currentSecs: _stamp(2018, 8, 9, 3, west: 420),
        currentUtcOffsetMinutesWest: 420,
      );
      final at = schedTimingTodayV2Legacy(
        creationSecs: _stamp(2018, 8, 6, 3, west: 360),
        rolloverHour: 4,
        currentSecs: _stamp(2018, 8, 9, 4, west: 420),
        currentUtcOffsetMinutesWest: 420,
      );
      expect(before.daysElapsed, 2);
      expect(at.daysElapsed, 3);
      expect(at.nextDayAt, at.now);
    });

    test('dispatcher selects timing from optional settings', () {
      final creation = _stamp(2018, 8, 6, 0, west: 360);
      final now = _stamp(2018, 8, 9, 3, west: 420);
      final v1 = schedTimingToday(
        creationSecs: creation,
        currentSecs: now,
        currentUtcOffsetMinutesWest: 420,
      );
      final legacy = schedTimingToday(
        creationSecs: creation,
        currentSecs: now,
        currentUtcOffsetMinutesWest: 420,
        rolloverHour: 4,
      );
      final v2New = schedTimingToday(
        creationSecs: creation,
        currentSecs: now,
        creationUtcOffsetMinutesWest: 360,
        currentUtcOffsetMinutesWest: 420,
        rolloverHour: 4,
      );

      expect(v1.daysElapsed, 3);
      expect(v1.nextDayAt, creation + 4 * 86_400);
      expect(legacy.daysElapsed, 3);
      expect(legacy.nextDayAt, _stamp(2018, 8, 9, 4, west: 420));
      expect(v2New.daysElapsed, 2);
      expect(v2New.nextDayAt, _stamp(2018, 8, 9, 4, west: 420));
    });

    test('v1 creation cutoff uses the supplied local offset', () {
      final beforeFour = v1CreationDate(
        nowSecs: _stamp(2020, 5, 10, 1, west: -600),
        localUtcOffsetMinutesWest: -600,
      );
      expect(beforeFour, _stamp(2020, 5, 9, 4, west: -600));

      final afterFour = v1CreationDate(
        nowSecs: _stamp(2020, 5, 10, 9, west: -600),
        localUtcOffsetMinutesWest: -600,
      );
      expect(afterFour, _stamp(2020, 5, 10, 4, west: -600));

      expect(fixedOffsetFromMinutes(5000), 1380);
      expect(fixedOffsetFromMinutes(-5000), -1380);
      expect(
        () => v1CreationDate(
          nowSecs: 8_210_266_876_800,
          localUtcOffsetMinutesWest: 0,
        ),
        throwsArgumentError,
      );
    });

    test('before, at, and after rollover use an inclusive boundary', () {
      final creation = _stamp(2019, 1, 1, 2);
      final before = schedTimingTodayV2New(
        creationSecs: creation,
        creationUtcOffsetMinutesWest: 0,
        currentSecs: _stamp(2019, 1, 3, 3) + 59 * 60 + 59,
        currentUtcOffsetMinutesWest: 0,
        rolloverHour: 4,
      );
      expect(before.daysElapsed, 1);
      expect(before.nextDayAt, _stamp(2019, 1, 3, 4));

      final at = schedTimingTodayV2New(
        creationSecs: creation,
        creationUtcOffsetMinutesWest: 0,
        currentSecs: _stamp(2019, 1, 3, 4),
        currentUtcOffsetMinutesWest: 0,
        rolloverHour: 4,
      );
      expect(at.daysElapsed, 2);
      expect(at.nextDayAt, _stamp(2019, 1, 4, 4));

      final after = schedTimingTodayV2New(
        creationSecs: creation,
        creationUtcOffsetMinutesWest: 0,
        currentSecs: _stamp(2019, 1, 3, 7),
        currentUtcOffsetMinutesWest: 0,
        rolloverHour: 4,
      );
      expect(after.daysElapsed, 2);
      expect(after.nextDayAt, _stamp(2019, 1, 4, 4));

      // Chrono uses proleptic Gregorian year 1; it must not be shifted to
      // 1901 by platform date constructors.
      const yearOneEpoch = -62135596800;
      final ancient = schedTimingTodayV2New(
        creationSecs: yearOneEpoch + 2 * 3600,
        creationUtcOffsetMinutesWest: 0,
        currentSecs: yearOneEpoch + 86400 + 4 * 3600,
        currentUtcOffsetMinutesWest: 0,
        rolloverHour: 4,
      );
      expect(ancient.daysElapsed, 1);
      expect(ancient.nextDayAt, yearOneEpoch + 2 * 86400 + 4 * 3600);
    });

    test('clips elapsed days and uses each supplied fixed offset', () {
      final same = _stamp(2019, 12, 1, 2, west: -360);
      expect(
        schedTimingTodayV2New(
          creationSecs: same,
          creationUtcOffsetMinutesWest: -360,
          currentSecs: same - 86400,
          currentUtcOffsetMinutesWest: -360,
          rolloverHour: 4,
        ).daysElapsed,
        0,
      );

      // Creation time is 03:00 MDT (UTC-6); current time is 04:00 MST
      // (UTC-7), representing a caller supplied DST-like offset change.
      final result = schedTimingTodayV2New(
        creationSecs: _stamp(2018, 8, 6, 3, west: 360),
        creationUtcOffsetMinutesWest: 360,
        currentSecs: _stamp(2018, 8, 9, 4, west: 420),
        currentUtcOffsetMinutesWest: 420,
        rolloverHour: 4,
      );
      expect(result.daysElapsed, 3);
      expect(result.nextDayAt, _stamp(2018, 8, 10, 4, west: 420));
    });

    test(
      'validates timestamp and offset limits and wraps u8 rollover hours',
      () {
        expect(
          () => schedTimingTodayV2New(
            creationSecs: 0,
            creationUtcOffsetMinutesWest: 1440,
            currentSecs: 0,
            currentUtcOffsetMinutesWest: 0,
            rolloverHour: 4,
          ),
          throwsArgumentError,
        );
        expect(
          () => schedTimingTodayV2New(
            creationSecs: 0,
            creationUtcOffsetMinutesWest: 0,
            currentSecs: 8_210_266_876_800,
            currentUtcOffsetMinutesWest: 0,
            rolloverHour: 4,
          ),
          throwsArgumentError,
        );
        expect(
          () => schedTimingTodayV2New(
            creationSecs: 0,
            creationUtcOffsetMinutesWest: 0,
            currentSecs: 8_640_000_000_001,
            currentUtcOffsetMinutesWest: 0,
            rolloverHour: 4,
          ),
          throwsArgumentError,
        );
        expect(
          () => schedTimingTodayV2New(
            creationSecs: 0,
            creationUtcOffsetMinutesWest: 0,
            currentSecs: 0,
            currentUtcOffsetMinutesWest: 0,
            rolloverHour: 256,
          ),
          throwsArgumentError,
        );
        final sourceLimit = schedTimingTodayV2New(
          creationSecs: 0,
          creationUtcOffsetMinutesWest: 0,
          currentSecs: 8_210_266_794_000,
          currentUtcOffsetMinutesWest: 0,
          rolloverHour: 4,
        );
        expect(sourceLimit.nextDayAt, 8_210_266_804_800);

        final result = schedTimingTodayV2New(
          creationSecs: _stamp(2024, 1, 1, 0),
          creationUtcOffsetMinutesWest: 0,
          currentSecs: _stamp(2024, 1, 1, 1),
          currentUtcOffsetMinutesWest: 0,
          rolloverHour: 255, // 255 % 24 == 15
        );
        expect(result.nextDayAt, _stamp(2024, 1, 1, 15));
      },
    );

    test(
      'preserves large seconds exactly on JavaScript safe integer range',
      () {
        const large = 8_000_000_000_000;
        final result = schedTimingTodayV2New(
          creationSecs: large - 86400,
          creationUtcOffsetMinutesWest: 0,
          currentSecs: large,
          currentUtcOffsetMinutesWest: 0,
          rolloverHour: 0,
        );
        expect(result.now, large);
        expect(result.daysElapsed, 1);
        expect(result.nextDayAt, large + 86400 - large % 86400);
      },
    );
  });
}
