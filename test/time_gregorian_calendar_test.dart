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
  group('gregorianCalendar', () {
    test(
      'creates once, assigns the exact milliseconds, and returns the calendar',
      () {
        final calendar = Object();
        final events = <String>[];
        final result = gregorianCalendar(
          -1234567890123,
          createGregorianCalendar: () {
            events.add('create');
            return calendar;
          },
          setTimeInMillis: (actualCalendar, milliseconds) {
            events.add('setTimeInMillis');
            expect(identical(actualCalendar, calendar), isTrue);
            expect(milliseconds, -1234567890123);
          },
        );

        expect(identical(result, calendar), isTrue);
        expect(events, ['create', 'setTimeInMillis']);
      },
    );

    test('calendar creation failure propagates and prevents assignment', () {
      final failure = Object();
      var assignments = 0;

      expect(
        () => gregorianCalendar(
          42,
          createGregorianCalendar: () => throw failure,
          setTimeInMillis: (_, _) => assignments++,
        ),
        throwsA(same(failure)),
      );
      expect(assignments, 0);
    });

    test('assignment failure propagates unchanged', () {
      final calendar = Object();
      final failure = Object();
      var creations = 0;
      var assignments = 0;

      expect(
        () => gregorianCalendar(
          42,
          createGregorianCalendar: () {
            creations++;
            return calendar;
          },
          setTimeInMillis: (actualCalendar, milliseconds) {
            assignments++;
            expect(identical(actualCalendar, calendar), isTrue);
            expect(milliseconds, 42);
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(creations, 1);
      expect(assignments, 1);
    });
  });
}
