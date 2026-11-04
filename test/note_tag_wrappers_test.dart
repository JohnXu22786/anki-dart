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
 * Source-derived cases for Note tag wrappers; the pinned tests do not directly
 * assert these methods. See ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Note tag wrappers', () {
    test(
      'hasNoteTag forwards tag then current tags once and returns result',
      () {
        final tags = ['first', 'second'];
        final calls = <(String, Iterable<String>)>[];

        final result = hasNoteTag(
          tags,
          'second',
          inList: (tag, currentTags) {
            calls.add((tag, currentTags));
            return false;
          },
        );

        expect(result, isFalse);
        expect(calls, hasLength(1));
        expect(calls.single.$1, 'second');
        expect(identical(calls.single.$2, tags), isTrue);
      },
    );

    test('addNoteTag appends exactly once without deduplicating', () {
      final tags = ['Tag'];

      addNoteTag(tags, 'Tag');

      expect(tags, ['Tag', 'Tag']);
    });

    test(
      'stringNoteTags canonifies before joining and returns join result',
      () {
        final tags = ['first', 'second'];
        final canonical = <String>{'second', 'first'};
        final calls = <String>[];
        final joined = 'host result';

        final result = stringNoteTags(
          tags,
          canonify: (currentTags) {
            calls.add('canonify');
            expect(identical(currentTags, tags), isTrue);
            return canonical;
          },
          join: (canonicalTags) {
            calls.add('join');
            expect(identical(canonicalTags, canonical), isTrue);
            return joined;
          },
        );

        expect(calls, ['canonify', 'join']);
        expect(identical(result, joined), isTrue);
      },
    );

    test('setNoteTagsFromStr replaces tags with the exact split list', () {
      final previous = ['old'];
      final split = ['parsed', 'tags'];
      final calls = <String>[];
      var noteTags = previous;

      setNoteTagsFromStr(
        'input',
        split: (value) {
          calls.add('split:$value');
          return split;
        },
        setTags: (value) {
          calls.add('set');
          noteTags = value;
        },
      );

      expect(calls, ['split:input', 'set']);
      expect(identical(noteTags, split), isTrue);
      expect(previous, ['old']);

      final splitFailure = StateError('split failed');
      expect(
        () => setNoteTagsFromStr(
          'input',
          split: (_) => throw splitFailure,
          setTags: (_) => fail('setter must not run after split fails'),
        ),
        throwsA(same(splitFailure)),
      );

      final setterFailure = StateError('setter failed');
      expect(
        () => setNoteTagsFromStr(
          'input',
          split: (_) => split,
          setTags: (_) => throw setterFailure,
        ),
        throwsA(same(setterFailure)),
      );
    });
  });
}
