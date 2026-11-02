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
 * Source-derived from SystemTime.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('systemTimeIntTimeMS', () {
    test('reads the host millisecond clock exactly once', () {
      var reads = 0;

      final milliseconds = systemTimeIntTimeMS(
        currentTimeMillis: () {
          reads++;
          return 1_234_567_890_123;
        },
      );

      expect(milliseconds, 1_234_567_890_123);
      expect(reads, 1);
    });

    test('returns the exact host millisecond value unchanged', () {
      const value = -9_223_372_036_854_775_808;

      expect(systemTimeIntTimeMS(currentTimeMillis: () => value), value);
    });

    test('propagates host millisecond read failures unchanged', () {
      final error = Object();

      expect(
        () => systemTimeIntTimeMS(currentTimeMillis: () => throw error),
        throwsA(same(error)),
      );
    });
  });
}
