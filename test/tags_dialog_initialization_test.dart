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
 * Source-derived from TagsDialogViewModelTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Tags Dialog initialization projection', () {
    test(
      'unions per-note selections in order and retains duplicate progress positions',
      () {
        final projection = projectTagsDialogInitialization(
          collectionTags: ['b', 'a', 'c', 'd', 'e'],
          selectedNoteTags: [
            ['a', 'b'],
            ['a', 'b'],
            ['b', 'd'],
          ],
          checkedTags: ['d', 'extra'],
        );

        expect(projection.tags.copyOfAllTagList(), [
          'b',
          'a',
          'c',
          'd',
          'e',
          'extra',
        ]);
        expect(projection.tags.copyOfCheckedTagList(), ['b', 'd', 'extra']);
        expect(projection.tags.copyOfIndeterminateTagList(), ['a']);
        expect(projection.progress, [
          const TagsDialogInitProgress.processing(),
          const TagsDialogInitProgress.fetchingNoteTags(1, 3),
          const TagsDialogInitProgress.fetchingNoteTags(2, 3),
          const TagsDialogInitProgress.fetchingNoteTags(3, 3),
          const TagsDialogInitProgress.processing(),
          const TagsDialogInitProgress.finished(),
        ]);
      },
    );

    test(
      'custom study uses selected-note union and extras as unchecked tags',
      () {
        final projection = projectTagsDialogInitialization(
          collectionTags: ['b', 'a', 'c', 'd'],
          selectedNoteTags: [
            ['a', 'b'],
            ['b', 'd'],
          ],
          checkedTags: ['extra'],
          isCustomStudying: true,
        );

        expect(projection.tags.copyOfAllTagList(), ['b', 'a', 'd', 'extra']);
        expect(projection.tags.copyOfCheckedTagList(), isEmpty);
        expect(projection.tags.copyOfIndeterminateTagList(), isEmpty);
        for (final tag in projection.tags) {
          expect(projection.tags.isChecked(tag), isFalse);
          expect(projection.tags.isIndeterminate(tag), isFalse);
        }
      },
    );

    test(
      'empty and case-mismatched inputs retain source progress and set semantics',
      () {
        final empty = projectTagsDialogInitialization(
          collectionTags: ['b', 'a'],
          selectedNoteTags: const [],
        );
        expect(empty.tags.copyOfAllTagList(), ['b', 'a']);
        expect(empty.tags.copyOfCheckedTagList(), isEmpty);
        expect(empty.tags.copyOfIndeterminateTagList(), isEmpty);
        expect(empty.progress, [
          const TagsDialogInitProgress.processing(),
          const TagsDialogInitProgress.processing(),
          const TagsDialogInitProgress.finished(),
        ]);

        final caseMismatch = projectTagsDialogInitialization(
          collectionTags: ['Foo'],
          selectedNoteTags: [
            ['foo'],
          ],
          checkedTags: ['FOO'],
        );
        expect(caseMismatch.tags.copyOfAllTagList(), ['Foo']);
        expect(caseMismatch.tags.copyOfCheckedTagList(), isEmpty);
        expect(caseMismatch.tags.copyOfIndeterminateTagList(), ['FOO']);
      },
    );
  });
}
