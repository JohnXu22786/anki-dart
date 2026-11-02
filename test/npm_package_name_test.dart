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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from NpmUtilsTest.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'dart:convert';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NpmPackageName', () {
    test('ports the pinned NpmUtilsTest valid and invalid cases', () {
      const valid = [
        'dashes-hyphens-minus-sign-valid',
        'example.com-periods-valid',
        'under_scores-valid',
        'example-123-numbers-valid',
        '123-starting-with-numbers-valid',
        '@scope/at-sign-for-scope-names-valid',
      ];
      const invalid = [
        '',
        'slashes@using-at-sign-for-non-scopename-uses-invalid',
        'slashes/on-nonscoped-names-invalid',
        'pipes|invalid',
        'exclamations!for!new!packages!invalid',
        'space invalid',
        'html%20entities-invalid',
        'square[brackets]-invalid',
        'commas,invalid',
        'colon:invalid',
        'semicolon;invalid',
        "single-quote'invalid",
        'double-quote"invalid',
        'tilde~invalid',
        'simple-(brackets)-invalid',
        'curly-{braces}-invalid',
        'asterisks*-invalid',
        'carets^-invalid',
        'pound-sign#-invalid',
        'plus-sign+-invalid',
        'question-mark?-invalid',
      ];

      for (final name in valid) {
        expect(_validate(name), isTrue, reason: name);
      }
      for (final name in invalid) {
        expect(_validate(name), isFalse, reason: name);
      }
    });

    test('preserves validation order and the exact first invalid log', () {
      final logger = _Logger();
      final validate = logger.validate;

      expect(validate(' \u00a0 '), isFalse);
      expect(logger.messages, [
        'Invalid package name: non-empty characters allowed',
      ]);

      logger.messages.clear();
      expect(validate(' name'), isFalse);
      expect(logger.messages, [
        'Invalid package name: non-empty characters allowed',
      ]);

      logger.messages.clear();
      expect(validate('a' * 215), isFalse);
      expect(logger.messages, [
        'Invalid package name: name string length less than 214 allowed',
      ]);

      logger.messages.clear();
      expect(validate('.name'), isFalse);
      expect(logger.messages, [
        'Invalid package name: name cannot start with a period or an underscore',
      ]);

      logger.messages.clear();
      expect(validate('Name'), isFalse);
      expect(logger.messages, [
        'Invalid package name: only small letters allowed',
      ]);

      logger.messages.clear();
      expect(validate('@scope'), isFalse);
      expect(logger.messages, ["Invalid scoped package name: must have '/'"]);

      logger.messages.clear();
      expect(validate('a/b'), isFalse);
      expect(logger.messages, [
        'Invalid package name: only URL safe characters allowed',
      ]);

      logger.messages.clear();
      expect(validate('a*b'), isFalse);
      expect(logger.messages, [
        'Invalid package name: no special characters allowed',
      ]);
    });

    test('uses UTF-16 length and Kotlin whitespace boundaries', () {
      final logger = _Logger();
      expect(logger.validate('a' * 214), isTrue);
      expect(
        validateNpmPackageName(
          'a' * 213 + '😀',
          lowercase: (value) => value,
          urlEncode: (value) => value,
          logInfo: logger.messages.add,
        ),
        isFalse,
      );
      expect(
        logger.messages.last,
        'Invalid package name: name string length less than 214 allowed',
      );
      logger.messages.clear();
      expect(
        validateNpmPackageName(
          'a' * 212 + '😀',
          lowercase: (value) => value,
          urlEncode: (value) => value,
          logInfo: logger.messages.add,
        ),
        isTrue,
      );

      logger.messages.clear();
      expect(logger.validate('\u00a0name'), isFalse);
      expect(logger.messages, [
        'Invalid package name: non-empty characters allowed',
      ]);

      logger.messages.clear();
      expect(logger.validate('\u00a0'), isFalse);
      expect(logger.messages, [
        'Invalid package name: non-empty characters allowed',
      ]);
    });

    test('recursively validates scoped parts and logs the recursive failure', () {
      final logger = _Logger();
      expect(logger.validate('@scope/name'), isTrue);
      expect(logger.messages, isEmpty);

      expect(logger.validate('@@scope/name'), isFalse);
      expect(
        logger.messages.last,
        "Invalid scoped package name: only one '@' allowed",
      );

      logger.messages.clear();
      expect(logger.validate('@scope/name/extra'), isFalse);
      expect(
        logger.messages.last,
        "Invalid scoped package name: only one '/' allowed",
      );

      logger.messages.clear();
      expect(logger.validate('@.scope/name'), isFalse);
      expect(logger.messages, [
        'Invalid package name: name cannot start with a period or an underscore',
      ]);
    });

    test('delegates locale, URL encoding, and logging boundaries', () {
      var lowerCalls = 0;
      var encoderCalls = 0;
      final logs = <String>[];
      final valid = validateNpmPackageName(
        'name',
        lowercase: (value) {
          lowerCalls++;
          return value.toLowerCase();
        },
        urlEncode: (value) {
          encoderCalls++;
          return _javaFormEncode(value);
        },
        logInfo: logs.add,
      );
      expect(valid, isTrue);
      expect(lowerCalls, 1);
      expect(encoderCalls, 1);
      expect(logs, isEmpty);

      final localeRejects = validateNpmPackageName(
        'i',
        lowercase: (_) => 'ı',
        urlEncode: _javaFormEncode,
        logInfo: logs.add,
      );
      expect(localeRejects, isFalse);
      expect(logs.single, 'Invalid package name: only small letters allowed');

      final failure = StateError('encoder failure');
      expect(
        () => validateNpmPackageName(
          'name',
          lowercase: (value) => value,
          urlEncode: (_) => throw failure,
          logInfo: logs.add,
        ),
        throwsA(same(failure)),
      );
    });
  });
}

bool _validate(String name) => _Logger().validate(name);

final class _Logger {
  final messages = <String>[];

  bool validate(String name) => validateNpmPackageName(
    name,
    lowercase: (value) => value.toLowerCase(),
    urlEncode: _javaFormEncode,
    logInfo: messages.add,
  );
}

String _javaFormEncode(String value) {
  final output = StringBuffer();
  for (final byte in utf8.encode(value)) {
    if ((byte >= 0x41 && byte <= 0x5a) ||
        (byte >= 0x61 && byte <= 0x7a) ||
        (byte >= 0x30 && byte <= 0x39) ||
        '.-*_'.codeUnits.contains(byte)) {
      output.writeCharCode(byte);
    } else if (byte == 0x20) {
      output.write('+');
    } else {
      output.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
    }
  }
  return output.toString();
}
