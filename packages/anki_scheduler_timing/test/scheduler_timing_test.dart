// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_scheduler_timing/anki_scheduler_timing.dart';
import 'package:test/test.dart';

int _stamp(int year, int month, int day, int hour, {int west = 0}) =>
    DateTime.utc(year, month, day, hour).millisecondsSinceEpoch ~/ 1000 +
    west * 60;

void main() {
  group('today timing', () {
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
