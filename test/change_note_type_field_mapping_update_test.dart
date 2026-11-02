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
  group('projectChangeNoteTypeFieldMappingUpdate', () {
    test('null selection clears only the requested output mapping', () {
      final currentMap = {0: 0, 1: 1, 2: 2};

      final updatedMap = projectChangeNoteTypeFieldMappingUpdate(
        currentMap: currentMap,
        outputFieldOrdinal: 1,
        selectedInputFieldOrdinal: null,
      );

      expect(updatedMap, {0: 0, 1: null, 2: 2});
      expect(currentMap, {0: 0, 1: 1, 2: 2});
    });

    test('repeated input ordinals remain mapped to multiple outputs', () {
      final updatedMap = projectChangeNoteTypeFieldMappingUpdate(
        currentMap: {0: 0, 1: 1},
        outputFieldOrdinal: 1,
        selectedInputFieldOrdinal: 0,
      );

      expect(updatedMap, {0: 0, 1: 0});
    });

    test('missing output key is added without changing other entries', () {
      final updatedMap = projectChangeNoteTypeFieldMappingUpdate(
        currentMap: {0: 2, 2: null},
        outputFieldOrdinal: 3,
        selectedInputFieldOrdinal: 7,
      );

      expect(updatedMap, {0: 2, 2: null, 3: 7});
      expect(updatedMap.keys, [0, 2, 3]);
    });

    test('negative ordinals pass through unchanged', () {
      final updatedMap = projectChangeNoteTypeFieldMappingUpdate(
        currentMap: {-1: 12},
        outputFieldOrdinal: -4,
        selectedInputFieldOrdinal: -9,
      );

      expect(updatedMap, {-1: 12, -4: -9});
    });
  });
}
