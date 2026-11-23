// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  // Source: rslib/src/scheduler/states/load_balancer.rs at
  // Anki Core commit e64c6b1aee3e8d668fb8bbe084beada8e070d985.
  test('interval one uses the unchanged next-day timestamp', () {
    final nextDayAt = _localTimestamp(2024, 3, 4, 12);

    expect(
        intervalToWeekday(1, nextDayAt), DateTime(2024, 3, 4, 12).weekday - 1);
  });

  test('weekday indices are Monday based from zero through six', () {
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final localDate = DateTime(2024, 1, 1 + dayOffset, 12);

      expect(
        intervalToWeekday(1, _timestamp(localDate)),
        localDate.weekday - 1,
      );
    }
  });

  test('interval seconds cross week, month, and year boundaries', () {
    final cases = [
      (DateTime(2024, 1, 5, 12), DateTime(2024, 1, 6, 12)),
      (DateTime(2024, 1, 31, 12), DateTime(2024, 2, 1, 12)),
      (DateTime(2024, 12, 31, 12), DateTime(2025, 1, 1, 12)),
    ];

    for (final (start, target) in cases) {
      expect(
        intervalToWeekday(2, _timestamp(start)),
        target.weekday - 1,
      );
    }
  });

  test('adds absolute seconds before projecting through local timezone', () {
    final nextDayAt = TimestampSecs(
      DateTime.utc(2024, 3, 10, 6, 30).millisecondsSinceEpoch ~/ 1000,
    );
    final target = DateTime.fromMillisecondsSinceEpoch(
      (nextDayAt.toInt() + Duration.secondsPerDay) * 1000,
      isUtc: true,
    ).toLocal();

    expect(intervalToWeekday(2, nextDayAt), target.weekday - 1);
  });

  test('rejects invalid u32 interval values', () {
    final nextDayAt = TimestampSecs(0);

    for (final interval in [0, -1, 0x100000000]) {
      expect(
        () => intervalToWeekday(interval, nextDayAt),
        throwsArgumentError,
      );
    }
  });

  test('rejects timestamps outside the representable local date range', () {
    for (final timestamp in [
      TimestampSecs.parseInt('9223372036854775807'),
      TimestampSecs.parseInt('-9223372036854775808'),
    ]) {
      expect(() => intervalToWeekday(1, timestamp), throwsRangeError);
    }
  });
}

TimestampSecs _timestamp(DateTime localDate) =>
    TimestampSecs(localDate.millisecondsSinceEpoch ~/ 1000);

TimestampSecs _localTimestamp(int year, int month, int day, int hour) =>
    _timestamp(DateTime(year, month, day, hour));
