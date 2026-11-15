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
 * Behavioral reference: CardBrowserViewModel.generateExpensiveSavedState() in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'browser_row_collection.dart';

/// Selects the row IDs the host should pass to its saved-selection `IdsFile`.
///
/// A nonempty pending restore remains authoritative until it is applied to
/// rows. Otherwise this snapshots [selectedRows]. The host owns persistence,
/// `IdsFile` construction, and Android saved-state plumbing.
List<int>? browserSavedSelectionPayloadIds({
  required List<BrowserRowId> pendingSelectionRestore,
  required Iterable<BrowserRowId> selectedRows,
}) {
  final selection = pendingSelectionRestore.isNotEmpty
      ? pendingSelectionRestore
      : List<BrowserRowId>.of(selectedRows);
  if (selection.isEmpty) return null;
  return List<int>.unmodifiable(selection.map((row) => row.value));
}
