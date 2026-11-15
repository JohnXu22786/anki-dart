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
 * see ANKIDROID_UPSTREAM.md.
 */

enum MediaCheckTrashAction { delete, restore }

/// A host-owned Media Check trash operation selected by the source method.
class MediaCheckTrashActionPlan {
  const MediaCheckTrashActionPlan(this.action);

  final MediaCheckTrashAction action;

  /// AnkiDroid enters progress without assigning a message for either action.
  String? get progressMessage => null;

  /// Runs the selected host operation inside progress and the collection host.
  ///
  /// The host supplies progress, collection access, and backend operations. This
  /// method only preserves their source order; asynchronous errors propagate to
  /// the caller unchanged.
  Future<void> run({
    required Future<void> Function({
      required String? message,
      required Future<void> Function() action,
    })
    withProgress,
    required Future<void> Function(Future<void> Function() action)
    withCollection,
    required Future<void> Function() emptyTrash,
    required Future<void> Function() restoreTrash,
  }) async {
    final operation = switch (action) {
      MediaCheckTrashAction.delete => emptyTrash,
      MediaCheckTrashAction.restore => restoreTrash,
    };
    await withProgress(
      message: progressMessage,
      action: () => withCollection(operation),
    );
  }
}

/// Projects AnkiDroid's delete-trash or restore-trash operation for the host.
MediaCheckTrashActionPlan planMediaCheckTrashAction(
  MediaCheckTrashAction action,
) => MediaCheckTrashActionPlan(action);
