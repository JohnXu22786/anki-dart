/*
 * Copyright © 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from SavedStateHandle.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('SavedStateHandle scalar helpers', () {
    test(
      'require forwards key once and preserves non-null object identity',
      () {
        final value = _Value();
        final keys = <String>[];

        final result = savedStateHandleRequire<_Value>('item', (key) {
          keys.add(key);
          return value;
        });

        expect(identical(result, value), isTrue);
        expect(keys, ['item']);
      },
    );

    test(
      'require reports the exact source message when getter returns null',
      () {
        final keys = <String>[];

        expect(
          () => savedStateHandleRequire<Object>('missing', (key) {
            keys.add(key);
            return null;
          }),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              "Wrong type or key 'missing' not found",
            ),
          ),
        );
        expect(keys, ['missing']);
      },
    );

    test('require propagates getter exception unchanged', () {
      final failure = StateError('host getter failed');
      var calls = 0;

      expect(
        () => savedStateHandleRequire<Object>('key', (_) {
          calls++;
          throw failure;
        }),
        throwsA(same(failure)),
      );
      expect(calls, 1);
    });

    test(
      'Long lookup checks once, skips absent reads, and reads present values',
      () {
        final absentEvents = <String>[];
        final absent = savedStateHandleGetLongOrNull(
          'absent',
          contains: (key) {
            absentEvents.add('contains:$key');
            return false;
          },
          get: (key) {
            absentEvents.add('get:$key');
            return 1;
          },
        );
        expect(absent, isNull);
        expect(absentEvents, ['contains:absent']);

        final presentEvents = <String>[];
        final present = savedStateHandleGetLongOrNull(
          'present',
          contains: (key) {
            presentEvents.add('contains:$key');
            return true;
          },
          get: (key) {
            presentEvents.add('get:$key');
            return 9223372036854775807;
          },
        );
        expect(present, 9223372036854775807);
        expect(presentEvents, ['contains:present', 'get:present']);

        final nullEvents = <String>[];
        final nullValue = savedStateHandleGetLongOrNull(
          'null',
          contains: (key) {
            nullEvents.add('contains:$key');
            return true;
          },
          get: (key) {
            nullEvents.add('get:$key');
            return null;
          },
        );
        expect(nullValue, isNull);
        expect(nullEvents, ['contains:null', 'get:null']);
      },
    );

    test(
      'Long lookup casts wrong types and propagates callback exceptions',
      () {
        final wrongTypeEvents = <String>[];
        expect(
          () => savedStateHandleGetLongOrNull(
            'wrong',
            contains: (key) {
              wrongTypeEvents.add('contains:$key');
              return true;
            },
            get: (key) {
              wrongTypeEvents.add('get:$key');
              return 'not a Long';
            },
          ),
          throwsA(isA<TypeError>()),
        );
        expect(wrongTypeEvents, ['contains:wrong', 'get:wrong']);

        final containsFailure = StateError('contains failed');
        expect(
          () => savedStateHandleGetLongOrNull(
            'key',
            contains: (_) => throw containsFailure,
            get: (_) => fail('getter must not run'),
          ),
          throwsA(same(containsFailure)),
        );

        final getterFailure = StateError('getter failed');
        expect(
          () => savedStateHandleGetLongOrNull(
            'key',
            contains: (_) => true,
            get: (_) => throw getterFailure,
          ),
          throwsA(same(getterFailure)),
        );
      },
    );
  });
}

final class _Value {}
