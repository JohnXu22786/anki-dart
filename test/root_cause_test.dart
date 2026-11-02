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
 * Source-derived from Throwable.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('getRootCause', () {
    test('returns the receiver when it has no cause', () {
      final throwable = Object();
      final reads = <Object>[];

      final result = getRootCause(
        throwable,
        cause: (current) {
          reads.add(current);
          return null;
        },
      );

      expect(result, same(throwable));
      expect(reads, [throwable]);
    });

    test('returns the deepest cause and preserves repeated source reads', () {
      final first = Object();
      final second = Object();
      final third = Object();
      final reads = <Object>[];

      final result = getRootCause(
        first,
        cause: (current) {
          reads.add(current);
          if (identical(current, first)) return second;
          if (identical(current, second)) return third;
          return null;
        },
      );

      expect(result, same(third));
      expect(reads, [first, first, first, second, second, second, third]);
    });

    test('stops after the source direct self-cycle check', () {
      final throwable = Object();
      final reads = <Object>[];

      final result = getRootCause(
        throwable,
        cause: (current) {
          reads.add(current);
          return current;
        },
      );

      expect(result, same(throwable));
      expect(reads, [throwable, throwable]);
    });

    test('propagates cause callback errors and stops later reads', () {
      final throwable = Object();
      final failure = StateError('cause access failed');
      var reads = 0;

      expect(
        () => getRootCause(
          throwable,
          cause: (_) {
            reads++;
            if (reads == 2) throw failure;
            return Object();
          },
        ),
        throwsA(same(failure)),
      );
      expect(reads, 2);
    });
  });
}
