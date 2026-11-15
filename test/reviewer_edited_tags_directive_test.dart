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
 * Source-derived Reviewer tag-edit cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer edited-tags directive', () {
    test('suppresses only structurally equal ordered lists', () {
      expect(
        reviewerEditedTagsDirective(
          existingTags: ['one', 'two'],
          selectedTags: ['one', 'two'],
        ),
        isNull,
      );
      expect(
        reviewerEditedTagsDirective(
          existingTags: ['one', 'two', 'two'],
          selectedTags: ['one', 'two'],
        ),
        isNotNull,
      );
      expect(
        reviewerEditedTagsDirective(
          existingTags: ['one', 'two'],
          selectedTags: ['two', 'one'],
        ),
        isNotNull,
      );
      expect(
        reviewerEditedTagsDirective(
          existingTags: const [],
          selectedTags: [],
        ),
        isNull,
      );
    });

    test('joins selected tags with one ASCII space without normalization', () {
      final directive = reviewerEditedTagsDirective(
        existingTags: ['old'],
        selectedTags: [' first ', '', 'third\t'],
      );

      expect(directive, isA<ReviewerEditedTagsDirective>());
      expect(directive!.tagsString, ' first   third\t');
      expect(
        reviewerEditedTagsDirective(
          existingTags: ['old'],
          selectedTags: [],
        )!.tagsString,
        '',
      );
      expect(
        reviewerEditedTagsDirective(
          existingTags: ['old'],
          selectedTags: ['', ''],
        )!.tagsString,
        ' ',
      );
    });
  });
}
