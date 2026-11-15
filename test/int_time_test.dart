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
 * Source-derived from Time.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('intTime', () {
    test('truncates signed milliseconds toward zero', () {
      final cases = <(int, int)>[
        (1234, 1),
        (-1, 0),
        (-999, 0),
        (-1001, -1),
        (-2345, -2),
      ];

      for (final (milliseconds, expected) in cases) {
        expect(
          intTime(Object(), intTimeMS: (_) => milliseconds),
          expected,
          reason: '$milliseconds milliseconds',
        );
      }
    });

    test('reads the host millisecond clock exactly once', () {
      var reads = 0;

      final seconds = intTime(
        Object(),
        intTimeMS: (_) {
          reads++;
          return 2345;
        },
      );

      expect(seconds, 2);
      expect(reads, 1);
    });

    test('propagates host millisecond read failures unchanged', () {
      final error = Object();

      expect(
        () => intTime(Object(), intTimeMS: (_) => throw error),
        throwsA(same(error)),
      );
    });
  });
}
