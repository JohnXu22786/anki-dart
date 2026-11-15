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
  group('currentDate', () {
    test('reads milliseconds once before creating the date', () {
      final events = <String>[];
      final time = Object();
      final date = Object();
      var clockReads = 0;

      final result = currentDate(
        time,
        intTimeMS: (actualTime) {
          events.add('clock');
          clockReads++;
          expect(identical(actualTime, time), isTrue);
          return 1_723_456_789_123;
        },
        createDate: (milliseconds) {
          events.add('date');
          expect(milliseconds, 1_723_456_789_123);
          return date;
        },
      );

      expect(identical(result, date), isTrue);
      expect(clockReads, 1);
      expect(events, ['clock', 'date']);
    });

    test('clock failure prevents date creation and propagates unchanged', () {
      final error = Object();
      var dateCreations = 0;

      expect(
        () => currentDate(
          Object(),
          intTimeMS: (_) => throw error,
          createDate: (_) {
            dateCreations++;
            return Object();
          },
        ),
        throwsA(same(error)),
      );
      expect(dateCreations, 0);
    });

    test('date creation failure propagates unchanged', () {
      final error = Object();
      var clockReads = 0;

      expect(
        () => currentDate(
          Object(),
          intTimeMS: (_) {
            clockReads++;
            return 123;
          },
          createDate: (_) => throw error,
        ),
        throwsA(same(error)),
      );
      expect(clockReads, 1);
    });
  });

  group('calendar', () {
    test(
      'creates the calendar, reads the current date, assigns it, and returns it',
      () {
        final events = <String>[];
        final time = Object();
        final calendarObject = Object();
        final date = Object();
        var clockReads = 0;

        final result = calendar(
          time,
          createCalendar: () {
            events.add('calendar');
            return calendarObject;
          },
          intTimeMS: (actualTime) {
            events.add('clock');
            clockReads++;
            expect(identical(actualTime, time), isTrue);
            return 1_723_456_789_123;
          },
          createDate: (milliseconds) {
            events.add('date');
            expect(milliseconds, 1_723_456_789_123);
            return date;
          },
          setTime: (actualCalendar, actualDate) {
            events.add('setTime');
            expect(identical(actualCalendar, calendarObject), isTrue);
            expect(identical(actualDate, date), isTrue);
          },
        );

        expect(identical(result, calendarObject), isTrue);
        expect(clockReads, 1);
        expect(events, ['calendar', 'clock', 'date', 'setTime']);
      },
    );

    test('calendar creation failure prevents the time read', () {
      final error = Object();
      var clockReads = 0;

      expect(
        () => calendar(
          Object(),
          createCalendar: () => throw error,
          intTimeMS: (_) {
            clockReads++;
            return 123;
          },
          createDate: (_) => Object(),
          setTime: (_, _) {},
        ),
        throwsA(same(error)),
      );
      expect(clockReads, 0);
    });

    test('date creation failure prevents setting the calendar time', () {
      final error = Object();
      final events = <String>[];

      expect(
        () => calendar(
          Object(),
          createCalendar: () {
            events.add('calendar');
            return Object();
          },
          intTimeMS: (_) {
            events.add('clock');
            return 123;
          },
          createDate: (_) {
            events.add('date');
            throw error;
          },
          setTime: (_, _) => events.add('setTime'),
        ),
        throwsA(same(error)),
      );
      expect(events, ['calendar', 'clock', 'date']);
    });

    test('setTime failure propagates unchanged', () {
      final error = Object();
      final events = <String>[];

      expect(
        () => calendar(
          Object(),
          createCalendar: () {
            events.add('calendar');
            return Object();
          },
          intTimeMS: (_) {
            events.add('clock');
            return 123;
          },
          createDate: (_) {
            events.add('date');
            return Object();
          },
          setTime: (_, _) {
            events.add('setTime');
            throw error;
          },
        ),
        throwsA(same(error)),
      );
      expect(events, ['calendar', 'clock', 'date', 'setTime']);
    });
  });
}
