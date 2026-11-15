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
 * Behavioral reference: CardBrowserViewModel.deleteSelectedNotes() in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Runs the selected-note deletion effects through host-owned callbacks.
///
/// [cardIds] is the host-resolved list passed directly to the undoable removal
/// operation, preserving its order, duplicates, emptiness, and list identity.
/// A matching pane row is cleared first. After removal succeeds, the host ends
/// multi-select with `SingleSelectCause.Other`, refreshes search, and receives
/// the unchanged note count. A failed removal prevents those later effects.
Future<int> executeBrowserDeleteSelectedNotesPlan({
  required int? paneRowCardOrNoteId,
  required List<int> cardIds,
  required void Function() clearPaneRow,
  required Future<int> Function(List<int> cardIds) removeNotes,
  required void Function() endMultiSelectModeOther,
  required void Function() refreshSearch,
}) async {
  if (cardIds.contains(paneRowCardOrNoteId)) {
    clearPaneRow();
  }

  final count = await removeNotes(cardIds);
  endMultiSelectModeOther();
  refreshSearch();
  return count;
}
