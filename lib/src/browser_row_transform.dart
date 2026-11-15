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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Looks up the host row first, then asks whether its original ID is selected.
///
/// The host retains row construction and selected-row membership. This helper
/// only sequences those operations and returns their values unchanged.
({TRow row, bool isSelected}) transformBrowserRow<TRowId, TRow>({
  required TRowId id,
  required TRow Function(TRowId id) browserRowForId,
  required bool Function(TRowId id) containsSelectedRow,
}) {
  final row = browserRowForId(id);
  final isSelected = containsSelectedRow(id);
  return (row: row, isSelected: isSelected);
}
