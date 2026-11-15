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
 * Source-derived from ReviewReminderGroup.kt, ReviewReminder.kt, and the
 * current-schema fixture in ReviewRemindersDatabaseTest.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

ReviewReminder reminder(int id, {bool enabled = true}) =>
    ReviewReminder.createReviewReminder(
      id: ReviewReminderId(id),
      time: ReviewReminderTime(hour: 8, minute: 0),
      latestNotifTime: BigInt.from(0),
      enabled: enabled,
    );

void main() {
  group('ReviewReminderGroup', () {
    test('decodes and re-encodes the current-schema database golden JSON', () {
      const rawJson =
          '{"22":{"id":22,"time":{"hour":14,"minute":16},'
          '"cardTriggerThreshold":1,"scope":{"type":"com.ichi2.anki.'
          'reviewreminders.ReviewReminderScope.Global"},"enabled":true,'
          '"latestNotifTime":1771193761002,"profileID":"",'
          '"onlyNotifyIfNoReviews":false}}';

      final group = ReviewReminderGroup.fromJsonString(rawJson);

      expect(
        group[ReviewReminderId(22)],
        ReviewReminder.createReviewReminder(
          id: ReviewReminderId(22),
          time: ReviewReminderTime(hour: 14, minute: 16),
          cardTriggerThreshold: ReviewReminderCardTriggerThreshold(1),
          latestNotifTime: BigInt.from(1771193761002),
        ),
      );
      expect(group.serializeToString(), rawJson);
    });

    test('round trips DeckSpecific scope discriminator and deck payload', () {
      final group = ReviewReminderGroup.fromPairs([
        MapEntry(
          ReviewReminderId(7),
          ReviewReminder.createReviewReminder(
            id: ReviewReminderId(7),
            time: ReviewReminderTime(hour: 9, minute: 30),
            cardTriggerThreshold: ReviewReminderCardTriggerThreshold(12),
            scope: DeckSpecificReminderScope(BigInt.from(-42)),
            enabled: false,
            latestNotifTime: BigInt.from(1234),
            profileID: 'profile-a',
            onlyNotifyIfNoReviews: true,
          ),
        ),
      ]);

      const expectedJson =
          '{"7":{"id":7,"time":{"hour":9,"minute":30},'
          '"cardTriggerThreshold":12,"scope":{"type":"com.ichi2.anki.'
          'reviewreminders.ReviewReminderScope.DeckSpecific","did":-42},'
          '"enabled":false,"latestNotifTime":1234,'
          '"profileID":"profile-a","onlyNotifyIfNoReviews":true}}';

      expect(group.serializeToString(), expectedJson);
      expect(ReviewReminderGroup.fromJsonString(expectedJson), group);
    });

    test(
      'preserves Long timestamp and deck IDs beyond JavaScript safe integers',
      () {
        const rawJson =
            '{"7":{"id":7,"time":{"hour":1,"minute":2},'
            '"cardTriggerThreshold":0,"scope":{"type":"com.ichi2.anki.'
            'reviewreminders.ReviewReminderScope.DeckSpecific",'
            '"did":9223372036854775807},"enabled":true,'
            '"latestNotifTime":9007199254740993,"profileID":"",'
            '"onlyNotifyIfNoReviews":false}}';

        final group = ReviewReminderGroup.fromJsonString(rawJson);
        final reminder = group[ReviewReminderId(7)]!;
        expect(
          (reminder.scope as DeckSpecificReminderScope).deckId,
          BigInt.parse('9223372036854775807'),
        );
        expect(reminder.latestNotifTime, BigInt.parse('9007199254740993'));
        expect(group.serializeToString(), rawJson);

        final minimumJson = rawJson
            .replaceFirst('9223372036854775807', '-9223372036854775808')
            .replaceFirst('9007199254740993', '9007199254740994');
        final minimumRoundTrip = ReviewReminderGroup.fromJsonString(
          minimumJson,
        );
        expect(
          (minimumRoundTrip[ReviewReminderId(7)]!.scope
                  as DeckSpecificReminderScope)
              .deckId,
          BigInt.parse('-9223372036854775808'),
        );
        expect(
          minimumRoundTrip[ReviewReminderId(7)]!.latestNotifTime,
          BigInt.parse('9007199254740994'),
        );
        expect(minimumRoundTrip.serializeToString(), minimumJson);

        expect(
          () => ReviewReminderGroup.fromJsonString(
            rawJson.replaceFirst('9007199254740993', '9223372036854775808'),
          ),
          throwsFormatException,
        );
      },
    );

    test('rejects out-of-range Long fields during JSON serialization', () {
      final tooLarge = BigInt.parse('9223372036854775808');
      final timestampReminder = ReviewReminder.createReviewReminder(
        id: ReviewReminderId(1),
        time: ReviewReminderTime(hour: 1, minute: 2),
        latestNotifTime: tooLarge,
      );
      final timestampGroup = ReviewReminderGroup.fromPairs([
        MapEntry(timestampReminder.id, timestampReminder),
      ]);
      expect(timestampGroup.serializeToString, throwsArgumentError);

      final deckReminder = ReviewReminder.createReviewReminder(
        id: ReviewReminderId(2),
        time: ReviewReminderTime(hour: 1, minute: 2),
        latestNotifTime: BigInt.zero,
        scope: DeckSpecificReminderScope(tooLarge),
      );
      final deckGroup = ReviewReminderGroup.fromPairs([
        MapEntry(deckReminder.id, deckReminder),
      ]);
      expect(deckGroup.serializeToString, throwsArgumentError);
    });

    test('malformed and wrongly typed JSON fails during decoding', () {
      expect(
        () => ReviewReminderGroup.fromJsonString('{'),
        throwsFormatException,
      );
      expect(
        () => ReviewReminderGroup.fromJsonString(
          '{"22":{"id":22,"time":{"hour":14,"minute":16},'
          '"cardTriggerThreshold":1,"scope":{"type":"com.ichi2.anki.'
          'reviewreminders.ReviewReminderScope.Global"},"enabled":"true",'
          '"latestNotifTime":1771193761002,"profileID":"",'
          '"onlyNotifyIfNoReviews":false}}',
        ),
        throwsA(isA<TypeError>()),
      );
    });

    test(
      'copies map associations and retains values without key validation',
      () {
        final value = reminder(10);
        final input = <ReviewReminderId, ReviewReminder>{
          ReviewReminderId(1): value,
        };

        final group = ReviewReminderGroup.fromMap(input);
        input[ReviewReminderId(2)] = reminder(2);

        expect(group.getRemindersList(), hasLength(1));
        expect(identical(group[ReviewReminderId(1)], value), isTrue);
        expect(group[ReviewReminderId(10)], isNull);

        final pairs = ReviewReminderGroup.fromPairs([
          MapEntry(ReviewReminderId(3), reminder(30)),
        ]);
        expect(pairs[ReviewReminderId(3)]?.id, ReviewReminderId(30));
        expect(ReviewReminderGroup().isEmpty(), isTrue);
      },
    );

    test('plus and mergeAll let later groups replace collisions', () {
      final id = ReviewReminderId(1);
      final first = ReviewReminderGroup.fromPairs([MapEntry(id, reminder(1))]);
      final secondValue = reminder(2, enabled: false);
      final second = ReviewReminderGroup.fromPairs([MapEntry(id, secondValue)]);

      expect(identical((first + second)[id], secondValue), isTrue);
      expect(identical([first, second].mergeAll()[id], secondValue), isTrue);
      expect(<ReviewReminderGroup>[].mergeAll().isEmpty(), isTrue);

      final thirdValue = reminder(3);
      final three = ReviewReminderGroup.fromPairs([MapEntry(id, thirdValue)]);
      expect(
        identical([first, second, three].mergeAll()[id], thirdValue),
        isTrue,
      );
    });

    test(
      'supports lookup, updates, removal, entry iteration, and toggle no-op',
      () {
        final id = ReviewReminderId(5);
        final existing = reminder(5);
        final group = ReviewReminderGroup.fromMap({id: existing});
        expect(group.isEmpty(), isFalse);
        expect(identical(group[id], existing), isTrue);

        final replacement = reminder(6);
        group[id] = replacement;
        expect(identical(group[id], replacement), isTrue);

        final entries = <ReviewReminderId, ReviewReminder>{};
        group.forEach((entry) => entries[entry.key] = entry.value);
        expect(entries, {id: replacement});
        expect(group.getRemindersList(), [replacement]);

        group.toggleEnabled(id);
        expect(replacement.enabled, isFalse);
        group.toggleEnabled(ReviewReminderId(999));
        expect(replacement.enabled, isFalse);
        group.remove(id);
        expect(group[id], isNull);
        expect(group.isEmpty(), isTrue);
      },
    );

    test('equality and hash are structural and ignore entry order', () {
      final first = ReviewReminderGroup.fromPairs([
        MapEntry(ReviewReminderId(1), reminder(1)),
        MapEntry(ReviewReminderId(2), reminder(2)),
      ]);
      final reversed = ReviewReminderGroup.fromPairs([
        MapEntry(ReviewReminderId(2), reminder(2)),
        MapEntry(ReviewReminderId(1), reminder(1)),
      ]);
      final different = ReviewReminderGroup.fromPairs([
        MapEntry(ReviewReminderId(1), reminder(1, enabled: false)),
        MapEntry(ReviewReminderId(2), reminder(2)),
      ]);

      expect(first, reversed);
      expect(first.hashCode, reversed.hashCode);
      expect(first, isNot(different));
    });
  });
}
