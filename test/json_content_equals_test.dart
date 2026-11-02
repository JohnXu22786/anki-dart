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

String _numberToJsonString(num value) {
  if (value == 0 && value.isNegative) return '-0.0';
  if (value is int) return value.toString();
  if (value.isFinite && value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}

void main() {
  group('jsonContentEquals', () {
    test('compares nested objects independent of key order', () {
      final first = {
        'css': 'é 😀',
        'values': [
          true,
          false,
          null,
          <String, Object?>{},
          <Object?>[],
          {'front': 'a', 'back': 'b'},
        ],
      };
      final second = {
        'values': [
          true,
          false,
          ankiJsonNull,
          <String, Object?>{},
          <Object?>[],
          {'back': 'b', 'front': 'a'},
        ],
        'css': 'é 😀',
      };

      expect(
        jsonContentEquals(first, first, numberToString: _numberToJsonString),
        isTrue,
      );
      expect(
        jsonContentEquals(first, second, numberToString: _numberToJsonString),
        isTrue,
      );
      expect(
        jsonContentEquals(second, first, numberToString: _numberToJsonString),
        isTrue,
      );
    });

    test(
      'detects changed keys, JSON types, nested values, and array order',
      () {
        final differentValues = <(Object?, Object?)>[
          (<String, Object?>{}, {'value': null}),
          ({'first': null}, {'second': null}),
          ({'value': null}, {'value': 'null'}),
          ({'value': 1}, {'value': '1'}),
          ({'value': true}, {'value': false}),
          ({'value': <String, Object?>{}}, {'value': <Object?>[]}),
          (
            {
              'values': [1, 2],
            },
            {
              'values': [2, 1],
            },
          ),
          (
            {
              'values': [1],
            },
            {
              'values': [1, 2],
            },
          ),
          (
            {
              'values': [
                {'front': 'a'},
              ],
            },
            {
              'values': [
                {'front': 'b'},
              ],
            },
          ),
        ];

        for (final (first, second) in differentValues) {
          expect(
            jsonContentEquals(
              first,
              second,
              numberToString: _numberToJsonString,
            ),
            isFalse,
          );
          expect(
            jsonContentEquals(
              second,
              first,
              numberToString: _numberToJsonString,
            ),
            isFalse,
          );
        }
      },
    );

    test(
      'compares numbers by host JSON representation without losing integers',
      () {
        expect(
          jsonContentEquals(1, 1.0, numberToString: _numberToJsonString),
          isTrue,
        );
        expect(
          jsonContentEquals(-0.0, 0, numberToString: _numberToJsonString),
          isFalse,
        );
        expect(
          jsonContentEquals(
            9007199254740992,
            9007199254740993,
            numberToString: _numberToJsonString,
          ),
          isFalse,
        );
        expect(
          jsonContentEquals(
            9223372036854775807,
            9223372036854775806,
            numberToString: _numberToJsonString,
          ),
          isFalse,
        );
      },
    );

    test('treats sparse array slots as JSON null', () {
      expect(
        jsonContentEquals(
          {
            'values': [ankiJsonNull, ankiJsonNull, 'third'],
          },
          {
            'values': [null, null, 'third'],
          },
          numberToString: _numberToJsonString,
        ),
        isTrue,
      );
    });

    test(
      'stops at the first mismatch and propagates number callback errors',
      () {
        var comparisons = 0;
        expect(
          jsonContentEquals(
            {'first': 1, 'later': 2},
            {'first': 'different', 'later': 3},
            numberToString: (value) {
              comparisons++;
              return value.toString();
            },
          ),
          isFalse,
        );
        expect(comparisons, 0);

        final failure = StateError('number formatting failed');
        expect(
          () => jsonContentEquals(
            {'value': 1},
            {'value': 2},
            numberToString: (_) => throw failure,
          ),
          throwsA(same(failure)),
        );
      },
    );
  });
}
