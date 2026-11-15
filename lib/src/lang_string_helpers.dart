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
 * Behavioral reference: Lang.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Removes U+2068 and U+2069 isolation markers from [s], in that order.
///
/// All other text is preserved. This helper is used to compare translated
/// strings without their Unicode isolation markers.
String withoutUnicodeIsolation(String s) =>
    s.replaceAll('\u2068', '').replaceAll('\u2069', '');

/// Replaces each literal `\s+` sequence in [s] with one space.
///
/// This intentionally uses literal string replacement, matching the pinned
/// Kotlin String overload; it does not collapse whitespace characters.
String withCollapsedWhitespace(String s) => s.replaceAll(r'\s+', ' ');
