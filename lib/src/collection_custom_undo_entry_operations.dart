/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from Collection.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Forwards the custom undo entry name to the host collection backend.
///
/// The host owns the undo entry and returns its step counter unchanged.
int collectionAddCustomUndoEntry(
  String name,
  int Function(String name) addCustomUndoEntry,
) => addCustomUndoEntry(name);

/// Forwards the undo step [target] to the host collection backend.
///
/// The host owns undo merging and the generated operation changes; its result
/// is returned unchanged.
TResult collectionMergeUndoEntries<TResult>(
  int target,
  TResult Function(int target) mergeUndoEntries,
) => mergeUndoEntries(target);
