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

/// Projects one template mapping event over the host's current ordered map.
///
/// Disabled mappings preserve the current map and ignore the event. For an
/// enabled non-null selection, any existing key using that input ordinal is
/// cleared before the requested output ordinal is assigned. Null selections
/// do not clear any existing null mappings.
Map<int, int?> projectChangeNoteTypeTemplateMappingUpdate({
  required bool templatesEnabled,
  required Map<int, int?> currentMap,
  required int outputTemplateOrdinal,
  required int? selectedInputTemplateOrdinal,
}) {
  if (!templatesEnabled) {
    return currentMap;
  }

  final updatedMap = Map<int, int?>.of(currentMap);
  final selectedOrdinal = selectedInputTemplateOrdinal;
  if (selectedOrdinal != null) {
    final keysToClear = updatedMap.entries
        .where((entry) => entry.value == selectedOrdinal)
        .map((entry) => entry.key)
        .toList(growable: false);
    assert(keysToClear.length <= 1, 'a card was mapped multiple times');
    for (final key in keysToClear) {
      updatedMap[key] = null;
    }
  }

  updatedMap[outputTemplateOrdinal] = selectedOrdinal;
  return updatedMap;
}
