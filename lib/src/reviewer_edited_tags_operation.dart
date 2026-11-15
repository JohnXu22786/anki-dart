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
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'dart:async';

import 'reviewer_edited_tags_directive.dart';

/// Applies the source-ordered host operations from `ReviewerViewModel.onEditedTags`.
///
/// The current card and its note are resolved once, and the note's ordered tags
/// are read once. Equal ordered lists return `false` without writing tags or
/// starting an undoable update. Otherwise the selected tags are joined with
/// one literal ASCII space, written first, and then the same note is updated
/// undoably. Callback failures propagate unchanged and stop subsequent work.
/// Card/collection access, tag mutation, undo storage, and scheduling remain
/// host-owned.
Future<bool>
executeReviewerEditedTags<TCard extends Object, TNote extends Object>({
  required List<String> selectedTags,
  required FutureOr<TCard> Function() currentCard,
  required FutureOr<TNote> Function(TCard card) noteForCard,
  required FutureOr<List<String>> Function(TNote note) tagsForNote,
  required FutureOr<void> Function(TNote note, String tagsString)
  setTagsFromString,
  required FutureOr<void> Function(TNote note) updateNoteUndoably,
}) async {
  final card = await currentCard();
  final note = await noteForCard(card);
  final existingTags = await tagsForNote(note);
  final directive = reviewerEditedTagsDirective(
    existingTags: existingTags,
    selectedTags: selectedTags,
  );
  if (directive == null) return false;

  await setTagsFromString(note, directive.tagsString);
  await updateNoteUndoably(note);
  return true;
}
