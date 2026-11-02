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
 * SPDX-FileCopyrightText: 2025 Eric Li <ericli3690@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ReviewReminder.kt and ReviewReminderTest.kt in AnkiDroid
 * 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewReminder', () {
    test('creation uses host inputs and source defaults', () {
      final id = ReviewReminderId(27);
      final reminder = ReviewReminder.createReviewReminder(
        id: id,
        time: ReviewReminderTime(hour: 8, minute: 5),
        latestNotifTime: 1735732800123,
      );

      expect(reminder.id, id);
      expect(reminder.time, ReviewReminderTime(hour: 8, minute: 5));
      expect(reminder.cardTriggerThreshold.threshold, 0);
      expect(reminder.scope, const GlobalReminderScope());
      expect(reminder.enabled, isTrue);
      expect(reminder.latestNotifTime, 1735732800123);
      expect(reminder.profileID, isEmpty);
      expect(reminder.onlyNotifyIfNoReviews, isFalse);
      expect(reminder.time.toString(), 'ReviewReminderTime(hour=8, minute=5)');
      expect(reminder.scope.toString(), 'Global');
    });

    test('compares, hashes, and prints all source fields', () {
      final reminder = ReviewReminder.createReviewReminder(
        id: ReviewReminderId(27),
        time: ReviewReminderTime(hour: 8, minute: 5),
        cardTriggerThreshold: ReviewReminderCardTriggerThreshold(4),
        scope: const DeckSpecificReminderScope(42),
        enabled: false,
        latestNotifTime: 1735732800123,
        profileID: 'profile',
        onlyNotifyIfNoReviews: true,
      );
      final equal = ReviewReminder.createReviewReminder(
        id: ReviewReminderId(27),
        time: ReviewReminderTime(hour: 8, minute: 5),
        cardTriggerThreshold: ReviewReminderCardTriggerThreshold(4),
        scope: const DeckSpecificReminderScope(42),
        enabled: false,
        latestNotifTime: 1735732800123,
        profileID: 'profile',
        onlyNotifyIfNoReviews: true,
      );

      expect(reminder, equal);
      expect(reminder.hashCode, equal.hashCode);
      expect(
        reminder.toString(),
        'ReviewReminder(id=ReviewReminderId(value=27), '
        'time=ReviewReminderTime(hour=8, minute=5), '
        'cardTriggerThreshold=ReviewReminderCardTriggerThreshold(threshold=4), '
        'scope=DeckSpecific(did=42), enabled=false, '
        'latestNotifTime=1735732800123, profileID=profile, '
        'onlyNotifyIfNoReviews=true)',
      );

      final differentReminders = <ReviewReminder>[
        ReviewReminder.createReviewReminder(
          id: ReviewReminderId(28),
          time: reminder.time,
          cardTriggerThreshold: reminder.cardTriggerThreshold,
          scope: reminder.scope,
          enabled: reminder.enabled,
          latestNotifTime: reminder.latestNotifTime,
          profileID: reminder.profileID,
          onlyNotifyIfNoReviews: reminder.onlyNotifyIfNoReviews,
        ),
        ReviewReminder.createReviewReminder(
          id: reminder.id,
          time: ReviewReminderTime(hour: 8, minute: 6),
          cardTriggerThreshold: reminder.cardTriggerThreshold,
          scope: reminder.scope,
          enabled: reminder.enabled,
          latestNotifTime: reminder.latestNotifTime,
          profileID: reminder.profileID,
          onlyNotifyIfNoReviews: reminder.onlyNotifyIfNoReviews,
        ),
        ReviewReminder.createReviewReminder(
          id: reminder.id,
          time: reminder.time,
          cardTriggerThreshold: ReviewReminderCardTriggerThreshold(5),
          scope: reminder.scope,
          enabled: reminder.enabled,
          latestNotifTime: reminder.latestNotifTime,
          profileID: reminder.profileID,
          onlyNotifyIfNoReviews: reminder.onlyNotifyIfNoReviews,
        ),
        ReviewReminder.createReviewReminder(
          id: reminder.id,
          time: reminder.time,
          cardTriggerThreshold: reminder.cardTriggerThreshold,
          scope: const GlobalReminderScope(),
          enabled: reminder.enabled,
          latestNotifTime: reminder.latestNotifTime,
          profileID: reminder.profileID,
          onlyNotifyIfNoReviews: reminder.onlyNotifyIfNoReviews,
        ),
        ReviewReminder.createReviewReminder(
          id: reminder.id,
          time: reminder.time,
          cardTriggerThreshold: reminder.cardTriggerThreshold,
          scope: reminder.scope,
          enabled: true,
          latestNotifTime: reminder.latestNotifTime,
          profileID: reminder.profileID,
          onlyNotifyIfNoReviews: reminder.onlyNotifyIfNoReviews,
        ),
        ReviewReminder.createReviewReminder(
          id: reminder.id,
          time: reminder.time,
          cardTriggerThreshold: reminder.cardTriggerThreshold,
          scope: reminder.scope,
          enabled: reminder.enabled,
          latestNotifTime: 1735732800124,
          profileID: reminder.profileID,
          onlyNotifyIfNoReviews: reminder.onlyNotifyIfNoReviews,
        ),
        ReviewReminder.createReviewReminder(
          id: reminder.id,
          time: reminder.time,
          cardTriggerThreshold: reminder.cardTriggerThreshold,
          scope: reminder.scope,
          enabled: reminder.enabled,
          latestNotifTime: reminder.latestNotifTime,
          profileID: 'other',
          onlyNotifyIfNoReviews: reminder.onlyNotifyIfNoReviews,
        ),
        ReviewReminder.createReviewReminder(
          id: reminder.id,
          time: reminder.time,
          cardTriggerThreshold: reminder.cardTriggerThreshold,
          scope: reminder.scope,
          enabled: reminder.enabled,
          latestNotifTime: reminder.latestNotifTime,
          profileID: reminder.profileID,
          onlyNotifyIfNoReviews: false,
        ),
      ];
      for (final different in differentReminders) {
        expect(different, isNot(reminder));
      }
    });

    test('updates only latest notification time from the host timestamp', () {
      final reminder = ReviewReminder.createReviewReminder(
        id: ReviewReminderId(27),
        time: ReviewReminderTime(hour: 8, minute: 5),
        cardTriggerThreshold: ReviewReminderCardTriggerThreshold(4),
        scope: const DeckSpecificReminderScope(42),
        enabled: false,
        latestNotifTime: 100,
        profileID: 'profile',
        onlyNotifyIfNoReviews: true,
      );

      reminder.updateLatestNotifTime(currentTimestamp: 200);

      expect(reminder.latestNotifTime, 200);
      expect(reminder.id, ReviewReminderId(27));
      expect(reminder.time, ReviewReminderTime(hour: 8, minute: 5));
      expect(
        reminder.cardTriggerThreshold,
        ReviewReminderCardTriggerThreshold(4),
      );
      expect(reminder.scope, const DeckSpecificReminderScope(42));
      expect(reminder.enabled, isFalse);
      expect(reminder.profileID, 'profile');
      expect(reminder.onlyNotifyIfNoReviews, isTrue);
    });

    test('current schema migration returns the same instance', () {
      final reminder = ReviewReminder.createReviewReminder(
        id: ReviewReminderId(27),
        time: ReviewReminderTime(hour: 8, minute: 5),
        latestNotifTime: 100,
      );

      expect(identical(reminder.migrate(), reminder), isTrue);
    });
  });
}
