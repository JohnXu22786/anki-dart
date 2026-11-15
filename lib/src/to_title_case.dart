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

/// Kotlin/JVM-compatible blank predicate supplied by the host.
typedef KotlinStringBlank = bool Function(String value);

/// Locale-aware String casing supplied by the host's current default locale.
typedef LocaleStringCase = String Function(String value);

/// Applies the pinned `StringUtils.toTitleCase()` callback sequence.
///
/// The host supplies Kotlin/JVM blank and locale case behavior. The source's
/// first UTF-16 code unit and remainder split are retained exactly.
String? toTitleCase(
  String? value, {
  required KotlinStringBlank isBlank,
  required LocaleStringCase uppercase,
  required LocaleStringCase lowercase,
}) {
  if (value == null) return null;
  if (isBlank(value)) return value;

  return uppercase(value.substring(0, 1)) + lowercase(value.substring(1));
}
