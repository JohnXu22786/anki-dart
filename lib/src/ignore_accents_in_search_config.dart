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
 * Behavioral reference: Config.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Adapts `Config.ignoreAccentsInSearch` using host-supplied Config callbacks.
///
/// [key] must be the host's opaque token for the exact pinned generated key
/// `ConfigKey.Bool.IGNORE_ACCENTS_IN_SEARCH`. This adapter only forwards reads
/// and writes; generated Config keys, persistence, and search behavior stay
/// host-side.
class IgnoreAccentsInSearchConfig<TConfigKey> {
  /// Creates an adapter for the host token corresponding to the pinned key.
  IgnoreAccentsInSearchConfig({
    required TConfigKey key,
    required bool Function(TConfigKey key) getBool,
    required void Function(TConfigKey key, bool value) setBool,
  }) : _key = key,
       _getBool = getBool,
       _setBool = setBool;

  final TConfigKey _key;
  final bool Function(TConfigKey key) _getBool;
  final void Function(TConfigKey key, bool value) _setBool;

  /// Reads the current preference once through the host callback.
  bool get ignoreAccentsInSearch => _getBool(_key);

  /// Writes [value] once through the host callback without transforming it.
  set ignoreAccentsInSearch(bool value) => _setBool(_key, value);
}
