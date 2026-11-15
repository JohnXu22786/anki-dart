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
 * Source-derived NoteService mark-toggle branch/effect cases.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('NoteService mark toggle plan', () {
    test('removes the marked tag before requesting undoable update', () {
      final effects = planNoteServiceToggleMark(isMarked: true);

      expect(effects, hasLength(2));
      final tagEffect = effects[0] as NoteServiceUpdateMarkTagEffect;
      expect(tagEffect.tag, 'marked');
      expect(tagEffect.action, NoteServiceMarkTagAction.remove);
      expect(effects[1], isA<NoteServicePersistNoteUndoablyEffect>());
    });

    test('adds the marked tag before requesting undoable update', () {
      final effects = planNoteServiceToggleMark(isMarked: false);

      expect(effects, hasLength(2));
      final tagEffect = effects[0] as NoteServiceUpdateMarkTagEffect;
      expect(tagEffect.tag, 'marked');
      expect(tagEffect.action, NoteServiceMarkTagAction.add);
      expect(effects[1], isA<NoteServicePersistNoteUndoablyEffect>());
    });
  });
}
