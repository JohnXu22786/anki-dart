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

/// Returns [defaultValue] when [value] is null or empty; otherwise returns the
/// exact [value] object supplied by the host.
///
/// The host supplies [isEmpty] because Dart has no equivalent of Kotlin's
/// `CharSequence` interface. For a null [value], [isEmpty] is not called. For a
/// nonnull [value], it is called once. [defaultValue] is called once only when
/// the value is null or empty. Callback exceptions propagate unchanged.
T ifNullOrEmpty<T extends Object>(
  T? value, {
  required bool Function(T value) isEmpty,
  required T Function() defaultValue,
}) {
  if (identical(value, null)) return defaultValue();
  final nonNullValue = value;
  if (isEmpty(nonNullValue)) return defaultValue();
  return nonNullValue;
}
