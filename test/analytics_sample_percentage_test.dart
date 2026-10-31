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
 * Source-derived from AnalyticsSamplePercentage.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AnalyticsSamplePercentage', () {
    test('accepts the sentinel and inclusive percentage boundaries', () {
      for (final value in [-1, 0, 1, 99, 100]) {
        expect(AnalyticsSamplePercentage(value).value, value);
      }
    });

    test('rejects values outside the contract with the source message', () {
      for (final value in [-2, -3, -101, 101, 1000]) {
        expect(
          () => AnalyticsSamplePercentage(value),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'Analytics sample percentage must be in 0..100 or '
                  'Uninitialized (-1), got $value',
            ),
          ),
          reason: 'value=$value',
        );
      }
    });

    test('tracks initialization and exposes source constants', () {
      expect(AnalyticsSamplePercentage.Uninitialized.value, -1);
      expect(AnalyticsSamplePercentage.Uninitialized.isInitialized, isFalse);
      expect(AnalyticsSamplePercentage.Full.value, 100);
      expect(AnalyticsSamplePercentage.Full.isInitialized, isTrue);

      for (var value = 0; value <= 100; value++) {
        expect(AnalyticsSamplePercentage(value).isInitialized, isTrue);
      }
    });

    test(
      'uses integer value equality, hashing, and value-class string form',
      () {
        final first = AnalyticsSamplePercentage(45);
        final equal = AnalyticsSamplePercentage(45);
        final different = AnalyticsSamplePercentage(46);

        expect(first, equal);
        expect(first.hashCode, equal.hashCode);
        expect(first.hashCode, 45.hashCode);
        expect(first, isNot(different));
        expect(first.toString(), 'AnalyticsSamplePercentage(value=45)');
      },
    );
  });
}
