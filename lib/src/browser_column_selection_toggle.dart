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

/// The host-projected row kinds used by AnkiDroid's column-selection adapter.
enum BrowserColumnSelectionRowKind {
  column,
  activeHeading,
  availableHeading,
}

/// Captures the indexes and side test used for one column toggle click.
///
/// [availableHeadingPosition] is found from the original row order and is also
/// the insertion index. [applyTo] retains the source's remove-then-add order
/// and deliberately does not validate indexes. The host owns click listeners,
/// adapter notifications, and RecyclerView lifecycle.
final class BrowserColumnSelectionTogglePlan {
  const BrowserColumnSelectionTogglePlan({
    required this.fromPosition,
    required this.availableHeadingPosition,
  });

  final int fromPosition;
  final int availableHeadingPosition;

  /// Matches the source `absoluteAdapterPosition < positionOfAvailableHeading`.
  bool get isBeforeAvailableHeading => fromPosition < availableHeadingPosition;

  /// Applies the source `removeAt(fromPosition); add(targetPosition, item)`.
  ///
  /// If the source index is valid but the Available heading is absent, the
  /// heading index is `-1`; removal therefore happens before insertion throws,
  /// matching the source operation order.
  void applyTo<T>(List<T> rows) {
    final row = rows.removeAt(fromPosition);
    rows.insert(availableHeadingPosition, row);
  }
}

/// Projects AnkiDroid's column-selection click decision without Android.
///
/// The host supplies a row-kind snapshot in the same order as its mutable row
/// list. The first Available heading is used; a missing heading yields `-1`.
/// Positions are not normalized or validated, preserving the source's
/// index-based move and failure behavior.
BrowserColumnSelectionTogglePlan planBrowserColumnSelectionToggle({
  required List<BrowserColumnSelectionRowKind> rowKinds,
  required int fromPosition,
}) =>
    BrowserColumnSelectionTogglePlan(
      fromPosition: fromPosition,
      availableHeadingPosition:
          rowKinds.indexOf(BrowserColumnSelectionRowKind.availableHeading),
    );
