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
 * SPDX-FileCopyrightText: 2021 Arthur Milchior <arthur@milchior.fr>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from MockTime.kt and MockTimeTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('MockTime', () {
    test('returns the current value before applying the Int32 step', () {
      final time = MockTime(41, step: 7);

      expect(time.intTimeMS(), 41);
      expect(time.intTimeMS(), 48);
      expect(time.intTimeMS(), 55);
    });

    test('wraps the step from signed Int32 to signed Int64', () {
      final time = MockTime(0, step: 0x80000000);

      expect(time.intTimeMS(), 0);
      expect(time.intTimeMS(), -0x80000000);
    });

    test('addM and addD update milliseconds with signed Int64 wrapping', () {
      final time = MockTime(1000);

      time.addM(2);
      expect(time.intTimeMS(), 121000);
      time.addD(-1);
      expect(time.intTimeMS(), -86_279_000);

      final wrapping = MockTime(0x7fffffffffffffff);
      wrapping.addM(1);
      expect(wrapping.intTimeMS(), -9223372036854715809);

      final wrappingDays = MockTime(0x7fffffffffffffff);
      wrappingDays.addD(1);
      expect(wrappingDays.intTimeMS(), -9223372036768375809);
    });

    test(
      'timeStamp constructs in source order and uses the same GMT object',
      () {
        final events = <String>[];
        final zone = Object();
        final calendar = Object();
        final result = MockTime.timeStamp(
          2020,
          7,
          7,
          7,
          0,
          0,
          milliseconds: 0,
          getTimeZone: (id) {
            events.add('getTimeZone');
            expect(id, 'GMT');
            return zone;
          },
          createGregorianCalendar: (year, month, date, hour, minute, second) {
            events.add('createGregorianCalendar');
            expect(
              [year, month, date, hour, minute, second],
              [2020, 7, 7, 7, 0, 0],
            );
            return calendar;
          },
          setTimeZone: (actualCalendar, actualZone) {
            events.add('setTimeZone');
            expect(identical(actualCalendar, calendar), isTrue);
            expect(identical(actualZone, zone), isTrue);
          },
          setMillisecond: (actualCalendar, value) {
            events.add('setMillisecond');
            expect(identical(actualCalendar, calendar), isTrue);
            expect(value, 0);
          },
          getTimeInMillis: (actualCalendar) {
            events.add('getTimeInMillis');
            expect(identical(actualCalendar, calendar), isTrue);
            return 1596783600000;
          },
        );

        expect(result, 1596783600000);
        expect(events, [
          'getTimeZone',
          'createGregorianCalendar',
          'setTimeZone',
          'setMillisecond',
          'getTimeInMillis',
        ]);
      },
    );

    test(
      'date-components constructor uses timeStamp then applies the step',
      () {
        final time = MockTime.fromComponents(
          year: 2020,
          month: 7,
          date: 7,
          hourOfDay: 7,
          minute: 0,
          second: 0,
          step: 3,
          getTimeZone: (_) => Object(),
          createGregorianCalendar: (_, _, _, _, _, _) => Object(),
          setTimeZone: (_, _) {},
          setMillisecond: (_, _) {},
          getTimeInMillis: (_) => 1596783600000,
        );

        expect(time.intTimeMS(), 1596783600000);
        expect(time.intTimeMS(), 1596783600003);
      },
    );

    for (final failingEvent in [
      'getTimeZone',
      'createGregorianCalendar',
      'setTimeZone',
      'setMillisecond',
      'getTimeInMillis',
    ]) {
      test('$failingEvent failure propagates and skips later callbacks', () {
        final failure = Object();
        final events = <String>[];
        void record(String event) {
          events.add(event);
          if (event == failingEvent) throw failure;
        }

        expect(
          () => MockTime.timeStamp(
            2020,
            7,
            7,
            7,
            0,
            0,
            getTimeZone: (id) {
              expect(id, 'GMT');
              record('getTimeZone');
              return Object();
            },
            createGregorianCalendar: (_, _, _, _, _, _) {
              record('createGregorianCalendar');
              return Object();
            },
            setTimeZone: (_, _) => record('setTimeZone'),
            setMillisecond: (_, _) => record('setMillisecond'),
            getTimeInMillis: (_) {
              record('getTimeInMillis');
              return 0;
            },
          ),
          throwsA(same(failure)),
        );
        expect(events.last, failingEvent);
      });
    }
  });
}
