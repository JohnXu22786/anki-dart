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
 * Source-derived from BundleUtils.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BundleUtils scalar accessors', () {
    // These four cases directly port BundleUtilsTest.kt assertions.
    test('pinned: nullable Long missing returns null without a typed read', () {
      final bundle = _FakeBundle(present: false);

      expect(bundle.getLongOrNull('KEY'), isNull);
      expect(bundle.events, ['contains:KEY']);
    });

    test('pinned: nullable Long present returns its value', () {
      final bundle = _FakeBundle(present: true, longValue: 42);

      expect(bundle.getLongOrNull('KEY'), 42);
      expect(bundle.events, ['contains:KEY', 'long:KEY']);
    });

    test('pinned: requireLong rejects missing and returns present value', () {
      final missing = _FakeBundle(present: false);
      expect(() => missing.requireLong('KEY'), throwsA(isA<StateError>()));
      expect(missing.events, ['contains:KEY']);

      final present = _FakeBundle(present: true, longValue: 42);
      expect(present.requireLong('KEY'), 42);
      expect(present.events, ['contains:KEY', 'long:KEY']);
    });

    test(
      'pinned: requireBoolean rejects missing and returns present value',
      () {
        final missing = _FakeBundle(present: false);
        expect(() => missing.requireBoolean('KEY'), throwsA(isA<StateError>()));
        expect(missing.events, ['contains:KEY']);

        final present = _FakeBundle(present: true, booleanValue: true);
        expect(present.requireBoolean('KEY'), isTrue);
        expect(present.events, ['contains:KEY', 'boolean:KEY']);
      },
    );

    // The remaining cases are source-derived coverage for the scalar methods.
    test('nullable accessors check once and skip typed reads when absent', () {
      final bundle = _FakeBundle(present: false);

      expect(bundle.getLongOrNull('long'), isNull);
      expect(bundle.getIntOrNull('int'), isNull);
      expect(bundle.events, ['contains:long', 'contains:int']);
    });

    test(
      'nullable accessors read present values once after presence check',
      () {
        final bundle = _FakeBundle(present: true, longValue: 123, intValue: -7);

        expect(bundle.getLongOrNull('long'), 123);
        expect(bundle.getIntOrNull('int'), -7);
        expect(bundle.events, [
          'contains:long',
          'long:long',
          'contains:int',
          'int:int',
        ]);
      },
    );

    test(
      'required accessors preserve exact missing-key StateError messages',
      () {
        final long = _FakeBundle(present: false);
        expect(
          () => long.requireLong('absent'),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              "key: 'absent' not found",
            ),
          ),
        );
        expect(long.events, ['contains:absent']);

        final boolean = _FakeBundle(present: false);
        expect(
          () => boolean.requireBoolean('absent'),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              "key: 'absent' not found",
            ),
          ),
        );
        expect(boolean.events, ['contains:absent']);
      },
    );

    test(
      'requireString preserves value and reports null with source message',
      () {
        const value = 'value';
        final present = _FakeBundle(present: true, stringValue: value);

        expect(identical(present.requireString('text'), value), isTrue);
        expect(present.events, ['contains:text', 'string:text']);

        final nullValue = _FakeBundle(present: true, stringValue: null);
        expect(
          () => nullValue.requireString('text'),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              "String in 'text' was null",
            ),
          ),
        );
        expect(nullValue.events, ['contains:text', 'string:text']);

        final missing = _FakeBundle(present: false);
        expect(
          () => missing.requireString('absent'),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              "key: 'absent' not found",
            ),
          ),
        );
        expect(missing.events, ['contains:absent']);
      },
    );

    test('host callback errors propagate unchanged', () {
      final containsFailure = StateError('contains failed');
      final contains = _FakeBundle(containsKey: (_) => throw containsFailure);
      expect(
        () => contains.getIntOrNull('key'),
        throwsA(same(containsFailure)),
      );
      expect(contains.events, ['contains:key']);

      final longFailure = ArgumentError('long failed');
      final long = _FakeBundle(
        present: true,
        getLong: (_) => throw longFailure,
      );
      expect(() => long.requireLong('key'), throwsA(same(longFailure)));
      expect(long.events, ['contains:key', 'long:key']);

      final intFailure = StateError('int failed');
      final integer = _FakeBundle(
        present: true,
        getInt: (_) => throw intFailure,
      );
      expect(() => integer.getIntOrNull('key'), throwsA(same(intFailure)));
      expect(integer.events, ['contains:key', 'int:key']);

      final stringFailure = ArgumentError('string failed');
      final string = _FakeBundle(
        present: true,
        getString: (_) => throw stringFailure,
      );
      expect(() => string.requireString('key'), throwsA(same(stringFailure)));
      expect(string.events, ['contains:key', 'string:key']);

      final booleanFailure = StateError('boolean failed');
      final boolean = _FakeBundle(
        present: true,
        getBoolean: (_) => throw booleanFailure,
      );
      expect(
        () => boolean.requireBoolean('key'),
        throwsA(same(booleanFailure)),
      );
      expect(boolean.events, ['contains:key', 'boolean:key']);
    });
  });
}

final class _FakeBundle implements BundleUtilsAccess {
  _FakeBundle({
    bool present = false,
    this.longValue = 0,
    this.intValue = 0,
    this.stringValue,
    this.booleanValue = false,
    bool Function(String key)? containsKey,
    int Function(String key)? getLong,
    int Function(String key)? getInt,
    String? Function(String key)? getString,
    bool Function(String key)? getBoolean,
  }) : _containsKey = containsKey ?? ((_) => present),
       _getLong = getLong,
       _getInt = getInt,
       _getString = getString,
       _getBoolean = getBoolean;

  final int longValue;
  final int intValue;
  final String? stringValue;
  final bool booleanValue;
  final List<String> events = [];
  final bool Function(String key) _containsKey;
  final int Function(String key)? _getLong;
  final int Function(String key)? _getInt;
  final String? Function(String key)? _getString;
  final bool Function(String key)? _getBoolean;

  @override
  bool containsKey(String key) {
    events.add('contains:$key');
    return _containsKey(key);
  }

  @override
  int getLong(String key) {
    events.add('long:$key');
    return _getLong?.call(key) ?? longValue;
  }

  @override
  int getInt(String key) {
    events.add('int:$key');
    return _getInt?.call(key) ?? intValue;
  }

  @override
  String? getString(String key) {
    events.add('string:$key');
    return _getString?.call(key) ?? stringValue;
  }

  @override
  bool getBoolean(String key) {
    events.add('boolean:$key');
    return _getBoolean?.call(key) ?? booleanValue;
  }
}
