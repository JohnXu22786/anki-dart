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
 * ANKIDROID_UPSTREAM.md.
 */

import 'browser_column_collection.dart';
import 'browser_sort_type.dart';

/// Data for the Card Browser's sort-change notification.
sealed class BrowserSortChangeNotification {
  const BrowserSortChangeNotification();
}

/// The browser's sort order was cleared.
final class BrowserSortNoOrderingNotification
    extends BrowserSortChangeNotification {
  const BrowserSortNoOrderingNotification();
}

/// Collection ordering data displayed by the host's sort-change message.
final class BrowserSortCollectionOrderingNotification
    extends BrowserSortChangeNotification {
  const BrowserSortCollectionOrderingNotification({
    required this.columnLabel,
    required this.type,
    required this.reverse,
  });

  final String columnLabel;
  final BrowserColumnType type;
  final bool reverse;
}

/// Projects source sort type and already-resolved column presentation values.
///
/// The host resolves the localized label and Cards/Notes column type. Missing
/// labels fall back to the raw sort key; missing types fall back to
/// [BrowserColumnType.unspecified]. The source NoOrdering branch does not use
/// any of these collection-ordering values.
BrowserSortChangeNotification projectBrowserSortChangeNotification({
  required BrowserSortType sortType,
  String? resolvedColumnLabel,
  BrowserColumnType? resolvedColumnType,
}) => switch (sortType) {
  BrowserSortNoOrdering() => const BrowserSortNoOrderingNotification(),
  BrowserSortCollectionOrdering(:final key, :final reverse) =>
    BrowserSortCollectionOrderingNotification(
      columnLabel: resolvedColumnLabel ?? key,
      type: resolvedColumnType ?? BrowserColumnType.unspecified,
      reverse: reverse,
    ),
};
