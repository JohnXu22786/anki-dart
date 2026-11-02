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
 * Behavioral reference: CardBrowserViewModel.findAndReplace() and
 * FindReplaceResult in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Sentinel field values emitted by AnkiDroid's find-and-replace dialog.
const browserAllFieldsAsField =
    'find_and_replace_dialog_fragment_all_fields_as_field';
const browserTagsAsField = 'find_and_replace_dialog_fragment_tags_as_field';

/// The host operation selected by Card Browser find-and-replace.
enum BrowserFindReplaceCommand { tags, collection }

/// The host arguments for one Card Browser find-and-replace operation.
final class BrowserFindReplacePlan {
  const BrowserFindReplacePlan({
    required this.command,
    required this.noteIds,
    required this.search,
    required this.replacement,
    required this.regex,
    required this.matchCase,
    required this.field,
  });

  final BrowserFindReplaceCommand command;
  final List<int> noteIds;
  final String search;
  final String replacement;
  final bool regex;
  final bool matchCase;

  /// Null for the Tags command and for Collection's all-fields command.
  final String? field;
}

/// Projects the host arguments selected by `CardBrowserViewModel.findAndReplace()`.
///
/// The host supplies the already-resolved selected note IDs. When selection-only
/// is disabled, the source passes an empty list to mean all notes. The host
/// retains ID lookup, undoable collection/tag operations, matching, and Android
/// dialog and result delivery.
BrowserFindReplacePlan planBrowserFindReplace({
  required String field,
  required bool onlyOnSelectedNotes,
  required List<int> selectedNoteIds,
  required String search,
  required String replacement,
  required bool regex,
  required bool matchCase,
}) {
  final noteIds = onlyOnSelectedNotes ? selectedNoteIds : const <int>[];
  if (field == browserTagsAsField) {
    return BrowserFindReplacePlan(
      command: BrowserFindReplaceCommand.tags,
      noteIds: noteIds,
      search: search,
      replacement: replacement,
      regex: regex,
      matchCase: matchCase,
      field: null,
    );
  }

  return BrowserFindReplacePlan(
    command: BrowserFindReplaceCommand.collection,
    noteIds: noteIds,
    search: search,
    replacement: replacement,
    regex: regex,
    matchCase: matchCase,
    field: field == browserAllFieldsAsField ? null : field,
  );
}

/// Returns the host operation's affected-note count without conversion.
int browserFindReplaceResultCount(int count) => count;
