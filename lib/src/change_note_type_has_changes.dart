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
 * Behavioral reference: ChangeNoteTypeViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Projects the source's dirty-state decision from host-resolved values.
///
/// The checks follow the source order: note-type identity, field map, then
/// template map. Map comparison is structural and independent of entry order;
/// a missing key differs from one whose value is null.
bool projectChangeNoteTypeHasChanges({
  required Object? inputNoteTypeId,
  required Object? outputNoteTypeId,
  required Map<int, int?> currentFieldMap,
  required Map<int, int?> defaultFieldMap,
  required Map<int, int?> currentTemplateMap,
  required Map<int, int?> defaultTemplateMap,
}) {
  if (outputNoteTypeId != inputNoteTypeId) {
    return true;
  }
  if (!_structurallyEqualMaps(currentFieldMap, defaultFieldMap)) {
    return true;
  }
  return !_structurallyEqualMaps(currentTemplateMap, defaultTemplateMap);
}

bool _structurallyEqualMaps(Map<int, int?> first, Map<int, int?> second) {
  if (first.length != second.length) {
    return false;
  }
  for (final entry in first.entries) {
    if (!second.containsKey(entry.key) || second[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
