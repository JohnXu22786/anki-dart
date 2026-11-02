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
 * SPDX-FileCopyrightText: 2025 Eric Li <ericli3690@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ReviewRemindersDatabase.kt and
 * ReviewRemindersDatabaseTest.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('review reminder notification refresh decision', () {
    final checkTime = DateTime(2026, 10, 31, 10);
    final schedule = ReviewReminderTime(hour: 9, minute: 0);

    ReviewReminder makeReminder({required int id, required int latestTime}) =>
        ReviewReminder.createReviewReminder(
          id: ReviewReminderId(id),
          time: schedule,
          latestNotifTime: latestTime,
          enabled: false,
          profileID: 'profile',
        );

    test(
      'missing reminder returns null and leaves other entries unchanged',
      () {
        final existing = makeReminder(id: 1, latestTime: 123);
        final group = ReviewReminderGroup.fromPairs([
          MapEntry(existing.id, existing),
        ]);

        final result = refreshReviewReminderNotification(
          reminders: group,
          id: ReviewReminderId(2),
          checkTime: checkTime,
          updatedAtEpochMilliseconds: 456,
        );

        expect(result, isNull);
        expect(group[existing.id], same(existing));
        expect(existing.latestNotifTime, 123);
      },
    );

    test(
      'delivered reminder returns null without mutating it or the group',
      () {
        final reminder = makeReminder(
          id: 1,
          latestTime: DateTime(2026, 10, 31, 9).millisecondsSinceEpoch,
        );
        final group = ReviewReminderGroup.fromPairs([
          MapEntry(reminder.id, reminder),
        ]);

        final result = refreshReviewReminderNotification(
          reminders: group,
          id: reminder.id,
          checkTime: checkTime,
          updatedAtEpochMilliseconds: 456,
        );

        expect(result, isNull);
        expect(group[reminder.id], same(reminder));
        expect(
          reminder.latestNotifTime,
          DateTime(2026, 10, 31, 9).millisecondsSinceEpoch,
        );
        expect(reminder.enabled, isFalse);
        expect(reminder.profileID, 'profile');
      },
    );

    test(
      'refresh uses separate update timestamp and returns same stored object',
      () {
        final oldLatestTime = DateTime(2026, 10, 30, 9).millisecondsSinceEpoch;
        final reminder = makeReminder(id: 1, latestTime: oldLatestTime);
        final unrelated = makeReminder(id: 2, latestTime: 789);
        final group = ReviewReminderGroup.fromPairs([
          MapEntry(reminder.id, reminder),
          MapEntry(unrelated.id, unrelated),
        ]);
        const updatedAt = 9876543210123;

        final result = refreshReviewReminderNotification(
          reminders: group,
          id: reminder.id,
          checkTime: checkTime,
          updatedAtEpochMilliseconds: updatedAt,
        );

        expect(result, same(reminder));
        expect(group[reminder.id], same(reminder));
        expect(reminder.latestNotifTime, updatedAt);
        expect(reminder.id, ReviewReminderId(1));
        expect(reminder.time, schedule);
        expect(reminder.enabled, isFalse);
        expect(reminder.profileID, 'profile');
        expect(group[unrelated.id], same(unrelated));
        expect(unrelated.latestNotifTime, 789);
      },
    );
  });
}
