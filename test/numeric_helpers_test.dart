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
 * Source-derived from LongTest.kt and FloatTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

double _float32(double value) => Float32List.fromList([value])[0];

void main() {
  group('longIfZero', () {
    test('calls the default once only for zero', () {
      var calls = 0;
      int fallback() {
        calls++;
        return 2;
      }

      expect(longIfZero(0, fallback), 2);
      expect(calls, 1);
      expect(longIfZero(1, fallback), 1);
      expect(calls, 1);
      expect(longIfZero(-1, fallback), -1);
      expect(calls, 1);
    });

    test('propagates a default callback failure unchanged', () {
      final failure = StateError('default failed');
      expect(() => longIfZero(0, () => throw failure), throwsA(same(failure)));
    });
  });

  group('clampFloat', () {
    test('matches the source bounds and in-range examples', () {
      expect(clampFloat(1.0, 0, 1), 1.0);
      expect(clampFloat(1.1, 0, 1), 1.0);
      expect(clampFloat(0, 0, 1), 0.0);
      expect(clampFloat(-1, 0, 1), 0.0);
      expect(clampFloat(0.5, 0, 1), 0.5);
      expect(clampFloat(0.3, 0, 1), _float32(0.3));
      expect(clampFloat(1.1, 0, 1000), _float32(1.1));
    });

    test('keeps the source comparison order for reversed bounds', () {
      expect(clampFloat(5, 10, 0), 10.0);
      expect(clampFloat(11, 10, 0), 0.0);
    });

    test('preserves NaN and signed zero comparison outcomes', () {
      expect(clampFloat(double.nan, 0, 1).isNaN, isTrue);
      expect(clampFloat(-0.0, -1, 1).isNegative, isTrue);
      expect(clampFloat(double.infinity, 0, 1), 1.0);
      expect(clampFloat(double.negativeInfinity, 0, 1), 0.0);
    });
  });
}
