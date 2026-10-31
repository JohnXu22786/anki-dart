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
 * SPDX-FileCopyrightText: 2026 Eric Li <ericli3690@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ReviewReminderSchema.kt, ReviewReminder.kt, and
 * ReviewRemindersDatabaseTest.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewReminderSchemaVersion', () {
    test('rejects versions below one and compares versions by value', () {
      expect(() => ReviewReminderSchemaVersion(0), throwsArgumentError);
      expect(
        () => ReviewReminderSchemaVersion(2147483648),
        throwsArgumentError,
      );
      expect(ReviewReminderSchemaVersion(2147483647).value, 2147483647);

      final version = ReviewReminderSchemaVersion(1);
      final equalVersion = ReviewReminderSchemaVersion(1);
      expect(version, equalVersion);
      expect(version.hashCode, equalVersion.hashCode);
      expect(version.value, 1);
    });
  });

  group('ReviewReminderSchemaV1 migration', () {
    test(
      'defaults onlyNotifyIfNoReviews to false and copies every field to V2',
      () {
        final time = ReviewReminderTime(hour: 8, minute: 45);
        final threshold = ReviewReminderCardTriggerThreshold(4);
        const scope = DeckSpecificReminderScope(32);
        final schema = ReviewReminderSchemaV1(
          id: ReviewReminderId(7),
          time: time,
          cardTriggerThreshold: threshold,
          scope: scope,
          enabled: false,
          profileID: 'profile-a',
        );

        final migrated = schema.migrate();
        expect(migrated, isA<ReviewReminderSchemaV2>());
        expect(migrated.id, schema.id);
        expect(migrated.time, time);
        expect(migrated.cardTriggerThreshold, threshold);
        expect(migrated.scope, scope);
        expect(migrated.enabled, isFalse);
        expect(migrated.profileID, 'profile-a');
        expect(migrated.onlyNotifyIfNoReviews, isFalse);
      },
    );

    test(
      'preserves an explicit onlyNotifyIfNoReviews value through migration',
      () {
        final schema = ReviewReminderSchemaV1(
          id: ReviewReminderId(8),
          time: ReviewReminderTime(hour: 21, minute: 10),
          cardTriggerThreshold: ReviewReminderCardTriggerThreshold(0),
          scope: const GlobalReminderScope(),
          enabled: true,
          profileID: 'profile-b',
          onlyNotifyIfNoReviews: true,
        );

        expect(schema.migrate().onlyNotifyIfNoReviews, isTrue);
      },
    );
  });

  test(
    'V2 migration preserves source fields and uses host supplied ID and time',
    () {
      final time = ReviewReminderTime(hour: 13, minute: 5);
      final threshold = ReviewReminderCardTriggerThreshold(12);
      const scope = DeckSpecificReminderScope(91);
      final schema = ReviewReminderSchemaV2(
        id: ReviewReminderId(3),
        time: time,
        cardTriggerThreshold: threshold,
        scope: scope,
        enabled: false,
        profileID: 'profile-c',
        onlyNotifyIfNoReviews: true,
      );
      final currentId = ReviewReminderId(44);
      const currentTimestamp = 1793451900000;

      final migrated = schema.migrate(
        id: currentId,
        latestNotifTime: currentTimestamp,
      );

      expect(migrated.id, currentId);
      expect(migrated.time, time);
      expect(migrated.cardTriggerThreshold, threshold);
      expect(migrated.scope, scope);
      expect(migrated.enabled, isFalse);
      expect(migrated.profileID, 'profile-c');
      expect(migrated.onlyNotifyIfNoReviews, isTrue);
      expect(migrated.latestNotifTime, currentTimestamp);
    },
  );
}
