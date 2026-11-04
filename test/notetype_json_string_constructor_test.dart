/*
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from NotetypeJson.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NotetypeJsonStringConstructor', () {
    test('passes exact string and parsed object once in source order', () {
      const jsonString = '  {"field": "value"}\n';
      final parsedJsonObject = Object();
      final wrapper = Object();
      final calls = <String>[];
      final constructor = NotetypeJsonStringConstructor<Object, Object>(
        parseJsonObjectString: (actualString) {
          calls.add('parse');
          expect(actualString, jsonString);
          return parsedJsonObject;
        },
        wrapJsonObject: (actualJsonObject) {
          calls.add('wrap');
          expect(actualJsonObject, same(parsedJsonObject));
          return wrapper;
        },
      );

      final result = constructor.construct(jsonString);

      expect(calls, ['parse', 'wrap']);
      expect(result, same(wrapper));
    });

    test('returns the exact host wrapper result', () {
      final wrapper = Object();
      final constructor = NotetypeJsonStringConstructor<Object, Object>(
        parseJsonObjectString: (_) => Object(),
        wrapJsonObject: (_) => wrapper,
      );

      expect(constructor.construct('{}'), same(wrapper));
    });

    test('preserves parser failure identity and skips wrapper', () {
      final failure = FormatException('host parser failed');
      final calls = <String>[];
      final constructor = NotetypeJsonStringConstructor<Object, Object>(
        parseJsonObjectString: (_) {
          calls.add('parse');
          throw failure;
        },
        wrapJsonObject: (_) {
          calls.add('wrap');
          return Object();
        },
      );

      expect(() => constructor.construct('{'), throwsA(same(failure)));
      expect(calls, ['parse']);
    });

    test('preserves wrapper failure identity after parsing once', () {
      final failure = StateError('host wrapper failed');
      final parsedJsonObject = Object();
      final calls = <String>[];
      final constructor = NotetypeJsonStringConstructor<Object, Object>(
        parseJsonObjectString: (_) {
          calls.add('parse');
          return parsedJsonObject;
        },
        wrapJsonObject: (actualJsonObject) {
          calls.add('wrap');
          expect(actualJsonObject, same(parsedJsonObject));
          throw failure;
        },
      );

      expect(() => constructor.construct('{}'), throwsA(same(failure)));
      expect(calls, ['parse', 'wrap']);
    });
  });
}
