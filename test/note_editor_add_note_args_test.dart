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
  group('Note Editor add-note arguments', () {
    test('contains only the source caller key and value', () {
      expect(addNoteArgs(), {'CALLER': 3});
    });

    test('returns a fresh map on every call', () {
      final first = addNoteArgs();
      final second = addNoteArgs();

      expect(identical(first, second), isFalse);
      first['CALLER'] = 99;
      expect(second, {'CALLER': 3});
    });

    test('uses the deck-picker caller code', () {
      expect(addNoteArgs()['CALLER'], NoteEditorCaller.DECKPICKER.value);
    });
  });
}
