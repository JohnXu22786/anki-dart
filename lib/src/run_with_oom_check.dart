/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
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
 * Source-derived from Exceptions.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Runs [action] and handles only errors the host classifies as out of memory.
///
/// Dart cannot portably identify the JVM's `OutOfMemoryError`, so
/// [isOutOfMemoryError] must perform platform-specific classification. It is
/// called only when [action] throws. A classified error is passed unchanged to
/// the optional [onError] callback; if that callback succeeds (or is null),
/// this function returns null. Other action errors are rethrown with their
/// original stack trace. Classifier and handler failures propagate unchanged.
T? runWithOomCheck<T>({
  required T Function() action,
  required bool Function(Object error) isOutOfMemoryError,
  void Function(Object error)? onError,
}) {
  try {
    return action();
  } catch (error, stackTrace) {
    if (!isOutOfMemoryError(error)) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    onError?.call(error);
    return null;
  }
}
