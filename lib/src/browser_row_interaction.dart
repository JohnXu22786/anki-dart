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
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'browser_row_collection.dart';
import 'browser_row_selection.dart';

/// The selection operation chosen by a Card Browser row interaction.
sealed class BrowserRowInteractionDirective {
  const BrowserRowInteractionDirective();
}

/// Directs the host to select the source-ordered range between two row IDs.
final class BrowserRowRangeSelectionDirective
    extends BrowserRowInteractionDirective {
  const BrowserRowRangeSelectionDirective({
    required this.startRowId,
    required this.endRowId,
  });

  final BrowserRowId startRowId;
  final BrowserRowId endRowId;

  @override
  bool operator ==(Object other) =>
      other is BrowserRowRangeSelectionDirective &&
      other.startRowId == startRowId &&
      other.endRowId == endRowId;

  @override
  int get hashCode => Object.hash(startRowId, endRowId);
}

/// Directs the host to toggle the exact row selection supplied by the event.
final class BrowserRowToggleSelectionDirective
    extends BrowserRowInteractionDirective {
  const BrowserRowToggleSelectionDirective(this.selection);

  final BrowserRowSelection selection;

  @override
  bool operator ==(Object other) =>
      other is BrowserRowToggleSelectionDirective &&
      other.selection == selection;

  @override
  int get hashCode => selection.hashCode;
}

/// Projects AnkiDroid's `handleRowLongPress` range-or-toggle decision.
///
/// A range is selected only when multi-select is active and
/// [lastSelectedRowId] exists. Otherwise, the original row selection is passed
/// to the toggle operation. The host performs the selection mutation.
BrowserRowInteractionDirective planBrowserRowLongPress({
  required BrowserRowSelection selection,
  required bool isInMultiSelectMode,
  required BrowserRowId? lastSelectedRowId,
}) => _planBrowserRowSelection(
  selection: selection,
  isInMultiSelectMode: isInMultiSelectMode,
  lastSelectedRowId: lastSelectedRowId,
);

/// Projects AnkiDroid's `handleRightClick` range-or-toggle decision.
///
/// The source duplicates the long-press guard and fallback; this entry point
/// retains that behavior for right-click events. The host performs the chosen
/// selection mutation.
BrowserRowInteractionDirective planBrowserRowRightClick({
  required BrowserRowSelection selection,
  required bool isInMultiSelectMode,
  required BrowserRowId? lastSelectedRowId,
}) => _planBrowserRowSelection(
  selection: selection,
  isInMultiSelectMode: isInMultiSelectMode,
  lastSelectedRowId: lastSelectedRowId,
);

BrowserRowInteractionDirective _planBrowserRowSelection({
  required BrowserRowSelection selection,
  required bool isInMultiSelectMode,
  required BrowserRowId? lastSelectedRowId,
}) {
  if (isInMultiSelectMode && lastSelectedRowId != null) {
    return BrowserRowRangeSelectionDirective(
      startRowId: lastSelectedRowId,
      endRowId: selection.rowId,
    );
  }
  return BrowserRowToggleSelectionDirective(selection);
}
