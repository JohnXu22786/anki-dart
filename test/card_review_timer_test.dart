/*
 * Copyright (c) 2009 Daniel Svärd daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2009 Daniel Svärd
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTest.kt and Card.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CardReviewTimer', () {
    test('startTimer reads and stores the host time once', () {
      final timer = CardReviewTimer();
      var calls = 0;

      timer.startTimer(
        timeNow: () {
          calls++;
          return 123456;
        },
      );

      expect(timer.timerStarted, 123456);
      expect(calls, 1);
    });

    test('timeTaken narrows before reading and applying the time limit', () {
      final timer = CardReviewTimer(timerStarted: 0);
      final calls = <String>[];

      final result = timer.timeTaken(
        timeNow: () {
          calls.add('now');
          return 0x80000005;
        },
        timeLimit: () {
          calls.add('limit');
          return 100;
        },
      );

      expect(result, -2147483643);
      expect(calls, ['now', 'limit']);
    });

    test(
      'timeTaken reads the limit once and caps a positive elapsed value',
      () {
        final timer = CardReviewTimer(timerStarted: 10);
        var nowCalls = 0;
        var limitCalls = 0;

        final result = timer.timeTaken(
          timeNow: () {
            nowCalls++;
            return 210;
          },
          timeLimit: () {
            limitCalls++;
            return 100;
          },
        );

        expect(result, 100);
        expect(nowCalls, 1);
        expect(limitCalls, 1);
      },
    );

    test(
      'timeTaken preserves negative elapsed time rather than clamping it',
      () {
        final timer = CardReviewTimer(timerStarted: 20);

        final result = timer.timeTaken(timeNow: () => 10, timeLimit: () => 100);

        expect(result, -10);
      },
    );

    test('stop and resume preserve full-width elapsed arithmetic', () {
      final timer = CardReviewTimer(timerStarted: 3);
      const largeTime = 0x100000005;
      timer.stopTimer(timeNow: () => largeTime);

      expect(timer.elapsedTime, largeTime - 3);

      timer.resumeTimer(timeNow: () => largeTime + 50);

      expect(timer.timerStarted, 53);
    });
  });
}
