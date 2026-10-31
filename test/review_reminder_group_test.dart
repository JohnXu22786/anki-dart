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
 * Source-derived from ReviewReminderGroup.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

ReviewReminder reminder(int id, {bool enabled = true}) =>
    ReviewReminder.createReviewReminder(
      id: ReviewReminderId(id),
      time: ReviewReminderTime(hour: 8, minute: 0),
      latestNotifTime: 0,
      enabled: enabled,
    );

void main() {
  group('ReviewReminderGroup', () {
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
