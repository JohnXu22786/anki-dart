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

/// Selects the card IDs passed to the source Card Browser note editor.
///
/// Row resolution and collection queries remain host-owned. A null resolved
/// card ID represents a row that cannot be edited.
List<int> browserEditorCardIds({
  required int? resolvedRowCardId,
  required BrowserColumnMode mode,
  required bool isInMultiSelectMode,
  required List<int> noteCardIds,
  required List<int> selectedCardIds,
}) {
  if (resolvedRowCardId == null) return const [];

  if (mode == BrowserColumnMode.notes) return noteCardIds;
  if (isInMultiSelectMode) return selectedCardIds;
  return [resolvedRowCardId];
}
