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

/// Returns host-supplied input template names whose indices are unmapped.
///
/// Duplicate map values collapse through set membership. Null and out-of-range
/// values do not match any input list index. Name order and duplicates remain.
List<String> projectChangeNoteTypeDiscardedTemplates({
  required Map<int, int?> templateChangeMap,
  required List<String> inputTemplateNames,
}) {
  final mappedOrdinals = templateChangeMap.values.toSet();
  return [
    for (var index = 0; index < inputTemplateNames.length; index++)
      if (!mappedOrdinals.contains(index)) inputTemplateNames[index],
  ];
}
