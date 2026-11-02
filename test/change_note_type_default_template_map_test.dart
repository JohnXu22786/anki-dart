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
  group('projectChangeNoteTypeDefaultTemplateMap', () {
    test('maps equal template counts by ordinal', () {
      expect(
        projectChangeNoteTypeDefaultTemplateMap(
          inputTemplateCount: 2,
          outputTemplateCount: 2,
        ),
        {0: 0, 1: 1},
      );
    });

    test('leaves unused input templates unmapped', () {
      expect(
        projectChangeNoteTypeDefaultTemplateMap(
          inputTemplateCount: 3,
          outputTemplateCount: 1,
        ),
        {0: 0},
      );
    });

    test('maps extra output templates to null', () {
      expect(
        projectChangeNoteTypeDefaultTemplateMap(
          inputTemplateCount: 1,
          outputTemplateCount: 3,
        ),
        {0: 0, 1: null, 2: null},
      );
    });

    test('empty input maps every output to null', () {
      expect(
        projectChangeNoteTypeDefaultTemplateMap(
          inputTemplateCount: 0,
          outputTemplateCount: 2,
        ),
        {0: null, 1: null},
      );
    });

    test('zero output templates produce an empty map', () {
      expect(
        projectChangeNoteTypeDefaultTemplateMap(
          inputTemplateCount: 2,
          outputTemplateCount: 0,
        ),
        isEmpty,
      );
    });

    test('inserts output ordinals in ascending source order', () {
      final mapping = projectChangeNoteTypeDefaultTemplateMap(
        inputTemplateCount: 4,
        outputTemplateCount: 4,
      );

      expect(mapping.keys, [0, 1, 2, 3]);
    });
  });
}
