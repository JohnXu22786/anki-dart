/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived cases from Collection.kt; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CollectionCardStateCustomizer', () {
    test('forwards the exact key once and returns the exact String', () {
      final key = Object();
      const value = 'window.customSchedule = "exact ✓";';
      var calls = 0;
      final adapter = CollectionCardStateCustomizer<Object>(
        key: key,
        getString: (receivedKey) {
          calls++;
          expect(receivedKey, same(key));
          return value;
        },
        setString: (_, _) => fail('setter must not be called by the getter'),
      );

      expect(adapter.cardStateCustomizer, value);
      expect(calls, 1);
    });

    test('forwards the exact key and supplied String once', () {
      final key = Object();
      const value = 'return "unchanged ✓";';
      var calls = 0;
      final adapter = CollectionCardStateCustomizer<Object>(
        key: key,
        getString: (_) => fail('getter must not be called by the setter'),
        setString: (receivedKey, receivedValue) {
          calls++;
          expect(receivedKey, same(key));
          expect(receivedValue, value);
        },
      );

      adapter.cardStateCustomizer = value;
      expect(calls, 1);
    });

    test('propagates a getter exception unchanged', () {
      final key = Object();
      final error = Exception('get failed');
      final adapter = CollectionCardStateCustomizer<Object>(
        key: key,
        getString: (_) => throw error,
        setString: (_, _) => fail('setter must not be called by the getter'),
      );

      expect(() => adapter.cardStateCustomizer, throwsA(same(error)));
    });

    test('propagates a setter exception unchanged', () {
      final key = Object();
      final error = Exception('set failed');
      final adapter = CollectionCardStateCustomizer<Object>(
        key: key,
        getString: (_) => fail('getter must not be called by the setter'),
        setString: (_, _) => throw error,
      );

      expect(
        () => adapter.cardStateCustomizer = 'script',
        throwsA(same(error)),
      );
    });
  });
}
