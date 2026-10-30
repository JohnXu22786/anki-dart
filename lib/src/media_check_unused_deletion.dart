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

/// Progress message used while AnkiDroid trashes unused media files.
enum MediaCheckProgress { deletingMedia }

/// A host operation in the unused-media deletion plan.
sealed class MediaCheckUnusedDeletionEffect {
  const MediaCheckUnusedDeletionEffect();
}

/// Trashes [files] through the host's media backend.
final class MediaCheckTrashUnusedFiles extends MediaCheckUnusedDeletionEffect {
  const MediaCheckTrashUnusedFiles(this.files);

  final List<String> files;
}

/// Publishes the number of files trashed by a successful operation.
final class MediaCheckPublishDeletedFilesCount
    extends MediaCheckUnusedDeletionEffect {
  const MediaCheckPublishDeletedFilesCount(this.count);

  final int count;
}

/// The source-ordered inputs and completion behavior for deleting unused media.
class MediaCheckUnusedDeletionPlan {
  const MediaCheckUnusedDeletionPlan({
    required this.progress,
    required this.trashEffect,
  });

  final MediaCheckProgress progress;
  final MediaCheckTrashUnusedFiles trashEffect;

  /// Returns the count publication only when the host trash operation succeeds.
  ///
  /// The host runs [trashEffect] inside progress identified by [progress], then
  /// applies this completion effect after success. On failure it must propagate
  /// the host error and omit the count publication, matching the source order.
  MediaCheckPublishDeletedFilesCount? completeTrash({
    required bool succeeded,
  }) => succeeded
      ? MediaCheckPublishDeletedFilesCount(trashEffect.files.length)
      : null;
}

/// Projects AnkiDroid's unused-file deletion using the current nullable result.
///
/// A missing check result supplies an empty list. The original list is passed to
/// the host unchanged; progress, filesystem access, trashing, and state delivery
/// remain host responsibilities.
MediaCheckUnusedDeletionPlan planMediaCheckUnusedDeletion(
  List<String>? unusedFiles,
) => MediaCheckUnusedDeletionPlan(
  progress: MediaCheckProgress.deletingMedia,
  trashEffect: MediaCheckTrashUnusedFiles(unusedFiles ?? const []),
);
