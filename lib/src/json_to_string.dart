/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * Copyright (C) 2010 The Android Open Source Project
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
 * SPDX-FileCopyrightText: 2010 The Android Open Source Project
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Adapted from the Apache-2.0 `JSON.toString()` in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md, NOTICE.md, and LICENSES/Apache-2.0.txt.
 */

/// Returns a string unchanged, or delegates non-string conversion to the host.
///
/// The host callback must implement Kotlin/JVM `Any.toString()` for its value
/// representation. It is required for every call but runs only when [value] is
/// non-null and not a [String]. Callback failures propagate unchanged.
String? jsonToString(
  Object? value, {
  required String Function(Object value) hostToString,
}) {
  if (value is String) {
    return value;
  } else if (value != null) {
    return hostToString(value);
  }
  return null;
}
