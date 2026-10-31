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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('projectBrowserRepositionQueueBounds', () {
    test('orders ordinary bounds into top and bottom', () {
      final bounds = projectBrowserRepositionQueueBounds(min: 2, max: 7);

      expect(bounds.queueTop, 2);
      expect(bounds.queueBottom, 7);
    });

    test('orders reversed bounds', () {
      final bounds = projectBrowserRepositionQueueBounds(min: 8, max: 3);

      expect(bounds.queueTop, 3);
      expect(bounds.queueBottom, 8);
    });

    test('preserves equal bounds', () {
      final bounds = projectBrowserRepositionQueueBounds(min: 5, max: 5);

      expect(bounds.queueTop, 5);
      expect(bounds.queueBottom, 5);
    });

    test('preserves negative values while ordering them', () {
      final bounds = projectBrowserRepositionQueueBounds(min: -8, max: -3);

      expect(bounds.queueTop, -8);
      expect(bounds.queueBottom, -3);
    });

    test('null min clears both bounds', () {
      final bounds = projectBrowserRepositionQueueBounds(min: null, max: 4);

      expect(bounds.queueTop, isNull);
      expect(bounds.queueBottom, isNull);
    });

    test('null max clears both bounds', () {
      final bounds = projectBrowserRepositionQueueBounds(min: 4, max: null);

      expect(bounds.queueTop, isNull);
      expect(bounds.queueBottom, isNull);
    });
  });
}
