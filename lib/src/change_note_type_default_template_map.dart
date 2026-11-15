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

/// Rebuilds the source's default output-to-input template ordinal map.
///
/// Each output ordinal maps to the same input ordinal when it exists, and to
/// null otherwise. Counts are consumed as supplied without validation.
Map<int, int?> projectChangeNoteTypeDefaultTemplateMap({
  required int inputTemplateCount,
  required int outputTemplateCount,
}) {
  final mapping = <int, int?>{};
  for (
    var outputOrdinal = 0;
    outputOrdinal < outputTemplateCount;
    outputOrdinal++
  ) {
    mapping[outputOrdinal] = outputOrdinal < inputTemplateCount
        ? outputOrdinal
        : null;
  }
  return mapping;
}
