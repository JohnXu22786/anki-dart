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
 * Source-derived from AnkiDroid 2.25.3 CardBrowserViewModel.kt and
 * FindAndReplaceDialogFragment.kt; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserFindReplace', () {
    test('tags field chooses Tags and preserves the operation arguments', () {
      final selectedNoteIds = [19, 7, 23];
      final plan = planBrowserFindReplace(
        field: browserTagsAsField,
        onlyOnSelectedNotes: true,
        selectedNoteIds: selectedNoteIds,
        search: r'cat(\d+)',
        replacement: r'dog$1',
        regex: true,
        matchCase: true,
      );

      expect(plan.command, BrowserFindReplaceCommand.tags);
      expect(plan.noteIds, selectedNoteIds);
      expect(plan.search, r'cat(\d+)');
      expect(plan.replacement, r'dog$1');
      expect(plan.regex, isTrue);
      expect(plan.matchCase, isTrue);
      expect(plan.field, isNull);
    });

    test('all-fields field maps to null for the Collection command', () {
      final plan = planBrowserFindReplace(
        field: browserAllFieldsAsField,
        onlyOnSelectedNotes: true,
        selectedNoteIds: const [31, 12],
        search: 'before',
        replacement: 'after',
        regex: false,
        matchCase: false,
      );

      expect(plan.command, BrowserFindReplaceCommand.collection);
      expect(plan.field, isNull);
      expect(plan.noteIds, [31, 12]);
      expect(plan.search, 'before');
      expect(plan.replacement, 'after');
      expect(plan.regex, isFalse);
      expect(plan.matchCase, isFalse);
    });

    test('custom field is preserved and unchecked selection means all notes',
        () {
      final plan = planBrowserFindReplace(
        field: 'Front\u0000field',
        onlyOnSelectedNotes: false,
        selectedNoteIds: const [31, 12],
        search: 'x',
        replacement: 'y',
        regex: true,
        matchCase: false,
      );

      expect(plan.command, BrowserFindReplaceCommand.collection);
      expect(plan.field, 'Front\u0000field');
      expect(plan.noteIds, isEmpty);
      expect(plan.search, 'x');
      expect(plan.replacement, 'y');
      expect(plan.regex, isTrue);
      expect(plan.matchCase, isFalse);
    });

    test('host operation result count passes through unchanged', () {
      expect(browserFindReplaceResultCount(0), 0);
      expect(browserFindReplaceResultCount(17), 17);
    });
  });
}
