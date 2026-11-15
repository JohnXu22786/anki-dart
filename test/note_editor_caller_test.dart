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
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NoteEditorCaller', () {
    test('retains AnkiDroid caller names and values in declaration order', () {
      expect(NoteEditorCaller.values.map((caller) => caller.name), [
        'NO_CALLER',
        'EDIT',
        'STUDYOPTIONS',
        'DECKPICKER',
        'REVIEWER_ADD',
        'CARDBROWSER_ADD',
        'NOTEEDITOR',
        'PREVIEWER_EDIT',
        'NOTEEDITOR_INTENT_ADD',
        'IMG_OCCLUSION',
        'ADD_IMAGE',
        'INSTANT_NOTE_EDITOR',
      ]);
      expect(NoteEditorCaller.values.map((caller) => caller.value), [
        0,
        1,
        2,
        3,
        11,
        7,
        8,
        9,
        10,
        12,
        13,
        14,
      ]);
    });

    test('fromValue resolves each caller code and rejects unknown values', () {
      for (final caller in NoteEditorCaller.values) {
        expect(NoteEditorCaller.fromValue(caller.value), caller);
      }

      expect(() => NoteEditorCaller.fromValue(-1), throwsStateError);
      expect(() => NoteEditorCaller.fromValue(4), throwsStateError);
      expect(() => NoteEditorCaller.fromValue(15), throwsStateError);
    });
  });
}
