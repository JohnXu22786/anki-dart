/*
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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Collection.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('collectionFieldNamesForNoteIds', () {
    test('forwards the same ordered note ID list to the host once', () {
      final noteIds = <NoteId>[9, 2, 9];
      var calls = 0;
      List<NoteId>? receivedIds;

      collectionFieldNamesForNoteIds(noteIds, (ids) {
        calls++;
        receivedIds = ids;
        return const [];
      });

      expect(identical(receivedIds, noteIds), isTrue);
      expect(receivedIds, [9, 2, 9]);
      expect(calls, 1);
    });

    test('returns the exact callback string list', () {
      final fieldNames = <String>['Front', 'Back'];

      final result = collectionFieldNamesForNoteIds(const <NoteId>[
        4,
      ], (_) => fieldNames);

      expect(identical(result, fieldNames), isTrue);
    });

    test('propagates the exact callback failure', () {
      final failure = StateError('field names lookup failed');

      expect(
        () => collectionFieldNamesForNoteIds(const <NoteId>[
          4,
        ], (_) => throw failure),
        throwsA(same(failure)),
      );
    });
  });
}
