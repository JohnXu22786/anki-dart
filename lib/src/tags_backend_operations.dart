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
 * Source-derived from Tags.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Forwards `Tags.all()` to the host backend and returns its exact result.
T tagsAll<T>({required T Function() allTags}) => allTags();

/// Forwards `Tags.tree()` to the host backend and returns its exact result.
T tagsTree<T>({required T Function() tagTree}) => tagTree();

/// Forwards `Tags.clearUnusedTags()` to the host backend unchanged.
T tagsClearUnusedTags<T>({required T Function() clearUnusedTags}) =>
    clearUnusedTags();

/// Forwards `Tags.bulkAdd(noteIds, tags)` to the host backend unchanged.
T tagsBulkAdd<T>({
  required List<int> noteIds,
  required String tags,
  required T Function({required List<int> noteIds, required String tags})
  addNoteTags,
}) => addNoteTags(noteIds: noteIds, tags: tags);

/// Forwards `Tags.bulkRemove(noteIds, tags)` to the host backend unchanged.
T tagsBulkRemove<T>({
  required List<int> noteIds,
  required String tags,
  required T Function({required List<int> noteIds, required String tags})
  removeNoteTags,
}) => removeNoteTags(noteIds: noteIds, tags: tags);

/// Forwards `Tags.rename(old, new)` to the host backend's named arguments.
T tagsRename<T>({
  required String old,
  required String newValue,
  required T Function({
    required String currentPrefix,
    required String newPrefix,
  })
  renameTags,
}) => renameTags(currentPrefix: old, newPrefix: newValue);

/// Forwards `Tags.remove(spaceSeparatedTags)` to the host backend's `val`.
T tagsRemove<T>({
  required String spaceSeparatedTags,
  required T Function({required String val}) removeTags,
}) => removeTags(val: spaceSeparatedTags);

/// Forwards `Tags.reparent(tags, newParent)` to the host backend unchanged.
T tagsReparent<T>({
  required Iterable<String> tags,
  required String newParent,
  required T Function({
    required Iterable<String> tags,
    required String newParent,
  })
  reparentTags,
}) => reparentTags(tags: tags, newParent: newParent);
