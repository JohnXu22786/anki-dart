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
  group('ellipsize', () {
    test('truncates at the host-provided last safe boundary', () {
      final calls = <(String, int)>[];
      final result = ellipsize(
        'Hello1',
        threshold: 5,
        lastSafeBoundary: (value, maxChars) {
          calls.add((value, maxChars));
          return 5;
        },
      );

      expect(result, 'Hello…');
      expect(calls, [('Hello1', 5)]);
    });

    test('returns equal or shorter text unchanged without a host call', () {
      var calls = 0;
      int boundary(String value, int maxChars) {
        calls++;
        return maxChars;
      }

      expect(
        ellipsize('Hello', threshold: 5, lastSafeBoundary: boundary),
        'Hello',
      );
      expect(ellipsize('Hi', threshold: 5, lastSafeBoundary: boundary), 'Hi');
      expect(ellipsize('', threshold: 1, lastSafeBoundary: boundary), '');
      expect(calls, 0);
    });

    test('rejects nonpositive thresholds before querying the host', () {
      var calls = 0;
      int boundary(String value, int maxChars) {
        calls++;
        return maxChars;
      }

      expect(
        () => ellipsize('hello', threshold: 0, lastSafeBoundary: boundary),
        throwsArgumentError,
      );
      expect(
        () => ellipsize('hello', threshold: -1, lastSafeBoundary: boundary),
        throwsArgumentError,
      );
      expect(calls, 0);
    });

    test('preserves the BreakIterator boundary for a flag grapheme', () {
      const value = 'Brazil🇧🇷';
      int boundary(String text, int maxChars) {
        expect(text, value);
        if (maxChars < 10) return 6;
        return 10;
      }

      for (final threshold in [6, 7, 8, 9]) {
        expect(
          ellipsize(value, threshold: threshold, lastSafeBoundary: boundary),
          'Brazil…',
        );
      }
      expect(
        ellipsize(value, threshold: 10, lastSafeBoundary: boundary),
        value,
      );
    });

    test('propagates BreakIterator failures unchanged', () {
      final failure = StateError('BreakIterator failed');
      expect(
        () => ellipsize(
          'Hello1',
          threshold: 5,
          lastSafeBoundary: (_, _) => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });
}
