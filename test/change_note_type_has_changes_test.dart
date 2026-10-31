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
  group('projectChangeNoteTypeHasChanges', () {
    test('is false for the original type and default maps', () {
      expect(
        projectChangeNoteTypeHasChanges(
          inputNoteTypeId: 1,
          outputNoteTypeId: 1,
          currentFieldMap: {0: 0, 1: null},
          defaultFieldMap: {0: 0, 1: null},
          currentTemplateMap: {0: 0, 1: null},
          defaultTemplateMap: {0: 0, 1: null},
        ),
        isFalse,
      );
    });

    test('a changed output note-type ID makes the result true', () {
      expect(
        projectChangeNoteTypeHasChanges(
          inputNoteTypeId: 1,
          outputNoteTypeId: 2,
          currentFieldMap: {0: 1},
          defaultFieldMap: {},
          currentTemplateMap: {0: null},
          defaultTemplateMap: {},
        ),
        isTrue,
      );
    });

    test('a field-map-only difference makes the result true', () {
      expect(
        projectChangeNoteTypeHasChanges(
          inputNoteTypeId: 1,
          outputNoteTypeId: 1,
          currentFieldMap: {0: 1},
          defaultFieldMap: {0: 0},
          currentTemplateMap: {0: 0},
          defaultTemplateMap: {0: 0},
        ),
        isTrue,
      );
    });

    test('a template-map-only difference makes the result true', () {
      expect(
        projectChangeNoteTypeHasChanges(
          inputNoteTypeId: 1,
          outputNoteTypeId: 1,
          currentFieldMap: {0: 0},
          defaultFieldMap: {0: 0},
          currentTemplateMap: {0: 1},
          defaultTemplateMap: {0: 0},
        ),
        isTrue,
      );
    });

    test('map equality ignores insertion order and includes null values', () {
      expect(
        projectChangeNoteTypeHasChanges(
          inputNoteTypeId: 1,
          outputNoteTypeId: 1,
          currentFieldMap: {1: null, 0: 0},
          defaultFieldMap: {0: 0, 1: null},
          currentTemplateMap: {1: 0, 0: null},
          defaultTemplateMap: {0: null, 1: 0},
        ),
        isFalse,
      );
    });

    test('a missing key differs from a present null-valued key', () {
      expect(
        projectChangeNoteTypeHasChanges(
          inputNoteTypeId: 1,
          outputNoteTypeId: 1,
          currentFieldMap: {},
          defaultFieldMap: {0: null},
          currentTemplateMap: {0: null},
          defaultTemplateMap: {0: null},
        ),
        isTrue,
      );
      expect(
        projectChangeNoteTypeHasChanges(
          inputNoteTypeId: 1,
          outputNoteTypeId: 1,
          currentFieldMap: {0: null},
          defaultFieldMap: {0: null},
          currentTemplateMap: {},
          defaultTemplateMap: {0: null},
        ),
        isTrue,
      );
    });
  });
}
