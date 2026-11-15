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
  group('projectChangeNoteTypeDiscardedTemplates', () {
    test('filters mapped indices and collapses duplicate map values', () {
      expect(
        projectChangeNoteTypeDiscardedTemplates(
          templateChangeMap: {0: 1, 1: 1},
          inputTemplateNames: ['Card 1', 'Card 2', 'Card 3'],
        ),
        ['Card 1', 'Card 3'],
      );
    });

    test('preserves source order and duplicate template names', () {
      expect(
        projectChangeNoteTypeDiscardedTemplates(
          templateChangeMap: {0: 0},
          inputTemplateNames: ['Card 2', 'Card 1', 'Card 2'],
        ),
        ['Card 1', 'Card 2'],
      );
    });

    test('null and out-of-range values do not map any list index', () {
      expect(
        projectChangeNoteTypeDiscardedTemplates(
          templateChangeMap: {0: null, 1: 8},
          inputTemplateNames: ['Card 1', 'Card 2', 'Card 3'],
        ),
        ['Card 1', 'Card 2', 'Card 3'],
      );
    });

    test('empty input names return an empty list', () {
      expect(
        projectChangeNoteTypeDiscardedTemplates(
          templateChangeMap: {0: null, 1: 10},
          inputTemplateNames: [],
        ),
        isEmpty,
      );
    });

    test('empty map leaves every input template discarded', () {
      expect(
        projectChangeNoteTypeDiscardedTemplates(
          templateChangeMap: {},
          inputTemplateNames: ['Card 1', 'Card 2'],
        ),
        ['Card 1', 'Card 2'],
      );
    });
  });
}
