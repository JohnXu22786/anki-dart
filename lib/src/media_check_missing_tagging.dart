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
 * Behavioral reference: MediaCheckViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'media_check_unused_deletion.dart';

/// The host bulk-adds the exact note IDs with the caller-supplied tag.
final class MediaCheckBulkAddMissingTags {
  const MediaCheckBulkAddMissingTags({
    required this.noteIds,
    required this.tag,
  });

  final List<int> noteIds;
  final String tag;
}

/// Publishes the tagged-note count returned by a successful host operation.
final class MediaCheckPublishTaggedFilesCount {
  const MediaCheckPublishTaggedFilesCount(this.count);

  final int count;
}

/// The source-ordered inputs and completion behavior for tagging missing media.
class MediaCheckMissingTaggingPlan {
  const MediaCheckMissingTaggingPlan({
    required this.progress,
    required this.bulkAddEffect,
  });

  final MediaCheckProgress progress;
  final MediaCheckBulkAddMissingTags bulkAddEffect;

  /// Publishes the host operation's result count only after it succeeds.
  ///
  /// The host runs [bulkAddEffect] inside its undoable operation while progress
  /// is [progress]. It passes the returned count here only after success; on
  /// failure it propagates the error and omits this completion effect.
  MediaCheckPublishTaggedFilesCount? completeBulkAdd({
    required bool succeeded,
    required int taggedCount,
  }) => succeeded ? MediaCheckPublishTaggedFilesCount(taggedCount) : null;
}

/// Projects AnkiDroid's missing-media tagging action from the current result.
///
/// A missing check result supplies an empty note-ID list. The host performs the
/// bulk add in an undoable operation, under [MediaCheckProgress.addingTags],
/// then publishes its returned count only after success. Tag storage,
/// progress execution, and state delivery remain host responsibilities.
MediaCheckMissingTaggingPlan planMediaCheckMissingTagging(
  List<int>? missingNoteIds,
  String tag,
) => MediaCheckMissingTaggingPlan(
  progress: MediaCheckProgress.addingTags,
  bulkAddEffect: MediaCheckBulkAddMissingTags(
    noteIds: missingNoteIds ?? const [],
    tag: tag,
  ),
);
