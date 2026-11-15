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
 * Source-derived cases from Config.kt; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('IgnoreAccentsInSearchConfig', () {
    test('forwards the exact key once and returns the stored Boolean', () {
      final key = Object();

      for (final value in [false, true]) {
        var calls = 0;
        final config = IgnoreAccentsInSearchConfig<Object>(
          key: key,
          getBool: (receivedKey) {
            calls++;
            expect(receivedKey, same(key));
            return value;
          },
          setBool: (_, _) => fail('setter must not be called by the getter'),
        );

        expect(config.ignoreAccentsInSearch, value);
        expect(calls, 1);
      }
    });

    test('forwards the exact key and supplied Boolean once', () {
      final key = Object();

      for (final value in [false, true]) {
        var calls = 0;
        final config = IgnoreAccentsInSearchConfig<Object>(
          key: key,
          getBool: (_) => fail('getter must not be called by the setter'),
          setBool: (receivedKey, receivedValue) {
            calls++;
            expect(receivedKey, same(key));
            expect(receivedValue, value);
          },
        );

        config.ignoreAccentsInSearch = value;
        expect(calls, 1);
      }
    });

    test('propagates a getter exception unchanged', () {
      final key = Object();
      final error = Exception('get failed');
      final config = IgnoreAccentsInSearchConfig<Object>(
        key: key,
        getBool: (_) => throw error,
        setBool: (_, _) => fail('setter must not be called by the getter'),
      );

      expect(() => config.ignoreAccentsInSearch, throwsA(same(error)));
    });

    test('propagates a setter exception unchanged', () {
      final key = Object();
      final error = Exception('set failed');
      final config = IgnoreAccentsInSearchConfig<Object>(
        key: key,
        getBool: (_) => fail('getter must not be called by the setter'),
        setBool: (_, _) => throw error,
      );

      expect(() => config.ignoreAccentsInSearch = true, throwsA(same(error)));
    });
  });
}
