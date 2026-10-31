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
 * Source-derived from ReviewRemindersDatabase.kt and
 * ReviewRemindersDatabaseTest.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('StoredReviewReminderGroup', () {
    test('decodes and re-encodes the pinned current-schema JSON fixture', () {
      const rawJson = '''
{
"version":3,
"remindersMapJson":"{\\"22\\":{\\"id\\":22,\\"time\\":{\\"hour\\":14,\\"minute\\":16},\\"cardTriggerThreshold\\":1,\\"scope\\":{\\"type\\":\\"com.ichi2.anki.reviewreminders.ReviewReminderScope.Global\\"},\\"enabled\\":true,\\"latestNotifTime\\":1771193761002,\\"profileID\\":\\"\\",\\"onlyNotifyIfNoReviews\\":false}}"
}
''';
      const expectedJson =
          '{"version":3,"remindersMapJson":"{\\"22\\":{\\"id\\":22,'
          '\\"time\\":{\\"hour\\":14,\\"minute\\":16},'
          '\\"cardTriggerThreshold\\":1,\\"scope\\":{\\"type\\":'
          '\\"com.ichi2.anki.reviewreminders.ReviewReminderScope.Global\\"},'
          '\\"enabled\\":true,\\"latestNotifTime\\":1771193761002,'
          '\\"profileID\\":\\"\\",\\"onlyNotifyIfNoReviews\\":false}}"}';

      final stored = StoredReviewReminderGroup.fromJsonString(rawJson);

      expect(stored.version, ReviewReminderSchemaVersion(3));
      expect(
        stored.remindersMapJson,
        '{"22":{"id":22,"time":{"hour":14,"minute":16},'
        '"cardTriggerThreshold":1,"scope":{"type":"com.ichi2.anki.'
        'reviewreminders.ReviewReminderScope.Global"},"enabled":true,'
        '"latestNotifTime":1771193761002,"profileID":"",'
        '"onlyNotifyIfNoReviews":false}}',
      );
      expect(stored.serializeToString(), expectedJson);
    });

    test('uses value equality and hash codes for both stored fields', () {
      final first = StoredReviewReminderGroup(
        version: ReviewReminderSchemaVersion(3),
        remindersMapJson: '{}',
      );
      final equal = StoredReviewReminderGroup(
        version: ReviewReminderSchemaVersion(3),
        remindersMapJson: '{}',
      );

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(
        first,
        isNot(
          StoredReviewReminderGroup(
            version: ReviewReminderSchemaVersion(2),
            remindersMapJson: '{}',
          ),
        ),
      );
      expect(
        first,
        isNot(
          StoredReviewReminderGroup(
            version: ReviewReminderSchemaVersion(3),
            remindersMapJson: '{ }',
          ),
        ),
      );
    });

    test('malformed and wrongly typed envelope JSON fails during decoding', () {
      expect(
        () => StoredReviewReminderGroup.fromJsonString('{'),
        throwsFormatException,
      );
      expect(
        () => StoredReviewReminderGroup.fromJsonString('{"version":3}'),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => StoredReviewReminderGroup.fromJsonString(
          '{"version":"3","remindersMapJson":"{}"}',
        ),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => StoredReviewReminderGroup.fromJsonString(
          '{"version":3,"remindersMapJson":{}}',
        ),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => StoredReviewReminderGroup.fromJsonString(
          '{"version":3,"remindersMapJson":"{}","extra":true}',
        ),
        throwsFormatException,
      );
      expect(
        () => StoredReviewReminderGroup.fromJsonString(
          '{"version":2147483648,"remindersMapJson":"{}"}',
        ),
        throwsArgumentError,
      );
    });
  });
}
