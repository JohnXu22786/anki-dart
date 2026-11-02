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
 * SPDX-FileCopyrightText: 2026 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-FileCopyrightText: 2022 Ankitects Pty Ltd <https://apps.ankiweb.net>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ViewModelProgress.kt and CoroutineHelpers.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ViewModelProgress', () {
    test('idle is one singleton value', () {
      expect(ViewModelProgress.idle, same(ViewModelProgressIdle.instance));
    });

    test('active defaults format amounts and compare structurally', () {
      final first = ViewModelProgressActive<String>();
      final second = ViewModelProgressActive<String>();
      const amount = ProgressAmount(current: 12, max: 34);

      expect(first.message, isNull);
      expect(first.amount, isNull);
      expect(first.cancellable, isFalse);
      expect(first.separator, ' ');
      expect(first.formatAmount(amount), '12/34');
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('active preserves custom nullable values and formatter output', () {
      const amount = ProgressAmount(current: 5, max: 10);
      String formatter(ProgressAmount value) =>
          '${value.current} of ${value.max}';
      final active = ViewModelProgressActive<String>(
        message: null,
        amount: amount,
        cancellable: true,
        formatAmount: formatter,
        separator: ' — ',
      );

      expect(active.message, isNull);
      expect(active.amount, amount);
      expect(active.cancellable, isTrue);
      expect(active.separator, ' — ');
      expect(active.formatAmount, same(formatter));
      expect(active.formatAmount(amount), '5 of 10');
      final equal = ViewModelProgressActive<String>(
        amount: amount,
        cancellable: true,
        formatAmount: formatter,
        separator: ' — ',
      );

      expect(active, equal);
      expect(active.hashCode, equal.hashCode);
      expect(
        active,
        isNot(
          ViewModelProgressActive<String>(
            amount: amount,
            cancellable: true,
            formatAmount: formatter,
            separator: ' / ',
          ),
        ),
      );
    });

    test(
      'active compares formatter callbacks by identity without calling them',
      () {
        var calls = 0;
        String firstFormatter(ProgressAmount _) {
          calls++;
          return 'same output';
        }

        String secondFormatter(ProgressAmount _) {
          calls++;
          return 'same output';
        }

        final first = ViewModelProgressActive<String>(
          formatAmount: firstFormatter,
        );
        final sameCallback = ViewModelProgressActive<String>(
          formatAmount: firstFormatter,
        );
        final differentCallback = ViewModelProgressActive<String>(
          formatAmount: secondFormatter,
        );

        expect(first, sameCallback);
        expect(first.hashCode, sameCallback.hashCode);
        expect(first, isNot(differentCallback));
        expect(calls, 0);
      },
    );

    test('amount uses structural equality and hash for long range values', () {
      const minimum = ProgressAmount(
        current: -9223372036854775808,
        max: 9223372036854775807,
      );
      const equal = ProgressAmount(
        current: -9223372036854775808,
        max: 9223372036854775807,
      );
      const different = ProgressAmount(
        current: -9223372036854775807,
        max: 9223372036854775807,
      );

      expect(minimum, equal);
      expect(minimum.hashCode, equal.hashCode);
      expect(minimum, isNot(different));
    });
  });
}
