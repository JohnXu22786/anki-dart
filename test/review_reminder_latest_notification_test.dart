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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ReviewReminder.kt and ReviewReminderTest.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('latest review reminder notification delivery', () {
    final schedule = ReviewReminderTime(hour: 9, minute: 30);

    test('compares before, at, and after the scheduled time inclusively', () {
      final now = DateTime(2026, 10, 31, 9, 30);

      expect(
        wasLatestReviewReminderNotificationDelivered(
          now: now,
          time: schedule,
          latestNotifTime: now.subtract(const Duration(milliseconds: 1)),
        ),
        isFalse,
      );
      expect(
        wasLatestReviewReminderNotificationDelivered(
          now: now,
          time: schedule,
          latestNotifTime: now,
        ),
        isTrue,
      );
      expect(
        wasLatestReviewReminderNotificationDelivered(
          now: now,
          time: schedule,
          latestNotifTime: now.add(const Duration(milliseconds: 1)),
        ),
        isTrue,
      );
    });

    test('uses yesterday when the scheduled time is still in the future', () {
      final now = DateTime(2026, 10, 31, 8, 0);
      final yesterdayAtSchedule = DateTime(2026, 10, 30, 9, 30);

      expect(
        wasLatestReviewReminderNotificationDelivered(
          now: now,
          time: schedule,
          latestNotifTime: yesterdayAtSchedule,
        ),
        isTrue,
      );
      expect(
        wasLatestReviewReminderNotificationDelivered(
          now: now,
          time: schedule,
          latestNotifTime: yesterdayAtSchedule.subtract(
            const Duration(milliseconds: 1),
          ),
        ),
        isFalse,
      );
    });

    test(
      'does not accept a stale previous-day notification after today schedule',
      () {
        final now = DateTime(2026, 10, 31, 10, 0);
        final yesterdayAtSchedule = DateTime(2026, 10, 30, 9, 30);

        expect(
          wasLatestReviewReminderNotificationDelivered(
            now: now,
            time: schedule,
            latestNotifTime: yesterdayAtSchedule,
          ),
          isFalse,
        );
      },
    );

    test('preserves the current millisecond after setting seconds to zero', () {
      final now = DateTime(2026, 10, 31, 9, 30, 0, 500);

      expect(
        wasLatestReviewReminderNotificationDelivered(
          now: now,
          time: schedule,
          latestNotifTime: DateTime(2026, 10, 31, 9, 30, 0, 499),
        ),
        isFalse,
      );
      expect(
        wasLatestReviewReminderNotificationDelivered(
          now: now,
          time: schedule,
          latestNotifTime: now,
        ),
        isTrue,
      );
    });
  });
}
