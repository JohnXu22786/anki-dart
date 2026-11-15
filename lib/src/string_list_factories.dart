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
 * Source-derived from StringUtils.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Creates a growable, element-mutable list containing [size] empty strings.
List<String> emptyStringMutableList(int size) =>
    List<String>.filled(size, '', growable: true);

/// Creates a fixed-length, element-mutable list containing [size] empty strings.
///
/// This matches the size behavior of the source's `Array<String>`: entries can
/// be replaced, but the array cannot grow or shrink.
List<String> emptyStringArray(int size) =>
    List<String>.filled(size, '', growable: false);
