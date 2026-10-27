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
 * Behavioral reference: BrowserColumnSelectionAdapter.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'browser_column_collection.dart';

/// The usage heading rows in AnkiDroid's column-selection adapter.
enum BrowserColumnSelectionUsage { active, available }

/// One host-supplied row from the column-selection adapter.
sealed class BrowserColumnSelectionAdapterRow {
  const BrowserColumnSelectionAdapterRow();
}

/// A column row; its label, sample, and rendering stay with the host.
final class BrowserColumnSelectionColumnItem
    extends BrowserColumnSelectionAdapterRow {
  const BrowserColumnSelectionColumnItem(this.columnType);

  final BrowserColumn columnType;
}

/// A usage heading row, which is not included in either projected column list.
final class BrowserColumnSelectionUsageItem
    extends BrowserColumnSelectionAdapterRow {
  const BrowserColumnSelectionUsageItem(this.usage);

  final BrowserColumnSelectionUsage usage;
}

/// The adapter's ordered displayed and available columns plus selected types.
final class BrowserColumnSelectionProjection {
  BrowserColumnSelectionProjection({
    required this.availableHeadingPosition,
    required List<BrowserColumn> displayed,
    required List<BrowserColumn> available,
  }) : displayed = List<BrowserColumn>.unmodifiable(displayed),
       available = List<BrowserColumn>.unmodifiable(available),
       selected = List<BrowserColumn>.unmodifiable(displayed);

  /// Index of the first Available usage heading, or `-1` when absent.
  final int availableHeadingPosition;

  /// Column items at indexes strictly before [availableHeadingPosition].
  final List<BrowserColumn> displayed;

  /// Column items at indexes strictly after [availableHeadingPosition].
  final List<BrowserColumn> available;

  /// The selected column types, in displayed order.
  final List<BrowserColumn> selected;
}

/// Projects the adapter's row list into displayed, available, and selected columns.
///
/// The first Available heading determines the split. Comparisons are strict,
/// so headings are excluded and any other row kinds are dropped. If the heading
/// is absent, its source index is `-1`: no row is displayed and every column
/// row is available. Duplicate Available headings leave later headings on the
/// available side, matching the source's first-match lookup.
BrowserColumnSelectionProjection projectBrowserColumnSelectionRows({
  required List<BrowserColumnSelectionAdapterRow> items,
}) {
  final headingPosition = items.indexWhere(
    (item) =>
        item is BrowserColumnSelectionUsageItem &&
        item.usage == BrowserColumnSelectionUsage.available,
  );
  final displayed = <BrowserColumn>[];
  final available = <BrowserColumn>[];

  for (var index = 0; index < items.length; index++) {
    final item = items[index];
    if (item is! BrowserColumnSelectionColumnItem) continue;
    if (index < headingPosition) displayed.add(item.columnType);
    if (index > headingPosition) available.add(item.columnType);
  }

  return BrowserColumnSelectionProjection(
    availableHeadingPosition: headingPosition,
    displayed: displayed,
    available: available,
  );
}
