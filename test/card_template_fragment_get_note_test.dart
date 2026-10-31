/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateFragmentGetNote', () {
    test('sentinel note ID returns null without collection lookup', () {
      final events = <String>[];
      final result = cardTemplateFragmentGetNote<Object>(
        readEditorNoteId: () {
          events.add('read note ID');
          return -1;
        },
        getNote: (noteId) {
          events.add('get note:$noteId');
          return Object();
        },
      );

      expect(result, isNull);
      expect(events, ['read note ID']);
    });

    test(
      'looks up the exact non-sentinel ID once and returns note unchanged',
      () {
        final events = <String>[];
        final note = Object();
        var reads = 0;
        var lookups = 0;

        final result = cardTemplateFragmentGetNote<Object>(
          readEditorNoteId: () {
            reads++;
            events.add('read note ID');
            return 0x123456789;
          },
          getNote: (noteId) {
            lookups++;
            events.add('get note:$noteId');
            return note;
          },
        );

        expect(result, same(note));
        expect(reads, 1);
        expect(lookups, 1);
        expect(events, ['read note ID', 'get note:4886718345']);
      },
    );

    test('returns a null collection result unchanged', () {
      final events = <String>[];
      final result = cardTemplateFragmentGetNote<Object>(
        readEditorNoteId: () {
          events.add('read note ID');
          return 0;
        },
        getNote: (noteId) {
          events.add('get note:$noteId');
          return null;
        },
      );

      expect(result, isNull);
      expect(events, ['read note ID', 'get note:0']);
    });

    test('propagates argument and collection failures unchanged', () {
      final readFailure = StateError('read arguments');
      final readEvents = <String>[];
      expect(
        () => cardTemplateFragmentGetNote<Object>(
          readEditorNoteId: () {
            readEvents.add('read note ID');
            throw readFailure;
          },
          getNote: (noteId) {
            readEvents.add('get note:$noteId');
            return Object();
          },
        ),
        throwsA(same(readFailure)),
      );
      expect(readEvents, ['read note ID']);

      final lookupFailure = StateError('collection lookup');
      final lookupEvents = <String>[];
      expect(
        () => cardTemplateFragmentGetNote<Object>(
          readEditorNoteId: () {
            lookupEvents.add('read note ID');
            return 12;
          },
          getNote: (noteId) {
            lookupEvents.add('get note:$noteId');
            throw lookupFailure;
          },
        ),
        throwsA(same(lookupFailure)),
      );
      expect(lookupEvents, ['read note ID', 'get note:12']);
    });
  });
}
