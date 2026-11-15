/*
 * Copyright © 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from SavedStateHandle.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Returns the value for [key], throwing when the host getter returns null.
///
/// The host supplies any generic type checking. A getter failure propagates
/// unchanged.
T savedStateHandleRequire<T extends Object>(
  String key,
  T? Function(String key) get,
) {
  final value = get(key);
  if (value == null) {
    throw StateError("Wrong type or key '$key' not found");
  }
  return value;
}

/// Returns the nullable Long projection for [key].
///
/// The getter runs only after [contains] returns true. Its result is cast to
/// `int?`, and host callback failures propagate unchanged.
int? savedStateHandleGetLongOrNull(
  String key, {
  required bool Function(String key) contains,
  required Object? Function(String key) get,
}) {
  if (!contains(key)) return null;
  return get(key) as int?;
}
