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

/// Returns a mutable copy of [activeColumns] with every selected-key match
/// replaced by [replacementColumn], preserving all positions and other values.
///
/// The host supplies the selected heading key and calls its own
/// `updateActiveColumns` with this list.
List<BrowserColumn> replaceBrowserSelectedColumn({
  required List<BrowserColumn> activeColumns,
  required String selectedColumnKey,
  required BrowserColumn replacementColumn,
}) => List<BrowserColumn>.of(
  activeColumns.map(
    (column) => column.key == selectedColumnKey ? replacementColumn : column,
  ),
);
