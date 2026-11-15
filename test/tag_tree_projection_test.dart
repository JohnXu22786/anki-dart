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
 * Source-derived from TagName.kt and ManageTagsViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('TagName', () {
    test(
      'rejects blank input and replaces spaces without changing delimiters',
      () {
        expect(TagName.build(' \t\n\u00a0'), isNull);
        expect(
          TagName.build('science fiction::deep space')?.value,
          'science_fiction::deep_space',
        );
      },
    );

    test(
      'ancestors are cumulative prefixes split on literal double colons',
      () {
        expect(TagName.build('a::b::c')!.ancestors, ['a', 'a::b']);
        expect(TagName.build('a:b:c')!.ancestors, isEmpty);
        expect(TagName.build('a::::c')!.ancestors, ['a', 'a::']);
      },
    );

    test('uses value equality like the Kotlin value class', () {
      final first = TagName.build('a::b')!;
      final second = TagName.build('a::b')!;

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });

  group('tag tree projections', () {
    test(
      'flattens recursively in preorder with composed paths and source levels',
      () {
        final rows = flattenTagTree(
          TagTreeNode(
            name: '',
            level: 0,
            children: [
              TagTreeNode(
                name: 'science fiction',
                level: 1,
                collapsed: true,
                children: [
                  TagTreeNode(name: 'biology', level: 2),
                  TagTreeNode(
                    name: 'chemistry',
                    level: 2,
                    children: [TagTreeNode(name: 'organic', level: 3)],
                  ),
                ],
              ),
              TagTreeNode(name: 'history', level: 1),
            ],
          ),
        );

        expect(rows.map((row) => row.fullTag.value), [
          'science_fiction',
          'science_fiction::biology',
          'science_fiction::chemistry',
          'science_fiction::chemistry::organic',
          'history',
        ]);
        expect(rows.map((row) => row.displayName), [
          'science fiction',
          'biology',
          'chemistry',
          'organic',
          'history',
        ]);
        expect(rows.map((row) => row.level), [0, 1, 1, 2, 0]);
        expect(rows.map((row) => row.hasChildren), [
          true,
          false,
          true,
          false,
          false,
        ]);
        expect(rows.map((row) => row.collapsed), [
          true,
          false,
          false,
          false,
          false,
        ]);
      },
    );

    test(
      'collapsed visibility skips descendants and resumes at sibling levels',
      () {
        final rows = flattenTagTree(
          TagTreeNode(
            name: '',
            level: 0,
            children: [
              TagTreeNode(
                name: 'a',
                level: 1,
                collapsed: true,
                children: [
                  TagTreeNode(
                    name: 'b',
                    level: 2,
                    children: [TagTreeNode(name: 'c', level: 3)],
                  ),
                ],
              ),
              TagTreeNode(name: 'd', level: 1),
            ],
          ),
        );

        expect(
          applyCollapsedTagVisibility(rows).map((row) => row.fullTag.value),
          ['a', 'd'],
        );
      },
    );

    test(
      'search includes matching ancestors in source order and expands them',
      () {
        final rows = flattenTagTree(
          TagTreeNode(
            name: '',
            level: 0,
            children: [
              TagTreeNode(
                name: 'Science',
                level: 1,
                collapsed: true,
                children: [
                  TagTreeNode(name: 'Biology', level: 2),
                  TagTreeNode(name: 'Physics', level: 2),
                ],
              ),
              TagTreeNode(
                name: 'History',
                level: 1,
                collapsed: true,
                children: [TagTreeNode(name: 'Ancient', level: 2)],
              ),
            ],
          ),
        );

        final result = applyTagSearchFilter(rows, 'BIO');
        expect(result.map((row) => row.fullTag.value), [
          'Science',
          'Science::Biology',
        ]);
        expect(result.map((row) => row.collapsed), [false, false]);
        expect(rows.first.collapsed, isTrue);
      },
    );

    test('search preserves collapsed state when only the parent matches', () {
      final rows = [
        TagListItemState(
          fullTag: TagName.build('Science')!,
          displayName: 'Science',
          level: 0,
          hasChildren: true,
          collapsed: true,
        ),
        TagListItemState(
          fullTag: TagName.build('History')!,
          displayName: 'History',
          level: 0,
          hasChildren: false,
          collapsed: true,
        ),
      ];

      final result = applyTagSearchFilter(rows, 'science');
      expect(result.map((row) => row.fullTag.value), ['Science']);
      expect(result.single.collapsed, isTrue);
    });

    test('blank root tag fails during flattening like the source', () {
      expect(
        () => flattenTagTree(
          TagTreeNode(
            name: '',
            level: 0,
            children: [TagTreeNode(name: '  ', level: 1)],
          ),
        ),
        throwsStateError,
      );
    });

    test('tag rows use data-class value equality', () {
      final first = TagListItemState(
        fullTag: TagName.build('a::b')!,
        displayName: 'b',
        level: 1,
        hasChildren: false,
        collapsed: false,
      );
      final second = TagListItemState(
        fullTag: TagName.build('a::b')!,
        displayName: 'b',
        level: 1,
        hasChildren: false,
        collapsed: false,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}
