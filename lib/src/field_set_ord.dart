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
 * Source-derived from Field.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Writes a field ordinal through the host JSON object's `put("ord", value)`.
///
/// The host owns its null sentinel and write behavior. Any write failure passes
/// through unchanged.
void setLibAnkiFieldOrd({
  required int? value,
  required Object nullSentinel,
  required void Function(String key, Object? value) put,
}) {
  put('ord', value ?? nullSentinel);
}
