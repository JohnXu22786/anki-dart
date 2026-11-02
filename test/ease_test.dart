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
 * Source-derived from Ease.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Ease', () {
    test('preserves source declaration order and integer values', () {
      expect(Ease.values, [Ease.AGAIN, Ease.HARD, Ease.GOOD, Ease.EASY]);
      expect(Ease.values.map((ease) => ease.value), [1, 2, 3, 4]);
    });

    test('fromValue maps each source integer to its matching entry', () {
      for (final ease in Ease.values) {
        expect(Ease.fromValue(ease.value), same(ease), reason: '${ease.value}');
      }
    });

    test('fromValue rejects integers outside the source values', () {
      for (final value in [0, 5, -1]) {
        expect(() => Ease.fromValue(value), throwsA(isA<StateError>()));
      }
    });
  });
}
