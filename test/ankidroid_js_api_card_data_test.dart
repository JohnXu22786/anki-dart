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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from AnkiDroidJsAPI.kt:605–613; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CardDataForJsApi', () {
    test('uses the source defaults for all public fields', () {
      final data = CardDataForJsApi();

      expect(data.newCardCount, -1);
      expect(data.lrnCardCount, -1);
      expect(data.revCardCount, -1);
      expect(data.eta, -1);
      expect(data.nextTime1, '');
      expect(data.nextTime2, '');
      expect(data.nextTime3, '');
      expect(data.nextTime4, '');
    });

    test('keeps all fields mutable and instances identity-equal only', () {
      final first = CardDataForJsApi();
      final second = CardDataForJsApi();

      first.newCardCount = 1;
      first.lrnCardCount = 2;
      first.revCardCount = 3;
      first.eta = 4;
      first.nextTime1 = 'one';
      first.nextTime2 = 'two';
      first.nextTime3 = 'three';
      first.nextTime4 = 'four';

      expect(first.newCardCount, 1);
      expect(first.lrnCardCount, 2);
      expect(first.revCardCount, 3);
      expect(first.eta, 4);
      expect(first.nextTime1, 'one');
      expect(first.nextTime2, 'two');
      expect(first.nextTime3, 'three');
      expect(first.nextTime4, 'four');
      expect(identical(first, second), isFalse);
      expect(first, isNot(second));
    });
  });
}
