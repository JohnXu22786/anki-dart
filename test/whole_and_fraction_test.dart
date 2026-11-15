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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Double.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('wholeAndFraction', () {
    test('truncates finite values toward zero and keeps signed remainders', () {
      expect(wholeAndFraction(12.75), (whole: 12, fraction: 0.75));
      expect(wholeAndFraction(-12.75), (whole: -12, fraction: -0.75));
      expect(wholeAndFraction(-0.0), (whole: 0, fraction: -0.0));
      expect(1 / wholeAndFraction(-0.0).fraction, double.negativeInfinity);
    });

    test('maps NaN and infinities with Kotlin Long conversion behavior', () {
      final nan = wholeAndFraction(double.nan);
      expect(nan.whole, 0);
      expect(nan.fraction.isNaN, isTrue);

      expect(wholeAndFraction(double.infinity), (
        whole: 9223372036854775807,
        fraction: double.infinity,
      ));
      expect(wholeAndFraction(double.negativeInfinity), (
        whole: -9223372036854775808,
        fraction: double.negativeInfinity,
      ));
    });

    test(
      'saturates at Long bounds before computing the binary64 remainder',
      () {
        const positiveBound = 9223372036854775808.0;
        const negativeBound = -9223372036854775808.0;

        expect(wholeAndFraction(positiveBound), (
          whole: 9223372036854775807,
          fraction: 0.0,
        ));
        expect(wholeAndFraction(negativeBound), (
          whole: -9223372036854775808,
          fraction: 0.0,
        ));
        expect(wholeAndFraction(positiveBound + 2048.0), (
          whole: 9223372036854775807,
          fraction: 2048.0,
        ));
        expect(wholeAndFraction(negativeBound - 2048.0), (
          whole: -9223372036854775808,
          fraction: -2048.0,
        ));
      },
    );
  });
}
