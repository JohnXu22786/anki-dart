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
 * ANKIDROID_UPSTREAM.md.
 */

/// Host request to open the Reviewer tag editor for one note.
class ReviewerEditTagsDirective {
  const ReviewerEditTagsDirective({required this.noteId});

  /// The host-resolved note ID, unchanged.
  final int noteId;

  /// The singleton note-ID list passed to the host tag-dialog factory.
  List<int> get noteIds => [noteId];
}

/// Projects a host-resolved note ID to the Reviewer edit-tags request.
///
/// Current-card and collection lookup, action dispatch, flow delivery, and
/// Android dialog creation and lifecycle remain the host's responsibility.
ReviewerEditTagsDirective reviewerEditTagsDirective({required int noteId}) =>
    ReviewerEditTagsDirective(noteId: noteId);
