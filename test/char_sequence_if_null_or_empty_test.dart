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
 * Source-derived from CharSequence.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ifNullOrEmpty', () {
    test('null bypasses emptiness and returns the single fallback result', () {
      final events = <String>[];
      final fallback = _HostCharSequence();

      final result = ifNullOrEmpty<_HostCharSequence>(
        null,
        isEmpty: (_) {
          events.add('isEmpty');
          return false;
        },
        defaultValue: () {
          events.add('defaultValue');
          return fallback;
        },
      );

      expect(identical(result, fallback), isTrue);
      expect(events, ['defaultValue']);
    });

    test('empty input checks once then returns the single fallback result', () {
      final events = <String>[];
      final receiver = _HostCharSequence();
      final fallback = _HostCharSequence();

      final result = ifNullOrEmpty<_HostCharSequence>(
        receiver,
        isEmpty: (value) {
          events.add('isEmpty');
          expect(identical(value, receiver), isTrue);
          return true;
        },
        defaultValue: () {
          events.add('defaultValue');
          return fallback;
        },
      );

      expect(identical(result, fallback), isTrue);
      expect(events, ['isEmpty', 'defaultValue']);
    });

    test(
      'nonempty input is returned unchanged without evaluating fallback',
      () {
        final events = <String>[];
        final receiver = _HostCharSequence();

        final result = ifNullOrEmpty<_HostCharSequence>(
          receiver,
          isEmpty: (_) {
            events.add('isEmpty');
            return false;
          },
          defaultValue: () {
            events.add('defaultValue');
            return _HostCharSequence();
          },
        );

        expect(identical(result, receiver), isTrue);
        expect(events, ['isEmpty']);
      },
    );

    test('emptiness failure propagates and prevents fallback evaluation', () {
      final events = <String>[];
      final exception = StateError('emptiness failed');

      expect(
        () => ifNullOrEmpty<_HostCharSequence>(
          _HostCharSequence(),
          isEmpty: (_) {
            events.add('isEmpty');
            throw exception;
          },
          defaultValue: () {
            events.add('defaultValue');
            return _HostCharSequence();
          },
        ),
        throwsA(same(exception)),
      );
      expect(events, ['isEmpty']);
    });

    test('fallback failure propagates unchanged', () {
      final exception = StateError('fallback failed');

      expect(
        () => ifNullOrEmpty<_HostCharSequence>(
          null,
          isEmpty: (_) => fail('null input must bypass isEmpty'),
          defaultValue: () => throw exception,
        ),
        throwsA(same(exception)),
      );
    });
  });
}

class _HostCharSequence {
  _HostCharSequence();
}
