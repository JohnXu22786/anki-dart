/*
 * Copyright © 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Fragment.isCompactWidth in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('fragmentIsCompactWidth', () {
    test('returns true below 600dp', () {
      expect(
        fragmentIsCompactWidth<Object>(
          fragment: Object(),
          screenWidthDp: (_) => 599,
        ),
        isTrue,
      );
    });

    test('returns false at exactly 600dp', () {
      expect(
        fragmentIsCompactWidth<Object>(
          fragment: Object(),
          screenWidthDp: (_) => 600,
        ),
        isFalse,
      );
    });

    test('returns false above 600dp', () {
      expect(
        fragmentIsCompactWidth<Object>(
          fragment: Object(),
          screenWidthDp: (_) => 601,
        ),
        isFalse,
      );
    });

    test('reads width once from the identical Fragment token', () {
      final fragment = Object();
      var reads = 0;

      final isCompact = fragmentIsCompactWidth<Object>(
        fragment: fragment,
        screenWidthDp: (receiver) {
          reads++;
          expect(identical(receiver, fragment), isTrue);
          return 500;
        },
      );

      expect(isCompact, isTrue);
      expect(reads, 1);
    });

    test('propagates host lookup failure unchanged without retry', () {
      final fragment = Object();
      final failure = StateError('requireContext failed');
      var reads = 0;

      expect(
        () => fragmentIsCompactWidth<Object>(
          fragment: fragment,
          screenWidthDp: (receiver) {
            reads++;
            expect(identical(receiver, fragment), isTrue);
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(reads, 1);
    });
  });
}
