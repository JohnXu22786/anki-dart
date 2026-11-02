/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from TimeUtils.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('time utility constants', () {
    test('preserve the source values and floating point arithmetic', () {
      expect(SECONDS_PER_DAY, 86400);
      expect(TIME_MINUTE, 60.0);
      expect(TIME_HOUR, 3600.0);
      expect(TIME_DAY, 86400.0);
    });
  });

  group('getTimestamp', () {
    test(
      'creates the formatter before reading and formatting the date once',
      () {
        final events = <String>[];
        final time = Object();
        final date = Object();
        final formatter = Object();

        final result = getTimestamp(
          time,
          createSimpleDateFormat: (pattern, locale) {
            events.add('create');
            expect(pattern, 'yyyyMMddHHmmss');
            expect(locale, 'US');
            return formatter;
          },
          currentDate: (actualTime) {
            events.add('date');
            expect(identical(actualTime, time), isTrue);
            return date;
          },
          format: (actualFormatter, actualDate) {
            events.add('format');
            expect(identical(actualFormatter, formatter), isTrue);
            expect(identical(actualDate, date), isTrue);
            return '20200807070000';
          },
        );

        expect(result, '20200807070000');
        expect(events, ['create', 'date', 'format']);
      },
    );

    test('formatter creation failure prevents reading the date', () {
      final error = Object();
      var dateReads = 0;
      expect(
        () => getTimestamp(
          Object(),
          createSimpleDateFormat: (_, _) => throw error,
          currentDate: (_) {
            dateReads++;
            return Object();
          },
          format: (_, _) => 'unused',
        ),
        throwsA(same(error)),
      );
      expect(dateReads, 0);
    });

    test('date read failure prevents formatting', () {
      final error = Object();
      var formatCalls = 0;
      expect(
        () => getTimestamp(
          Object(),
          createSimpleDateFormat: (_, _) => Object(),
          currentDate: (_) => throw error,
          format: (_, _) {
            formatCalls++;
            return 'unused';
          },
        ),
        throwsA(same(error)),
      );
      expect(formatCalls, 0);
    });
  });

  group('formatAsString', () {
    test(
      'formats zero and positive durations with source patterns and values',
      () {
        final calls = <(String, List<int>)>[];
        final resultZero = formatAsString(
          Object(),
          inWholeMilliseconds: (_) => 0,
          format: (pattern, values) {
            calls.add((pattern, values));
            return 'zero';
          },
        );
        final resultPositive = formatAsString(
          Object(),
          inWholeMilliseconds: (_) => 90_500,
          format: (pattern, values) {
            calls.add((pattern, values));
            return 'positive';
          },
        );
        final resultHourly = formatAsString(
          Object(),
          inWholeMilliseconds: (_) => 3_784_500,
          format: (pattern, values) {
            calls.add((pattern, values));
            return 'hourly';
          },
        );

        expect(resultZero, 'zero');
        expect(resultPositive, 'positive');
        expect(resultHourly, 'hourly');
        expect(calls.map((call) => call.$1), [
          '%02d:%02d.%02d',
          '%02d:%02d.%02d',
          '%02d:%02d:%02d.%02d',
        ]);
        expect(calls.map((call) => call.$2).toList(), [
          [0, 0, 0],
          [1, 30, 50],
          [1, 3, 4, 50],
        ]);
      },
    );

    test('formatter failure propagates unchanged after one projection', () {
      final error = Object();
      var projections = 0;
      expect(
        () => formatAsString(
          Object(),
          inWholeMilliseconds: (_) {
            projections++;
            return 0;
          },
          format: (_, _) => throw error,
        ),
        throwsA(same(error)),
      );
      expect(projections, 1);
    });

    test('projects milliseconds once and propagates conversion failure', () {
      final token = Object();
      final error = Object();
      var reads = 0;
      expect(
        () => formatAsString(
          token,
          inWholeMilliseconds: (duration) {
            reads++;
            expect(identical(duration, token), isTrue);
            throw error;
          },
          format: (_, _) => 'unused',
        ),
        throwsA(same(error)),
      );
      expect(reads, 1);
    });

    test(
      'retains negative truncation and greater-than-sixty-hour wrapping',
      () {
        final calls = <(String, List<int>)>[];
        formatAsString(
          Object(),
          inWholeMilliseconds: (_) => -3_723_457,
          format: (pattern, values) {
            calls.add((pattern, values));
            return 'negative';
          },
        );
        formatAsString(
          Object(),
          inWholeMilliseconds: (_) =>
              61 * 60 * 60 * 1000 + 2 * 60 * 1000 + 3400,
          format: (pattern, values) {
            calls.add((pattern, values));
            return 'wrapped';
          },
        );

        expect(calls.map((call) => call.$1), [
          '%02d:%02d.%02d',
          '%02d:%02d:%02d.%02d',
        ]);
        expect(calls.map((call) => call.$2).toList(), [
          [-2, -3, -45],
          [1, 2, 3, 40],
        ]);
      },
    );
  });

  group('getDayStart', () {
    test('runs calendar operations in source order for a time before 4 AM', () {
      final events = <String>[];
      final time = Object();
      final calendar = Object();
      final result = getDayStart(
        time,
        calendar: (actualTime) {
          events.add('calendar');
          expect(identical(actualTime, time), isTrue);
          return calendar;
        },
        getHourOfDay: (actualCalendar) {
          events.add('getHourOfDay');
          expect(identical(actualCalendar, calendar), isTrue);
          return 3;
        },
        addDayOfYear: (actualCalendar, amount) {
          events.add('addDayOfYear');
          expect(identical(actualCalendar, calendar), isTrue);
          expect(amount, -1);
        },
        setHourOfDay: (actualCalendar, value) {
          events.add('setHourOfDay:$value');
          expect(identical(actualCalendar, calendar), isTrue);
        },
        setMinute: (actualCalendar, value) => events.add('setMinute:$value'),
        setSecond: (actualCalendar, value) => events.add('setSecond:$value'),
        setMillisecond: (actualCalendar, value) =>
            events.add('setMillisecond:$value'),
        getTimeInMillis: (actualCalendar) {
          events.add('timeInMillis');
          expect(identical(actualCalendar, calendar), isTrue);
          return 123;
        },
      );

      expect(result, 123);
      expect(events, [
        'calendar',
        'getHourOfDay',
        'addDayOfYear',
        'setHourOfDay:4',
        'setMinute:0',
        'setSecond:0',
        'setMillisecond:0',
        'timeInMillis',
      ]);
    });

    test('does not roll the date at or after 4 AM', () {
      for (final hour in [4, 5]) {
        var additions = 0;
        getDayStart(
          Object(),
          calendar: (_) => Object(),
          getHourOfDay: (_) => hour,
          addDayOfYear: (_, _) => additions++,
          setHourOfDay: (_, _) {},
          setMinute: (_, _) {},
          setSecond: (_, _) {},
          setMillisecond: (_, _) {},
          getTimeInMillis: (_) => 0,
        );
        expect(additions, 0);
      }
    });

    test('rolls back once for a January 1 time before 4 AM', () {
      final events = <String>[];
      final result = getDayStart(
        Object(),
        calendar: (_) {
          events.add('calendar');
          return Object();
        },
        getHourOfDay: (_) {
          events.add('hour');
          return 3;
        },
        addDayOfYear: (_, amount) {
          events.add('add:$amount');
          expect(amount, -1);
        },
        setHourOfDay: (_, value) => events.add('hour:$value'),
        setMinute: (_, value) => events.add('minute:$value'),
        setSecond: (_, value) => events.add('second:$value'),
        setMillisecond: (_, value) => events.add('millisecond:$value'),
        getTimeInMillis: (_) {
          events.add('timeInMillis');
          return 1609387200000;
        },
      );

      expect(result, 1609387200000);
      expect(events, [
        'calendar',
        'hour',
        'add:-1',
        'hour:4',
        'minute:0',
        'second:0',
        'millisecond:0',
        'timeInMillis',
      ]);
    });

    test('stops immediately when reading hour throws', () {
      final error = Object();
      final events = <String>[];
      expect(
        () => getDayStart(
          Object(),
          calendar: (_) {
            events.add('calendar');
            return Object();
          },
          getHourOfDay: (_) {
            events.add('hour');
            throw error;
          },
          addDayOfYear: (_, _) => events.add('add'),
          setHourOfDay: (_, _) => events.add('setHour'),
          setMinute: (_, _) => events.add('setMinute'),
          setSecond: (_, _) => events.add('setSecond'),
          setMillisecond: (_, _) => events.add('setMillisecond'),
          getTimeInMillis: (_) {
            events.add('timeInMillis');
            return 0;
          },
        ),
        throwsA(same(error)),
      );
      expect(events, ['calendar', 'hour']);
    });
  });
}
