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
  group('projectChangeNoteTypeTemplateMappingUpdate', () {
    test('disabled templates keep the original map unchanged', () {
      final currentMap = {0: 2, 1: null};

      final updatedMap = projectChangeNoteTypeTemplateMappingUpdate(
        templatesEnabled: false,
        currentMap: currentMap,
        outputTemplateOrdinal: 4,
        selectedInputTemplateOrdinal: 2,
      );

      expect(updatedMap, same(currentMap));
    });

    test(
      'null selection sets the output null without clearing other nulls',
      () {
        final updatedMap = projectChangeNoteTypeTemplateMappingUpdate(
          templatesEnabled: true,
          currentMap: {0: null, 1: 1, 2: null},
          outputTemplateOrdinal: 3,
          selectedInputTemplateOrdinal: null,
        );

        expect(updatedMap, {0: null, 1: 1, 2: null, 3: null});
      },
    );

    test('selected input clears its previous mapping before assignment', () {
      final updatedMap = projectChangeNoteTypeTemplateMappingUpdate(
        templatesEnabled: true,
        currentMap: {0: 2, 1: 0},
        outputTemplateOrdinal: 2,
        selectedInputTemplateOrdinal: 0,
      );

      expect(updatedMap, {0: 2, 1: null, 2: 0});
    });

    test('multiple conflicting keys preserve the source assertion', () {
      expect(
        () => projectChangeNoteTypeTemplateMappingUpdate(
          templatesEnabled: true,
          currentMap: {0: 1, 1: 1},
          outputTemplateOrdinal: 2,
          selectedInputTemplateOrdinal: 1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('same-key replacement restores the requested mapping', () {
      final updatedMap = projectChangeNoteTypeTemplateMappingUpdate(
        templatesEnabled: true,
        currentMap: {0: 1, 1: 2},
        outputTemplateOrdinal: 0,
        selectedInputTemplateOrdinal: 1,
      );

      expect(updatedMap, {0: 1, 1: 2});
    });

    test('missing output ordinal is appended without reindexing', () {
      final updatedMap = projectChangeNoteTypeTemplateMappingUpdate(
        templatesEnabled: true,
        currentMap: {0: 0, 2: 2},
        outputTemplateOrdinal: 1,
        selectedInputTemplateOrdinal: 1,
      );

      expect(updatedMap, {0: 0, 2: 2, 1: 1});
      expect(updatedMap.keys, [0, 2, 1]);
    });
  });
}
