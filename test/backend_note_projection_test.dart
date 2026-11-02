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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from NoteUtil.kt and Note.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BackendNoteProjection', () {
    test('maps note fields and snapshots ordered tags and fields', () {
      final tags = ['first-tag', 'second-tag'];
      final fields = ['front', 'back'];
      final projection = BackendNoteProjection.fromNote(
        id: 123,
        guId: 'guid-123',
        noteTypeId: 456,
        mod: 789,
        usn: 12,
        tags: tags,
        fields: fields,
      );

      expect(projection.id, 123);
      expect(projection.guid, 'guid-123');
      expect(projection.notetypeId, 456);
      expect(projection.mtimeSecs, 789);
      expect(projection.usn, 12);
      expect(projection.tags, ['first-tag', 'second-tag']);
      expect(projection.fields, ['front', 'back']);
      expect(projection.tags, isNot(same(tags)));
      expect(projection.fields, isNot(same(fields)));

      tags.add('later-tag');
      fields[0] = 'changed';
      expect(projection.tags, ['first-tag', 'second-tag']);
      expect(projection.fields, ['front', 'back']);
    });

    test('preserves the source non-null assertion for a missing guid', () {
      expect(
        () => BackendNoteProjection.fromNote(
          id: 123,
          guId: null,
          noteTypeId: 456,
          mod: 789,
          usn: 12,
          tags: const [],
          fields: const [],
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
