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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: Collection.kt and ReviewerFragment.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewTimeboxTracker', () {
    test('expires only after the limit and returns the limit and answer delta',
        () {
      var now = 100;
      var limit = 60;
      var answers = 10;
      final tracker = ReviewTimeboxTracker(
        intTimeSeconds: () => now,
        timeboxSeconds: () => limit,
        numberOfAnswersRecorded: () => answers,
      );
      tracker.startTimebox();

      now = 160;
      answers = 12;
      expect(
        tracker.timeboxReached(),
        isNull,
      );

      now = 161;
      answers = 13;
      final reached = tracker.timeboxReached();

      expect(reached?.secs, 60);
      expect(reached?.reps, 3);
    });

    test('a zero limit does not read the clock or reset the baseline', () {
      var now = 100;
      var limit = 60;
      var answers = 4;
      var reads = 0;
      final tracker = ReviewTimeboxTracker(
        intTimeSeconds: () {
          reads++;
          return now;
        },
        timeboxSeconds: () => limit,
        numberOfAnswersRecorded: () => answers,
      );
      tracker.startTimebox();

      now = 1000;
      answers = 8;
      limit = 0;
      expect(tracker.timeboxReached(), isNull);
      expect(reads, 1);

      limit = 60;
      answers = 9;
      final reached = tracker.timeboxReached();
      expect(reached?.secs, 60);
      expect(reached?.reps, 5);
    });

    test('restarts the time and answer baseline using a fresh clock read', () {
      final clockValues = [100, 111, 113, 122, 124, 125];
      var reads = 0;
      var answers = 5;
      final tracker = ReviewTimeboxTracker(
        intTimeSeconds: () => clockValues[reads++],
        timeboxSeconds: () => 10,
        numberOfAnswersRecorded: () => answers,
      );
      tracker.startTimebox();

      answers = 12;
      final first = tracker.timeboxReached();
      expect(first?.reps, 7);
      expect(reads, 3);

      answers = 14;
      expect(tracker.timeboxReached(), isNull);
      final second = tracker.timeboxReached();
      expect(second?.secs, 10);
      expect(second?.reps, 2);
      expect(reads, 6);
    });

    test('negative limits and a backward clock keep the strict comparison', () {
      var now = 100;
      var limit = -1;
      var answers = 2;
      final tracker = ReviewTimeboxTracker(
        intTimeSeconds: () => now,
        timeboxSeconds: () => limit,
        numberOfAnswersRecorded: () => answers,
      );
      tracker.startTimebox();

      now = 99;
      expect(tracker.timeboxReached(), isNull);
      now = 100;
      final reached = tracker.timeboxReached();
      expect(reached?.secs, -1);
      expect(reached?.reps, 0);
    });
  });

  group('reviewTimeboxRoundedMinutes', () {
    test('preserves Float32 division and roundToInt tie boundaries', () {
      expect(reviewTimeboxRoundedMinutes(29), 0);
      expect(reviewTimeboxRoundedMinutes(30), 1);
      expect(reviewTimeboxRoundedMinutes(-30), 0);
      expect(reviewTimeboxRoundedMinutes(2147483647), 35791396);
    });
  });
}
