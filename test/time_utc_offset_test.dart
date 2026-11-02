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
 * Source-derived from Time.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('utcOffset', () {
    test(
      'truncates positive and negative non-divisible offsets toward zero',
      () {
        final calendar = Object();
        expect(
          utcOffset(
            createCalendar: () => calendar,
            getZoneOffset: (_) => 900_500,
            getDstOffset: (_) => -1_000,
          ),
          13_501.0,
        );
        expect(
          utcOffset(
            createCalendar: Object.new,
            getZoneOffset: (_) => -900_500,
            getDstOffset: (_) => 1_000,
          ),
          15_299.0,
        );
      },
    );

    test('wraps the offset sum as signed Int32 before division', () {
      expect(
        utcOffset(
          createCalendar: Object.new,
          getZoneOffset: (_) => 2_147_483_647,
          getDstOffset: (_) => 1,
        ),
        2_161_883.0,
      );
    });

    test('creates one calendar and reads its fields once in source order', () {
      final events = <String>[];
      final calendar = Object();
      var calendarCreations = 0;

      final result = utcOffset(
        createCalendar: () {
          events.add('createCalendar');
          calendarCreations++;
          return calendar;
        },
        getZoneOffset: (actualCalendar) {
          events.add('zoneOffset');
          expect(identical(actualCalendar, calendar), isTrue);
          return -3_600_000;
        },
        getDstOffset: (actualCalendar) {
          events.add('dstOffset');
          expect(identical(actualCalendar, calendar), isTrue);
          return 3_600_000;
        },
      );

      expect(result, 14_400.0);
      expect(calendarCreations, 1);
      expect(events, ['createCalendar', 'zoneOffset', 'dstOffset']);
    });

    test('calendar and zone-offset failures stop subsequent reads', () {
      final calendarError = Object();
      var zoneReads = 0;
      var dstReads = 0;
      expect(
        () => utcOffset(
          createCalendar: () => throw calendarError,
          getZoneOffset: (_) {
            zoneReads++;
            return 0;
          },
          getDstOffset: (_) {
            dstReads++;
            return 0;
          },
        ),
        throwsA(same(calendarError)),
      );
      expect(zoneReads, 0);
      expect(dstReads, 0);

      final zoneError = Object();
      expect(
        () => utcOffset(
          createCalendar: Object.new,
          getZoneOffset: (_) => throw zoneError,
          getDstOffset: (_) {
            dstReads++;
            return 0;
          },
        ),
        throwsA(same(zoneError)),
      );
      expect(dstReads, 0);
    });

    test('DST-offset failure propagates unchanged', () {
      final error = Object();
      var dstReads = 0;
      expect(
        () => utcOffset(
          createCalendar: Object.new,
          getZoneOffset: (_) => 0,
          getDstOffset: (_) {
            dstReads++;
            throw error;
          },
        ),
        throwsA(same(error)),
      );
      expect(dstReads, 1);
    });
  });
}
