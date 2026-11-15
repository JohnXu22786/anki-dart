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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ManageTagsViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The source action that selects a Manage Tags mutation and user message.
enum ManageTagsOperationAction { remove, rename, clearUnused }

/// A count-bearing event emitted after a Manage Tags mutation succeeds.
sealed class ManageTagsUserMessage {
  const ManageTagsUserMessage(this.count);

  final int count;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is ManageTagsUserMessage &&
      other.count == count;

  @override
  int get hashCode => Object.hash(runtimeType, count);
}

final class ManageTagsTagRemoved extends ManageTagsUserMessage {
  const ManageTagsTagRemoved(super.count);
}

final class ManageTagsTagRenamed extends ManageTagsUserMessage {
  const ManageTagsTagRenamed(super.count);
}

final class ManageTagsClearedUnusedTags extends ManageTagsUserMessage {
  const ManageTagsClearedUnusedTags(super.count);
}

/// Host-provided undoable operations, already bound to their tag arguments.
final class ManageTagsOperationCallbacks {
  const ManageTagsOperationCallbacks({
    required this.removeTag,
    required this.renameTag,
    required this.clearUnusedTags,
  });

  final Future<int> Function() removeTag;
  final Future<int> Function() renameTag;
  final Future<int> Function() clearUnusedTags;

  Future<int> Function() forAction(ManageTagsOperationAction action) =>
      switch (action) {
        ManageTagsOperationAction.remove => removeTag,
        ManageTagsOperationAction.rename => renameTag,
        ManageTagsOperationAction.clearUnused => clearUnusedTags,
      };
}

/// The captured query and ordered host callbacks for one tag operation.
final class ManageTagsOperationPlan {
  const ManageTagsOperationPlan._({
    required this.action,
    required this.searchQuery,
    required Future<int> Function() operation,
  }) : _operation = operation;

  final ManageTagsOperationAction action;
  final String searchQuery;
  final Future<int> Function() _operation;

  /// Runs mutation, its matching event, and reload in source order.
  ///
  /// The host supplies its cancellation type test because Dart has no built-in
  /// equivalent of Kotlin's `CancellationException`. Other [Exception] values
  /// are published unchanged; failures stop all later callbacks. Non-Exception
  /// Dart errors are not caught, matching Kotlin's `catch (Exception)` scope.
  Future<void> run({
    required Future<void> Function(ManageTagsUserMessage message) sendMessage,
    required Future<void> Function(String searchQuery) reloadTags,
    required void Function(Exception exception) publishError,
    required bool Function(Exception exception) isCancellation,
  }) async {
    try {
      final count = await _operation();
      await sendMessage(_messageFor(action, count));
      await reloadTags(searchQuery);
    } on Exception catch (exception) {
      if (isCancellation(exception)) rethrow;
      publishError(exception);
    }
  }
}

/// Captures the previous Content query and sets Loading before the host launches
/// [ManageTagsOperationPlan.run]. A null query means the previous state was not
/// Content and therefore uses the source's empty-query fallback.
ManageTagsOperationPlan prepareManageTagsOperation({
  required ManageTagsOperationAction action,
  required String? contentSearchQuery,
  required void Function() setLoading,
  required ManageTagsOperationCallbacks operations,
}) {
  final searchQuery = contentSearchQuery ?? '';
  final operation = operations.forAction(action);
  setLoading();
  return ManageTagsOperationPlan._(
    action: action,
    searchQuery: searchQuery,
    operation: operation,
  );
}

ManageTagsUserMessage _messageFor(
  ManageTagsOperationAction action,
  int count,
) => switch (action) {
  ManageTagsOperationAction.remove => ManageTagsTagRemoved(count),
  ManageTagsOperationAction.rename => ManageTagsTagRenamed(count),
  ManageTagsOperationAction.clearUnused => ManageTagsClearedUnusedTags(count),
};
