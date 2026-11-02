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
 * SPDX-FileCopyrightText: 2026 Eric Li <ericli3690@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ReviewReminderSchema.kt, ReviewReminder.kt, and
 * ReviewRemindersDatabase.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewReminderSchemaV1MapCodec', () {
    test('uses decimal map keys and preserves each value ID independently', () {
      const rawJson =
          '{"7":{"id":42,"time":{"hour":9,"minute":30},'
          '"cardTriggerThreshold":12,"scope":{"type":"com.ichi2.anki.'
          'reviewreminders.ReviewReminderScope.DeckSpecific","did":-42},'
          '"enabled":false,"profileID":"profile-a"}}';

      final decoded = ReviewReminderSchemaV1MapCodec.decode(rawJson);

      expect(decoded.keys, [ReviewReminderId(7)]);
      expect(decoded[ReviewReminderId(7)]?.id, ReviewReminderId(42));
      expect(ReviewReminderSchemaV1MapCodec.encode(decoded), rawJson);
    });

    test('defaults a missing false field and omits it when encoding', () {
      const rawJson =
          '{"1":{"id":1,"time":{"hour":8,"minute":0},'
          '"cardTriggerThreshold":0,"scope":{"type":"com.ichi2.anki.'
          'reviewreminders.ReviewReminderScope.Global"},"enabled":true,'
          '"profileID":""}}';

      final decoded = ReviewReminderSchemaV1MapCodec.decode(rawJson);

      expect(decoded[ReviewReminderId(1)]?.onlyNotifyIfNoReviews, isFalse);
      expect(ReviewReminderSchemaV1MapCodec.encode(decoded), rawJson);
    });

    test('encodes a true optional field', () {
      final schema = ReviewReminderSchemaV1(
        id: ReviewReminderId(3),
        time: ReviewReminderTime(hour: 10, minute: 15),
        cardTriggerThreshold: ReviewReminderCardTriggerThreshold(2),
        scope: const GlobalReminderScope(),
        enabled: true,
        profileID: 'profile',
        onlyNotifyIfNoReviews: true,
      );

      expect(
        ReviewReminderSchemaV1MapCodec.encode({ReviewReminderId(3): schema}),
        '{"3":{"id":3,"time":{"hour":10,"minute":15},'
        '"cardTriggerThreshold":2,"scope":{"type":"com.ichi2.anki.'
        'reviewreminders.ReviewReminderScope.Global"},"enabled":true,'
        '"profileID":"profile","onlyNotifyIfNoReviews":true}}',
      );
    });
  });

  group('ReviewReminderSchemaV2MapCodec', () {
    test('round trips source field types and scope payload', () {
      const rawJson =
          '{"9":{"id":10,"time":{"hour":23,"minute":59},'
          '"cardTriggerThreshold":2147483647,"scope":{"type":"com.ichi2.'
          'anki.reviewreminders.ReviewReminderScope.DeckSpecific",'
          '"did":9223372036854775807},"enabled":false,'
          '"profileID":"profile-b","onlyNotifyIfNoReviews":false}}';

      final decoded = ReviewReminderSchemaV2MapCodec.decode(rawJson);

      expect(decoded.keys, [ReviewReminderId(9)]);
      expect(decoded[ReviewReminderId(9)]?.id, ReviewReminderId(10));
      expect(
        decoded[ReviewReminderId(9)]?.time,
        ReviewReminderTime(hour: 23, minute: 59),
      );
      expect(
        decoded[ReviewReminderId(9)]?.scope,
        const DeckSpecificReminderScope(9223372036854775807),
      );
      expect(ReviewReminderSchemaV2MapCodec.encode(decoded), rawJson);
    });

    test('requires onlyNotifyIfNoReviews', () {
      expect(
        () => ReviewReminderSchemaV2MapCodec.decode(
          '{"1":{"id":1,"time":{"hour":8,"minute":0},'
          '"cardTriggerThreshold":0,"scope":{"type":"com.ichi2.anki.'
          'reviewreminders.ReviewReminderScope.Global"},"enabled":true,'
          '"profileID":""}}',
        ),
        throwsFormatException,
      );
    });
  });

  test('both codecs reject unknown fields and wrong source types', () {
    const validV1 =
        '{"1":{"id":1,"time":{"hour":8,"minute":0},'
        '"cardTriggerThreshold":0,"scope":{"type":"com.ichi2.anki.'
        'reviewreminders.ReviewReminderScope.Global"},"enabled":true,'
        '"profileID":""}}';
    const validV2 =
        '{"1":{"id":1,"time":{"hour":8,"minute":0},'
        '"cardTriggerThreshold":0,"scope":{"type":"com.ichi2.anki.'
        'reviewreminders.ReviewReminderScope.Global"},"enabled":true,'
        '"profileID":"","onlyNotifyIfNoReviews":false}}';

    expect(
      () => ReviewReminderSchemaV1MapCodec.decode(
        validV1.replaceAll('"profileID":""', '"profileID":"","extra":1'),
      ),
      throwsFormatException,
    );
    expect(
      () => ReviewReminderSchemaV2MapCodec.decode(
        validV2.replaceAll('"enabled":true', '"enabled":"true"'),
      ),
      throwsA(isA<TypeError>()),
    );
    expect(
      () => ReviewReminderSchemaV1MapCodec.decode(
        validV1.replaceAll(
          '"profileID":""',
          '"profileID":"","onlyNotifyIfNoReviews":null',
        ),
      ),
      throwsA(isA<TypeError>()),
    );
    expect(
      () => ReviewReminderSchemaV2MapCodec.decode(
        validV2.replaceAll(
          'ReviewReminderScope.Global"}',
          'ReviewReminderScope.Global","did":1}',
        ),
      ),
      throwsFormatException,
    );
  });
}
