/*
 * Copyright (c) 2009 Daniel Svärd <daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2009 Daniel Svärd
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CardNoteCache', () {
    test('loads once with the exact note ID and reuses the same note', () {
      final cache = CardNoteCache<Object>();
      final note = Object();
      final calls = <int>[];

      final first = cache.note(
        noteId: 456,
        getNote: (noteId) {
          calls.add(noteId);
          return note;
        },
      );
      final second = cache.note(
        noteId: 789,
        getNote: (noteId) {
          calls.add(noteId);
          return Object();
        },
      );

      expect(first, same(note));
      expect(second, same(note));
      expect(calls, [456]);
    });

    test('reload fetches and caches one replacement note', () {
      final original = Object();
      final replacement = Object();
      final cache = CardNoteCache<Object>(cachedNote: original);
      var calls = 0;

      final reloaded = cache.note(
        noteId: 123,
        reload: true,
        getNote: (noteId) {
          calls++;
          expect(noteId, 123);
          return replacement;
        },
      );
      final reused = cache.note(noteId: 123, getNote: (_) => Object());

      expect(reloaded, same(replacement));
      expect(reused, same(replacement));
      expect(calls, 1);
    });

    test(
      'failed reload propagates the same error and preserves the old note',
      () {
        final original = Object();
        final failure = StateError('lookup failed');
        final cache = CardNoteCache<Object>(cachedNote: original);

        expect(
          () => cache.note(
            noteId: 123,
            reload: true,
            getNote: (_) => throw failure,
          ),
          throwsA(same(failure)),
        );
        expect(
          cache.note(noteId: 123, getNote: (_) => Object()),
          same(original),
        );
      },
    );

    test('noteType resolves through note cache and returns host notetype', () {
      final noteType = Object();
      final note = _HostNote(noteType);
      final cache = CardNoteCache<_HostNote>();
      final calls = <String>[];

      final result = cache.noteType<Object>(
        noteId: 456,
        getNote: (noteId) {
          calls.add('note:$noteId');
          return note;
        },
        getNoteType: (resolvedNote) {
          calls.add('notetype');
          expect(resolvedNote, same(note));
          return resolvedNote.notetype;
        },
      );

      expect(result, same(noteType));
      expect(calls, ['note:456', 'notetype']);
      expect(note.noteTypeReads, 1);
    });
  });
}

final class _HostNote {
  _HostNote(this._noteType);

  int noteTypeReads = 0;

  Object get notetype {
    noteTypeReads++;
    return _noteType;
  }

  final Object _noteType;
}
