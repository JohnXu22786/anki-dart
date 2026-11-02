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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: DeckPickerViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Finds [deckId] in the visible deck IDs, falling back through its parents.
///
/// This preserves `findDeckPosition`'s first-visible-match and recursive parent
/// lookup behavior. The host supplies the flattened IDs and resolves each
/// deck's immediate parent from the due tree; tree construction and scrolling
/// remain host-side.
int findDeckPosition({
  required List<int> flattenedDeckIds,
  required int deckId,
  required int? Function(int deckId) parentDeckId,
}) {
  final position = flattenedDeckIds.indexOf(deckId);
  if (position >= 0) return position;

  final parentId = parentDeckId(deckId);
  if (parentId == null) return 0;
  return findDeckPosition(
    flattenedDeckIds: flattenedDeckIds,
    deckId: parentId,
    parentDeckId: parentDeckId,
  );
}
