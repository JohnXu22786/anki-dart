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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: ChangeNoteTypeViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('projectChangeNoteTypeDefaultFieldMap', () {
    test('uses exact names and the first input match with output ordinals', () {
      final mapping = projectChangeNoteTypeDefaultFieldMap(
        inputFields: [
          (name: 'Title', ordinal: 5),
          (name: 'Title', ordinal: 7),
          (name: 'title', ordinal: 6),
        ],
        outputFields: [
          (name: 'Title', ordinal: 1),
          (name: 'title', ordinal: 0),
          (name: 'TITLE', ordinal: 2),
        ],
      );

      expect(mapping, {1: 5, 0: 6, 2: 2});
    });

    test('uses identity when free and then the first unused input ordinal', () {
      final mapping = projectChangeNoteTypeDefaultFieldMap(
        inputFields: [
          (name: 'Title', ordinal: 1),
          (name: 'Body', ordinal: 0),
          (name: 'Extra', ordinal: 2),
        ],
        outputFields: [
          (name: 'Body', ordinal: 2),
          (name: 'Unknown A', ordinal: 0),
          (name: 'Unknown B', ordinal: 1),
        ],
      );

      expect(mapping, {2: 0, 0: 1, 1: 2});
    });

    test('duplicate output ordinals keep the last matched pair', () {
      final mapping = projectChangeNoteTypeDefaultFieldMap(
        inputFields: [(name: 'Alpha', ordinal: 0), (name: 'Beta', ordinal: 1)],
        outputFields: [(name: 'Beta', ordinal: 0), (name: 'Alpha', ordinal: 0)],
      );

      expect(mapping, {0: 0, 1: 1});
    });

    test(
      'preserves out-of-range keys and nulls after the source count limit',
      () {
        final mapping = projectChangeNoteTypeDefaultFieldMap(
          inputFields: [
            (name: 'Matched', ordinal: 0),
            (name: 'Other', ordinal: 1),
          ],
          outputFields: [
            (name: 'Matched', ordinal: 99),
            (name: 'Unknown A', ordinal: 40),
            (name: 'Unknown B', ordinal: 41),
          ],
        );

        expect(mapping, {99: 0, 0: 1, 1: null, 2: null});
      },
    );
  });
}
