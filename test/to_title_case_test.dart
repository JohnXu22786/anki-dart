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
  group('toTitleCase', () {
    String? transform(String? value) => toTitleCase(
      value,
      isBlank: (text) => text.trim().isEmpty,
      uppercase: (text) => text.toUpperCase(),
      lowercase: (text) => text.toLowerCase(),
    );

    test('returns null and blank input unchanged', () {
      expect(transform(null), isNull);
      expect(transform(''), '');
      expect(transform('   '), '   ');
    });

    test('uppercases the first part and lowercases the remainder', () {
      expect(transform('a'), 'A');
      expect(transform('A'), 'A');
      expect(transform('aB'), 'Ab');
      expect(transform('HELLO'), 'Hello');
      expect(transform('HELLO WORLD'), 'Hello world');
      expect(transform('hello world'), 'Hello world');
    });

    test('calls blank and locale mappings in source order', () {
      final calls = <String>[];

      final result = toTitleCase(
        'aB',
        isBlank: (value) {
          calls.add('blank:$value');
          return false;
        },
        uppercase: (value) {
          calls.add('upper:$value');
          return 'UP($value)';
        },
        lowercase: (value) {
          calls.add('lower:$value');
          return 'low($value)';
        },
      );

      expect(result, 'UP(a)low(B)');
      expect(calls, ['blank:aB', 'upper:a', 'lower:B']);
    });

    test('null and blank early returns suppress later callbacks', () {
      final calls = <String>[];
      final isBlank = (String value) {
        calls.add('blank:$value');
        return true;
      };
      final uppercase = (String value) {
        calls.add('upper:$value');
        return value;
      };
      final lowercase = (String value) {
        calls.add('lower:$value');
        return value;
      };

      expect(
        toTitleCase(
          null,
          isBlank: isBlank,
          uppercase: uppercase,
          lowercase: lowercase,
        ),
        isNull,
      );
      expect(calls, isEmpty);
      expect(
        toTitleCase(
          ' \t',
          isBlank: isBlank,
          uppercase: uppercase,
          lowercase: lowercase,
        ),
        ' \t',
      );
      expect(calls, ['blank: \t']);
    });

    test('uses the source UTF-16 first-unit and remainder boundaries', () {
      final arguments = <String>[];
      toTitleCase(
        '😀x',
        isBlank: (_) => false,
        uppercase: (value) {
          arguments.add(value);
          return value;
        },
        lowercase: (value) {
          arguments.add(value);
          return value;
        },
      );

      expect(arguments[0].codeUnits, [0xd83d]);
      expect(arguments[1].codeUnits, [0xde00, 0x78]);
    });

    test('propagates failures and stops later callbacks', () {
      final failure = StateError('locale lookup failed');
      var lowercaseCalled = false;

      expect(
        () => toTitleCase(
          'abc',
          isBlank: (_) => false,
          uppercase: (_) => throw failure,
          lowercase: (_) {
            lowercaseCalled = true;
            return '';
          },
        ),
        throwsA(same(failure)),
      );
      expect(lowercaseCalled, isFalse);
    });
  });
}
