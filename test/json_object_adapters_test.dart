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
 * Source-derived from JSONObjectTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('jsonObjectGetStringOrNull', () {
    test('skips reads for absent keys and JSON null values', () {
      final calls = <String>[];
      final absent = jsonObjectGetStringOrNull(
        key: 'test',
        has: (key) {
          calls.add('has:$key');
          return false;
        },
        isNull: (_) {
          calls.add('isNull');
          return false;
        },
        getString: (_) {
          calls.add('getString');
          return 'unexpected';
        },
      );
      expect(absent, isNull);
      expect(calls, ['has:test']);

      calls.clear();
      final jsonNull = jsonObjectGetStringOrNull(
        key: 'test',
        has: (key) {
          calls.add('has:$key');
          return true;
        },
        isNull: (key) {
          calls.add('isNull:$key');
          return true;
        },
        getString: (_) {
          calls.add('getString');
          return 'unexpected';
        },
      );
      expect(jsonNull, isNull);
      expect(calls, ['has:test', 'isNull:test']);
    });

    test(
      'returns the exact host string and catches only Exception from getter',
      () {
        final calls = <String>[];
        expect(
          jsonObjectGetStringOrNull(
            key: 'test',
            has: (_) {
              calls.add('has');
              return true;
            },
            isNull: (_) {
              calls.add('isNull');
              return false;
            },
            getString: (_) {
              calls.add('getString');
              return 'Android converted value';
            },
          ),
          'Android converted value',
        );
        expect(calls, ['has', 'isNull', 'getString']);
        expect(
          jsonObjectGetStringOrNull(
            key: 'test',
            has: (_) => true,
            isNull: (_) => false,
            getString: (_) => throw const FormatException('not a String'),
          ),
          isNull,
        );

        final error = StateError('not caught by Exception');
        expect(
          () => jsonObjectGetStringOrNull(
            key: 'test',
            has: (_) => true,
            isNull: (_) => false,
            getString: (_) => throw error,
          ),
          throwsA(same(error)),
        );
      },
    );

    test('does not catch failures from presence or null checks', () {
      final error = StateError('presence read failed');
      expect(
        () => jsonObjectGetStringOrNull(
          key: 'test',
          has: (_) => throw error,
          isNull: (_) => false,
          getString: (_) => 'unused',
        ),
        throwsA(same(error)),
      );
    });
  });

  group('jsonObjectIterable', () {
    test('is lazy and reads object values in key order', () {
      final calls = <String>[];
      final iterable = jsonObjectIterable<String>(
        keys: () {
          calls.add('keys');
          return ['1', '2'];
        },
        getJSONObject: (key) {
          calls.add('get:$key');
          return 'object:$key';
        },
      );

      expect(calls, isEmpty);
      expect(iterable.toList(), ['object:1', 'object:2']);
      expect(calls, ['keys', 'get:1', 'get:2']);
    });

    test('obtains fresh keys for each iteration', () {
      var keyReads = 0;
      final iterable = jsonObjectIterable<String>(
        keys: () {
          keyReads++;
          return ['key'];
        },
        getJSONObject: (key) => '$key$keyReads',
      );

      expect(iterable.toList(), ['key1']);
      expect(iterable.toList(), ['key2']);
      expect(keyReads, 2);
    });

    test('propagates a typed object-read failure at its element', () {
      final failure = FormatException('not a JSONObject');
      final iterator = jsonObjectIterable<String>(
        keys: () => ['1', '2'],
        getJSONObject: (key) {
          if (key == '2') throw failure;
          return 'first';
        },
      ).iterator;

      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, 'first');
      expect(() => iterator.moveNext(), throwsA(same(failure)));
    });

    test('supports an empty object', () {
      final iterable = jsonObjectIterable<String>(
        keys: () => const [],
        getJSONObject: (_) => 'unexpected',
      );
      expect(iterable, isEmpty);
    });
  });
}
