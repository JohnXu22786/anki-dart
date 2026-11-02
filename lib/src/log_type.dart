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
 * Behavioral reference: LogType.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Timber tree categories selected by the host's build and test environment.
///
/// Installing the corresponding logging trees remains host-side.
enum LogType {
  DEBUG,
  ROBOLECTRIC,
  PRODUCTION;

  /// Selects the source logging mode using host-supplied build and test flags.
  static LogType select({
    required bool buildConfigDebug,
    required bool isRobolectric,
  }) {
    if (!buildConfigDebug) return LogType.PRODUCTION;
    return isRobolectric ? LogType.ROBOLECTRIC : LogType.DEBUG;
  }
}
