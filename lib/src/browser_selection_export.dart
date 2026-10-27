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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'browser_column_collection.dart';
import 'browser_row_collection.dart';

/// Export category selected by AnkiDroid's current Cards or Notes browser mode.
enum BrowserSelectionExportType { notes, cards }

/// Mode and IDs passed from the selected rows to the host's export UI.
///
/// The IDs are a new list in the source selected-set iteration order. The host
/// supplies mode and selected rows; this value does not perform export work.
final class BrowserSelectionExportPlan {
  BrowserSelectionExportPlan._(this.type, this.ids);

  final BrowserSelectionExportType type;
  final List<int> ids;
}

/// Projects the source selected-row export data, or `null` for no selection.
///
/// [selectedRows] is expected to reflect the source LinkedHashSet iteration
/// order, so the resulting IDs retain that order without sorting or deduping.
/// Cards and Notes IDs are copied as-is; collection lookup and export are owned
/// by the host.
BrowserSelectionExportPlan? planBrowserSelectionExport({
  required BrowserColumnMode mode,
  required Iterable<BrowserRowId> selectedRows,
}) {
  final ids = selectedRows.map((row) => row.value).toList();
  if (ids.isEmpty) return null;

  final type = switch (mode) {
    BrowserColumnMode.cards => BrowserSelectionExportType.cards,
    BrowserColumnMode.notes => BrowserSelectionExportType.notes,
  };
  return BrowserSelectionExportPlan._(type, ids);
}
