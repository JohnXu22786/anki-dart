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
 * Source-derived from NotetypeJson.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NotetypeJsonObjectOperations', () {
    test(
      'deepClone reads, clones, wraps in order and returns exact wrapper',
      () {
        final notetype = Object();
        final jsonObject = Object();
        final clone = Object();
        final wrapper = Object();
        final calls = <String>[];
        final operations = NotetypeJsonObjectOperations<Object, Object, Object>(
          notetypeJson: notetype,
          getJsonObject: (actualNotetype) {
            calls.add('read');
            expect(actualNotetype, same(notetype));
            return jsonObject;
          },
          deepCloneJsonObject: (actualJsonObject) {
            calls.add('clone');
            expect(actualJsonObject, same(jsonObject));
            return clone;
          },
          wrapJsonObject: (actualJsonObject) {
            calls.add('wrap');
            expect(actualJsonObject, same(clone));
            return wrapper;
          },
          jsonObjectToString: (_) => 'unused',
        );

        final result = operations.deepClone();

        expect(calls, ['read', 'clone', 'wrap']);
        expect(result, same(wrapper));
      },
    );

    test('deepClone preserves the exact clone failure', () {
      final failure = StateError('clone failed');
      final calls = <String>[];
      final operations = NotetypeJsonObjectOperations<Object, Object, Object>(
        notetypeJson: Object(),
        getJsonObject: (_) {
          calls.add('read');
          return Object();
        },
        deepCloneJsonObject: (_) {
          calls.add('clone');
          throw failure;
        },
        wrapJsonObject: (_) {
          calls.add('wrap');
          return Object();
        },
        jsonObjectToString: (_) => 'unused',
      );

      expect(() => operations.deepClone(), throwsA(same(failure)));
      expect(calls, ['read', 'clone']);
    });

    test('deepClone preserves the exact wrapper failure', () {
      final failure = StateError('wrap failed');
      final calls = <String>[];
      final clone = Object();
      final operations = NotetypeJsonObjectOperations<Object, Object, Object>(
        notetypeJson: Object(),
        getJsonObject: (_) {
          calls.add('read');
          return Object();
        },
        deepCloneJsonObject: (_) {
          calls.add('clone');
          return clone;
        },
        wrapJsonObject: (actualClone) {
          calls.add('wrap');
          expect(actualClone, same(clone));
          throw failure;
        },
        jsonObjectToString: (_) => 'unused',
      );

      expect(() => operations.deepClone(), throwsA(same(failure)));
      expect(calls, ['read', 'clone', 'wrap']);
    });

    test('toString returns the exact host result from one conversion', () {
      final notetype = Object();
      final jsonObject = Object();
      final hostResult = String.fromCharCodes([0x61, 0x00, 0x62]);
      final calls = <String>[];
      final operations = NotetypeJsonObjectOperations<Object, Object, Object>(
        notetypeJson: notetype,
        getJsonObject: (actualNotetype) {
          calls.add('read');
          expect(actualNotetype, same(notetype));
          return jsonObject;
        },
        deepCloneJsonObject: (_) => Object(),
        wrapJsonObject: (_) => Object(),
        jsonObjectToString: (actualJsonObject) {
          calls.add('toString');
          expect(actualJsonObject, same(jsonObject));
          return hostResult;
        },
      );

      final result = operations.toString();

      expect(result, same(hostResult));
      expect(calls, ['read', 'toString']);
    });

    test('toString preserves the exact host formatting failure', () {
      final failure = StateError('format failed');
      final calls = <String>[];
      final operations = NotetypeJsonObjectOperations<Object, Object, Object>(
        notetypeJson: Object(),
        getJsonObject: (_) {
          calls.add('read');
          return Object();
        },
        deepCloneJsonObject: (_) => Object(),
        wrapJsonObject: (_) => Object(),
        jsonObjectToString: (_) {
          calls.add('toString');
          throw failure;
        },
      );

      expect(() => operations.toString(), throwsA(same(failure)));
      expect(calls, ['read', 'toString']);
    });
  });
}
