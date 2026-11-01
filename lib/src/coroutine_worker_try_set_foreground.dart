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
 * Source-derived from CoroutineWorker.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Awaits the host foreground operation, warning and returning normally on any
/// failure, following AnkiDroid's `CoroutineWorker.trySetForeground`.
///
/// The host supplies WorkManager's foreground operation and Timber warning
/// callback. The identical [foregroundInfo] is passed once to [setForeground].
/// Any thrown object from that callback is passed once to [warn] and swallowed
/// if warning succeeds; a failure from [warn] propagates.
Future<void> coroutineWorkerTrySetForeground<T>({
  required T foregroundInfo,
  required Future<void> Function(T foregroundInfo) setForeground,
  required void Function(Object error) warn,
}) async {
  try {
    await setForeground(foregroundInfo);
  } catch (error) {
    warn(error);
  }
}
