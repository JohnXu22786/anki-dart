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
  group('ReviewReminderId', () {
    test(
      'uses value equality, matching hashes, source-compatible text, and allows negative values',
      () {
        final first = ReviewReminderId(7);
        final equal = ReviewReminderId(7);
        final negative = ReviewReminderId(-1);

        expect(first, equal);
        expect(first.hashCode, equal.hashCode);
        expect(first.toString(), 'ReviewReminderId(value=7)');
        expect(negative.value, -1);
        expect(negative.toString(), 'ReviewReminderId(value=-1)');
        expect(ReviewReminderId(-2147483648).value, -2147483648);
        expect(() => ReviewReminderId(2147483648), throwsArgumentError);
      },
    );

    test(
      'allocation returns the old preference value before the increment',
      () {
        var nextFreeId = 0;
        final ids = <int>[];

        for (var index = 0; index <= 10; index++) {
          final allocation = ReviewReminderId.planNextFreeId(
            currentNextFreeId: nextFreeId,
          );
          ids.add(allocation.id.value);
          nextFreeId = allocation.nextFreeId;
        }

        expect(ids, List<int>.generate(11, (index) => index));
        expect(nextFreeId, 11);

        final overflow = ReviewReminderId.planNextFreeId(
          currentNextFreeId: 2147483647,
        );
        expect(overflow.id.value, 2147483647);
        expect(overflow.nextFreeId, -2147483648);
      },
    );
  });

  group('ReviewReminderCardTriggerThreshold', () {
    test('allows zero and positive thresholds with value semantics', () {
      final zero = ReviewReminderCardTriggerThreshold(0);
      final equalZero = ReviewReminderCardTriggerThreshold(0);
      final positive = ReviewReminderCardTriggerThreshold(3);

      expect(zero, equalZero);
      expect(zero.hashCode, equalZero.hashCode);
      expect(
        zero.toString(),
        'ReviewReminderCardTriggerThreshold(threshold=0)',
      );
      expect(positive.threshold, 3);
      expect(
        ReviewReminderCardTriggerThreshold(2147483647).threshold,
        2147483647,
      );
    });

    test('rejects values outside the nonnegative Int range', () {
      expect(() => ReviewReminderCardTriggerThreshold(-1), throwsArgumentError);
      expect(
        () => ReviewReminderCardTriggerThreshold(2147483648),
        throwsArgumentError,
      );
    });
  });
}
