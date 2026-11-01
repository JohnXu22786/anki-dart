/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
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
 * Source-derived from ViewPropertyAnimator.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('setViewPropertyAnimatorDuration', () {
    test(
      'converts once before setting and returns the exact animator token',
      () {
        final events = <String>[];
        final durationToken = Object();
        final animatorToken = Object();
        const milliseconds = -1234567890123456789;
        var conversionCalls = 0;
        var setterCalls = 0;

        final result = setViewPropertyAnimatorDuration(
          durationToken,
          toLongMilliseconds: (duration) {
            events.add('convert');
            conversionCalls++;
            expect(identical(duration, durationToken), isTrue);
            return milliseconds;
          },
          setDuration: (value) {
            events.add('set');
            setterCalls++;
            expect(value, milliseconds);
            return animatorToken;
          },
        );

        expect(events, ['convert', 'set']);
        expect(conversionCalls, 1);
        expect(setterCalls, 1);
        expect(identical(result, animatorToken), isTrue);
      },
    );

    test('conversion failure propagates and skips the setter', () {
      final events = <String>[];
      final failure = StateError('conversion failed');

      expect(
        () => setViewPropertyAnimatorDuration(
          Object(),
          toLongMilliseconds: (_) {
            events.add('convert');
            throw failure;
          },
          setDuration: (_) {
            events.add('set');
            return Object();
          },
        ),
        throwsA(same(failure)),
      );
      expect(events, ['convert']);
    });

    test('setter failure propagates after one conversion and setter call', () {
      final events = <String>[];
      final failure = StateError('setter failed');

      expect(
        () => setViewPropertyAnimatorDuration(
          Object(),
          toLongMilliseconds: (_) {
            events.add('convert');
            return 42;
          },
          setDuration: (milliseconds) {
            events.add('set:$milliseconds');
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(events, ['convert', 'set:42']);
    });
  });
}
