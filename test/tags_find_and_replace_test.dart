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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived adapter cases for Tags.findAndReplace(); see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('tagsFindAndReplace', () {
    test('forwards arguments once and returns the exact backend result', () {
      final noteIds = <int>[7, 11];
      final result = Object();
      var calls = 0;

      final actual = tagsFindAndReplace(
        noteIds: noteIds,
        search: 'old tag',
        replacement: 'new tag',
        regex: true,
        matchCase: false,
        findAndReplaceTag: (ids, search, replacement, regex, matchCase) {
          calls++;
          expect(ids, same(noteIds));
          expect(ids, [7, 11]);
          expect(search, 'old tag');
          expect(replacement, 'new tag');
          expect(regex, isTrue);
          expect(matchCase, isFalse);
          return result;
        },
      );

      expect(calls, 1);
      expect(actual, same(result));
    });

    test('propagates the exact backend exception', () {
      final failure = StateError('backend failed');

      expect(
        () => tagsFindAndReplace(
          noteIds: <int>[],
          search: 'old',
          replacement: 'new',
          regex: false,
          matchCase: true,
          findAndReplaceTag: (_, _, _, _, _) => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });
}
