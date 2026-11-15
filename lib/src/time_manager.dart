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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from TimeManager.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Tracks AnkiDroid's current time object and its test override.
///
/// The host supplies the stable default object, keeping clock construction and
/// platform behavior outside this state-only port.
final class TimeManager<T> {
  /// Creates a manager with the host-created default time object.
  TimeManager({required T defaultTime}) : _defaultTime = defaultTime;

  final T _defaultTime;
  final List<T> _mockInstances = <T>[];

  /// The top override, or the same default object when there is no override.
  T get time => _mockInstances.isEmpty ? _defaultTime : _mockInstances.last;

  /// Clears all test overrides.
  void reset() => _mockInstances.clear();

  /// Replaces all overrides with the exact supplied time object.
  void resetWith(T mockTime) {
    reset();
    _mockInstances.add(mockTime);
  }
}
