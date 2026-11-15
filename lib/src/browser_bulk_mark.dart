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

/// The tag mutation selected by AnkiDroid's Card Browser bulk-mark toggle.
enum BrowserBulkMarkOperation { addMarkedTag, removeMarkedTag }

/// Selects the source bulk-mark operation without performing collection work.
///
/// [selectedCardIds] is only used for the source's early empty-selection guard.
/// [noteMarkedStates] supplies the host-resolved `marked` tag state for the
/// notes represented by those cards. A non-null result asks the host to apply
/// the corresponding tag mutation in its undoable transaction and to publish
/// the source card-state change only after that transaction succeeds. An empty
/// [noteMarkedStates] uses the source's `all` behavior: it selects removal.
BrowserBulkMarkOperation? planBrowserBulkMarkToggle<T>({
  required Iterable<T> selectedCardIds,
  required Iterable<bool> noteMarkedStates,
}) {
  if (selectedCardIds.isEmpty) return null;

  return noteMarkedStates.every((isMarked) => isMarked)
      ? BrowserBulkMarkOperation.removeMarkedTag
      : BrowserBulkMarkOperation.addMarkedTag;
}
