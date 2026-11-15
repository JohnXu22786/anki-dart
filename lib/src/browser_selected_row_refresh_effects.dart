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

/// Runs the post-append effects from `CardBrowserViewModel.onAppendSelectedRows`.
///
/// [hasSelectedRows] is supplied by the host after it mutates selection. A
/// mode-change reason is emitted only when rows remain; refresh and logging
/// always follow in that order. Callback failures propagate and stop later
/// effects.
void runBrowserAppendSelectedRowsEffects<TReason>({
  required bool hasSelectedRows,
  required TReason reason,
  required void Function(TReason reason) emitMultiSelectModeChanged,
  required void Function() refreshSelectedRows,
  required void Function() logRefreshedSelectedRows,
}) {
  if (hasSelectedRows) emitMultiSelectModeChanged(reason);
  refreshSelectedRows();
  logRefreshedSelectedRows();
}

/// Runs the post-remove effects from `CardBrowserViewModel.onRemoveSelectedRows`.
///
/// [hasSelectedRows] is supplied by the host after it mutates selection. A
/// mode-change reason is emitted only when no rows remain and
/// [disableMultiSelectIfEmpty] is true (defaulting to true); refresh and
/// logging always follow in that order. Callback failures propagate and stop
/// later effects.
void runBrowserRemoveSelectedRowsEffects<TReason>({
  required bool hasSelectedRows,
  bool disableMultiSelectIfEmpty = true,
  required TReason reason,
  required void Function(TReason reason) emitSingleSelectModeChanged,
  required void Function() refreshSelectedRows,
  required void Function() logRefreshedSelectedRows,
}) {
  if (!hasSelectedRows && disableMultiSelectIfEmpty) {
    emitSingleSelectModeChanged(reason);
  }
  refreshSelectedRows();
  logRefreshedSelectedRows();
}
