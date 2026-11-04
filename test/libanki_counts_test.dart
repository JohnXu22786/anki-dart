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
 * Source-derived from Counts.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Counts', () {
    test('defaults, mutators, and count use signed Int32 arithmetic', () {
      final counts = Counts();

      expect((counts.newCount, counts.lrn, counts.rev), (0, 0, 0));
      counts.addNew(2);
      counts.addLrn(3);
      counts.addRev(4);
      expect(counts.count(), 9);

      final overflow = Counts(2147483647, 1, 0);
      expect(overflow.count(), -2147483648);
      overflow.addNew(1);
      overflow.addLrn(-2);
      overflow.addRev(-2147483648);
      expect(
        (overflow.newCount, overflow.lrn, overflow.rev),
        (-2147483648, -1, -2147483648),
      );
      overflow.addRev(-1);
      expect(overflow.rev, 2147483647);
    });

    test(
      'equality, Kotlin list hash folding, and string representation match',
      () {
        final counts = Counts(1, 2, 3);
        final equal = Counts(1, 2, 3);
        expect(counts, equal);
        expect(
          counts.hashCode,
          30847,
        ); // listOf(new, rev, lrn), starting from 1
        expect(counts.toString(), '[1, 2, 3]');

        equal.rev = 4;
        expect(counts, isNot(equal));
        expect(counts.hashCode, 30847);
        expect(equal.toString(), '[1, 2, 4]');
        equal.rev = 2147483648;
        expect(equal.rev, -2147483648);

        expect(Counts(2147483647, -2147483648, -1).hashCode, 28799);
      },
    );

    test('Queue values preserve the upstream enum order', () {
      expect(CountsQueue.values, [
        CountsQueue.NEW,
        CountsQueue.LRN,
        CountsQueue.REV,
      ]);
    });
  });
}
