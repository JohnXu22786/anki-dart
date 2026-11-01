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
 * Source-derived from CharSequence.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Returns [defaultValue] when [value] is null or empty; otherwise returns
/// [value] unchanged.
///
/// The callback is evaluated exactly once only when the fallback is needed,
/// and its exceptions propagate. Kotlin's source extension accepts any
/// `CharSequence` subtype; this Dart helper is limited to [String] because this
/// package does not expose an equivalent `CharSequence` hierarchy.
String ifNullOrEmpty(String? value, String Function() defaultValue) {
  if (value == null || value.isEmpty) return defaultValue();
  return value;
}
