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
 * Source-derived from Time.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('genToday', () {
    test('preserves source callback order and host object identity', () {
      final events = <String>[];
      final time = Object();
      final formatter = Object();
      final timeZone = Object();
      final calendar = Object();
      final date = Object();
      final sqlDate = Object();
      const formattedDate = '2024-02-29';

      final result = genToday(
        time,
        1.9,
        createSimpleDateFormat: (pattern, locale) {
          events.add('createFormatter');
          expect(pattern, 'yyyy-MM-dd');
          expect(locale, 'US');
          return formatter;
        },
        getTimeZone: (id) {
          events.add('getTimeZone');
          expect(id, 'GMT');
          return timeZone;
        },
        setTimeZone: (actualFormatter, actualTimeZone) {
          events.add('setTimeZone');
          expect(identical(actualFormatter, formatter), isTrue);
          expect(identical(actualTimeZone, timeZone), isTrue);
        },
        intTimeMS: (actualTime) {
          events.add('clock');
          expect(identical(actualTime, time), isTrue);
          return 1_700_000_000_123;
        },
        createGregorianCalendar: () {
          events.add('createCalendar');
          return calendar;
        },
        setTimeInMillis: (actualCalendar, milliseconds) {
          events.add('setTimeInMillis');
          expect(identical(actualCalendar, calendar), isTrue);
          expect(milliseconds, 1_699_999_999_123);
        },
        getTime: (actualCalendar) {
          events.add('getTime');
          expect(identical(actualCalendar, calendar), isTrue);
          return date;
        },
        format: (actualFormatter, actualDate) {
          events.add('format');
          expect(identical(actualFormatter, formatter), isTrue);
          expect(identical(actualDate, date), isTrue);
          return formattedDate;
        },
        sqlDateValueOf: (value) {
          events.add('sqlDateValueOf');
          expect(identical(value, formattedDate), isTrue);
          return sqlDate;
        },
      );

      expect(identical(result, sqlDate), isTrue);
      expect(events, [
        'createFormatter',
        'getTimeZone',
        'setTimeZone',
        'clock',
        'createCalendar',
        'setTimeInMillis',
        'getTime',
        'format',
        'sqlDateValueOf',
      ]);
    });

    test('matches Kotlin Long conversion and wrapping arithmetic', () {
      const twoTo63 = 9223372036854775808.0;
      final cases = <(double, int, int)>[
        (-1.9, 0, 1000),
        (double.nan, 5, 5),
        (double.infinity, 0, 1000),
        (twoTo63, 0, 1000),
        (-twoTo63, 0, 0),
        (1.9, -9223372036854775808, 9223372036854774808),
      ];

      for (final (offset, clock, expected) in cases) {
        var assignedMilliseconds = 0;
        genToday(
          Object(),
          offset,
          createSimpleDateFormat: (_, _) => Object(),
          getTimeZone: (_) => Object(),
          setTimeZone: (_, _) {},
          intTimeMS: (_) => clock,
          createGregorianCalendar: Object.new,
          setTimeInMillis: (_, milliseconds) =>
              assignedMilliseconds = milliseconds,
          getTime: (_) => Object(),
          format: (_, _) => '2024-01-01',
          sqlDateValueOf: (_) => Object(),
        );
        expect(assignedMilliseconds, expected, reason: 'offset=$offset');
      }
    });

    test('propagates host failures and stops later callbacks', () {
      final error = Object();
      final events = <String>[];

      expect(
        () => genToday(
          Object(),
          0,
          createSimpleDateFormat: (_, _) {
            events.add('createFormatter');
            return Object();
          },
          getTimeZone: (_) {
            events.add('getTimeZone');
            return Object();
          },
          setTimeZone: (_, _) {
            events.add('setTimeZone');
            throw error;
          },
          intTimeMS: (_) {
            events.add('clock');
            return 0;
          },
          createGregorianCalendar: () {
            events.add('createCalendar');
            return Object();
          },
          setTimeInMillis: (_, _) => events.add('setTimeInMillis'),
          getTime: (_) => Object(),
          format: (_, _) => 'unused',
          sqlDateValueOf: (_) => Object(),
        ),
        throwsA(same(error)),
      );
      expect(events, ['createFormatter', 'getTimeZone', 'setTimeZone']);
    });
  });
}
