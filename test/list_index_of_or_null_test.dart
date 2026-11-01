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
 * Source-derived from ListTest.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('List.indexOfOrNull(predicate)', () {
    test(
      'returns the first match and stops after visiting values in order',
      () {
        final values = [1, 2, 3, 4];
        final visited = <int>[];

        final index = values.indexOfOrNull((value) {
          visited.add(value);
          return value.isEven;
        });

        expect(index, 1);
        expect(visited, [1, 2]);
      },
    );

    test('returns null when no value matches or the list is empty', () {
      expect([1, 3, 5].indexOfOrNull((value) => value.isEven), isNull);
      expect(
        <int>[].indexOfOrNull(
          (_) => fail('empty list must not call predicate'),
        ),
        isNull,
      );
    });

    test('propagates the predicate failure unchanged and stops traversal', () {
      final failure = StateError('predicate failed');
      final visited = <int>[];

      expect(
        () => [1, 2, 3].indexOfOrNull((value) {
          visited.add(value);
          if (value == 2) throw failure;
          return false;
        }),
        throwsA(same(failure)),
      );
      expect(visited, [1, 2]);
    });
  });
}
