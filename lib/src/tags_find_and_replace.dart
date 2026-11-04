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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Tags.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Forwards a tag replacement request to the host backend unchanged.
///
/// The host owns its backend and result type; [T] preserves the exact result
/// returned by [findAndReplaceTag].
T tagsFindAndReplace<T>({
  required List<int> noteIds,
  required String search,
  required String replacement,
  required bool regex,
  required bool matchCase,
  required T Function(
    List<int> noteIds,
    String search,
    String replacement,
    bool regex,
    bool matchCase,
  )
  findAndReplaceTag,
}) => findAndReplaceTag(noteIds, search, replacement, regex, matchCase);
