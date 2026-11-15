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
 * Source-derived from StringUtilsTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('stringIndexOfOrNull', () {
    test('returns null for absent characters and empty strings', () {
      expect(stringIndexOfOrNull('hello', 0x7a), isNull);
      expect(stringIndexOfOrNull('', 0x61), isNull);
    });

    test('returns the first matching UTF-16 index', () {
      expect(stringIndexOfOrNull('hello', 0x68), 0);
      expect(stringIndexOfOrNull('hello', 0x6f), 4);
      expect(stringIndexOfOrNull('banana', 0x61), 1);
      expect(stringIndexOfOrNull('aaa', 0x61), 0);
    });

    test('preserves negative and oversized start indexes', () {
      expect(stringIndexOfOrNull('banana', 0x61, startIndex: -3), 1);
      expect(stringIndexOfOrNull('banana', 0x61, startIndex: 2), 3);
      expect(stringIndexOfOrNull('banana', 0x61, startIndex: 6), isNull);
      expect(stringIndexOfOrNull('😀', 0xde00), 1);
    });
  });

  group('stringLastIndexOfCharOrNull', () {
    test('returns null for absent characters and empty strings', () {
      expect(stringLastIndexOfCharOrNull('hello', 0x7a), isNull);
      expect(stringLastIndexOfCharOrNull('', 0x61), isNull);
    });

    test('returns the last matching UTF-16 index', () {
      expect(stringLastIndexOfCharOrNull('hello', 0x68), 0);
      expect(stringLastIndexOfCharOrNull('hello', 0x6f), 4);
      expect(stringLastIndexOfCharOrNull('banana', 0x61), 5);
      expect(stringLastIndexOfCharOrNull('aaa', 0x61), 2);
    });

    test('clamps oversized starts and returns null for negative starts', () {
      expect(stringLastIndexOfCharOrNull('banana', 0x61, startIndex: 100), 5);
      expect(stringLastIndexOfCharOrNull('banana', 0x61, startIndex: 2), 1);
      expect(
        stringLastIndexOfCharOrNull('banana', 0x61, startIndex: -1),
        isNull,
      );
      expect(stringLastIndexOfCharOrNull('😀', 0xd83d), 0);
    });
  });

  group('stringLastIndexOfOrNull', () {
    test('returns the last substring match, including overlapping matches', () {
      expect(stringLastIndexOfOrNull('hello', 'z'), isNull);
      expect(stringLastIndexOfOrNull('', 'a'), isNull);
      expect(stringLastIndexOfOrNull('hello', 'h'), 0);
      expect(stringLastIndexOfOrNull('hello', 'o'), 4);
      expect(stringLastIndexOfOrNull('banana', 'ana'), 3);
      expect(stringLastIndexOfOrNull('aaa', 'aa'), 1);
    });

    test('preserves start bounds and empty-needle positions', () {
      expect(stringLastIndexOfOrNull('banana', 'a', startIndex: 2), 1);
      expect(stringLastIndexOfOrNull('banana', 'a', startIndex: -1), isNull);
      expect(stringLastIndexOfOrNull('banana', '', startIndex: 2), 3);
      expect(stringLastIndexOfOrNull('banana', '', startIndex: 100), 6);
      expect(stringLastIndexOfOrNull('', ''), isNull);
    });
  });

  test('uses the host Kotlin Char comparison only when needed', () {
    final comparisons = <(int, int)>[];
    bool compare(int left, int right) {
      comparisons.add((left, right));
      final leftString = String.fromCharCode(left);
      final rightString = String.fromCharCode(right);
      return leftString.toLowerCase() == rightString.toLowerCase();
    }

    expect(
      stringIndexOfOrNull(
        'AbA',
        0x61,
        ignoreCase: true,
        charEqualsIgnoreCase: compare,
      ),
      0,
    );
    expect(comparisons, [(0x41, 0x61)]);
    expect(
      stringLastIndexOfOrNull(
        'AbA',
        'a',
        ignoreCase: true,
        charEqualsIgnoreCase: compare,
      ),
      2,
    );
    expect(stringIndexOfOrNull('aaa', 0x61, ignoreCase: true), 0);
    expect(stringLastIndexOfOrNull('', '', ignoreCase: true), isNull);
  });
}
