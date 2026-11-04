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
 * Source-derived cases for Note.removeTag(); the pinned tests do not directly
 * assert this method. See ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('removeNoteTag', () {
    test('removes all matching case variants and duplicates in order', () {
      final tags = ['Keep', 'TaG', 'stay', 'tag', 'TAG', 'Also'];

      removeNoteTag(
        tags,
        'tAg',
        equalsIgnoreCase: (candidate, requested) =>
            candidate.toLowerCase() == requested.toLowerCase(),
      );

      expect(tags, ['Keep', 'stay', 'Also']);
    });

    test(
      'compares tags in order with requested tag second before any removal',
      () {
        final tags = ['first', 'Tag', 'last'];
        final calls = <(String, String)>[];

        removeNoteTag(
          tags,
          'tag',
          equalsIgnoreCase: (candidate, requested) {
            calls.add((candidate, requested));
            expect(tags, ['first', 'Tag', 'last']);
            return candidate.toLowerCase() == requested.toLowerCase();
          },
        );

        expect(calls, [('first', 'tag'), ('Tag', 'tag'), ('last', 'tag')]);
        expect(tags, ['first', 'last']);
      },
    );

    test('comparison failure propagates before mutating tags', () {
      final tags = ['keep', 'Tag', 'other', 'tag'];
      final before = List<String>.of(tags);
      final failure = StateError('comparison failed');

      expect(
        () => removeNoteTag(
          tags,
          'tag',
          equalsIgnoreCase: (candidate, requested) {
            if (candidate == 'other') throw failure;
            return candidate.toLowerCase() == requested.toLowerCase();
          },
        ),
        throwsA(same(failure)),
      );

      expect(tags, before);
    });
  });
}
