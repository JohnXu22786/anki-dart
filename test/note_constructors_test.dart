/*
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived Note constructor/factory adapter tests; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnki Note constructors', () {
    test('id constructor sets the id before loading once', () {
      final collection = Object();
      final calls = <Object?>[];

      libankiNoteConstructFromId<Object>(
        collection: collection,
        id: 42,
        setId: (id) => calls.add('setId:$id'),
        load: (col) {
          calls.add('load');
          expect(col, same(collection));
        },
      );

      expect(calls, ['setId:42', 'load']);
    });

    test('id constructor stops after a setter or load failure', () {
      final collection = Object();
      final setterFailure = StateError('setter failed');
      final setterCalls = <String>[];

      expect(
        () => libankiNoteConstructFromId<Object>(
          collection: collection,
          id: 42,
          setId: (_) {
            setterCalls.add('setId');
            throw setterFailure;
          },
          load: (_) => setterCalls.add('load'),
        ),
        throwsA(same(setterFailure)),
      );
      expect(setterCalls, ['setId']);

      final loadFailure = StateError('load failed');
      final loadCalls = <String>[];
      expect(
        () => libankiNoteConstructFromId<Object>(
          collection: collection,
          id: 42,
          setId: (_) => loadCalls.add('setId'),
          load: (_) {
            loadCalls.add('load');
            throw loadFailure;
          },
        ),
        throwsA(same(loadFailure)),
      );
      expect(loadCalls, ['setId', 'load']);
    });

    test('backend-note constructor forwards the exact object once', () {
      final collection = Object();
      final backendNote = Object();
      final calls = <String>[];

      libankiNoteConstructFromBackendNote<Object, Object>(
        collection: collection,
        backendNote: backendNote,
        loadFromBackendNote: (col, note) {
          calls.add('loadFromBackendNote');
          expect(col, same(collection));
          expect(note, same(backendNote));
        },
      );

      expect(calls, ['loadFromBackendNote']);
    });

    test(
      'backend-note constructor propagates projection failure unchanged',
      () {
        final failure = StateError('projection failed');
        var calls = 0;

        expect(
          () => libankiNoteConstructFromBackendNote<Object, Object>(
            collection: Object(),
            backendNote: Object(),
            loadFromBackendNote: (_, _) {
              calls++;
              throw failure;
            },
          ),
          throwsA(same(failure)),
        );
        expect(calls, 1);
      },
    );
  });

  group('LibAnki Note.fromNotetypeId', () {
    test('creates, constructs, and returns the exact objects in order', () {
      final collection = Object();
      final backendNote = Object();
      final note = Object();
      final calls = <String>[];

      final result = libankiNoteFromNotetypeId<Object, Object, Object>(
        collection: collection,
        noteTypeId: 23,
        newNote: (noteTypeId) {
          calls.add('newNote:$noteTypeId');
          return backendNote;
        },
        constructFromBackendNote: (col, backend) {
          calls.add('construct');
          expect(col, same(collection));
          expect(backend, same(backendNote));
          return note;
        },
      );

      expect(calls, ['newNote:23', 'construct']);
      expect(result, same(note));
    });

    test('factory failures prevent construction or later work', () {
      final collection = Object();
      final newNoteFailure = StateError('newNote failed');
      final backendCalls = <String>[];

      expect(
        () => libankiNoteFromNotetypeId<Object, Object, Object>(
          collection: collection,
          noteTypeId: 23,
          newNote: (_) {
            backendCalls.add('newNote');
            throw newNoteFailure;
          },
          constructFromBackendNote: (_, _) {
            backendCalls.add('construct');
            return Object();
          },
        ),
        throwsA(same(newNoteFailure)),
      );
      expect(backendCalls, ['newNote']);

      final constructFailure = StateError('construct failed');
      final constructCalls = <String>[];
      expect(
        () => libankiNoteFromNotetypeId<Object, Object, Object>(
          collection: collection,
          noteTypeId: 23,
          newNote: (_) {
            constructCalls.add('newNote');
            return Object();
          },
          constructFromBackendNote: (_, _) {
            constructCalls.add('construct');
            throw constructFailure;
          },
        ),
        throwsA(same(constructFailure)),
      );
      expect(constructCalls, ['newNote', 'construct']);
    });
  });
}
