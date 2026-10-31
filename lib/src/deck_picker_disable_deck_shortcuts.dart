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
 * Source-derived from DeckPickerViewModel.kt:502–505 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Resolves the target subtree, stringifies its IDs in order, and emits once.
///
/// [findDeckAndChildren] is the host's nullable `dueTree?.find(deckId)` lookup;
/// it receives [deckId] unchanged and returns the found node's source-order
/// iteration, or null when the due tree or match is absent. The host retains
/// the due tree, node lookup, coroutine scheduling/error handling, flow
/// delivery, lifecycle, and shortcut service. ID conversion is eager, so a
/// lookup or conversion failure propagates before [emit] is called.
List<String> disableDeckAndChildrenShortcuts<TNode>({
  required int deckId,
  required Iterable<TNode>? Function(int deckId) findDeckAndChildren,
  required Object? Function(TNode node) didOf,
  required void Function(List<String> deckIds) emit,
}) {
  final deckTreeDids =
      findDeckAndChildren(
        deckId,
      )?.map((node) => didOf(node).toString()).toList() ??
      const <String>[];
  emit(deckTreeDids);
  return deckTreeDids;
}
