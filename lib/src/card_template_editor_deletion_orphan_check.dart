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
 * Source-derived from CardTemplateEditor.kt; see ANKIDROID_UPSTREAM.md.
 */

/// Preserves the source `deletionWouldOrphanNote()` decision and callback order.
///
/// [tempModel] is kept opaque because the host owns `CardTemplateNotetype` and
/// its null assertion. [isOrdinalPendingAdd] receives that exact model first;
/// if it returns false, [getDeleteDbOrds] is called once and the exact list it
/// returns is passed to [queryCardIds] with [noteTypeId]. The host owns the
/// collection and `withCol` boundary, so a null query result means the source
/// considers deletion unsafe. Callback errors propagate unchanged.
Future<bool> cardTemplateEditorDeletionWouldOrphanNote({
  required Object? tempModel,
  required int position,
  required int noteTypeId,
  required bool Function(Object? tempModel, int position) isOrdinalPendingAdd,
  required List<int> Function(Object? tempModel, int position) getDeleteDbOrds,
  required Future<List<int>?> Function(int noteTypeId, List<int> deleteOrdinals)
  queryCardIds,
}) async {
  if (isOrdinalPendingAdd(tempModel, position)) return false;

  final currentDeletes = getDeleteDbOrds(tempModel, position);
  final cardIds = await queryCardIds(noteTypeId, currentDeletes);
  return cardIds == null;
}
