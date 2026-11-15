/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Collection.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Adapts `Collection.cardStateCustomizer` through host-supplied Config callbacks.
///
/// [key] must be the host's opaque token for the exact pinned generated key
/// `ConfigKey.String.CARD_STATE_CUSTOMIZER`. This adapter only forwards reads
/// and writes; generated Config keys, persistence, and JavaScript execution stay
/// host-side.
class CollectionCardStateCustomizer<TConfigKey> {
  /// Creates an adapter for the host token corresponding to the pinned key.
  CollectionCardStateCustomizer({
    required TConfigKey key,
    required String Function(TConfigKey key) getString,
    required void Function(TConfigKey key, String value) setString,
  }) : _key = key,
       _getString = getString,
       _setString = setString;

  final TConfigKey _key;
  final String Function(TConfigKey key) _getString;
  final void Function(TConfigKey key, String value) _setString;

  /// Reads the current custom scheduling script once through the host callback.
  String get cardStateCustomizer => _getString(_key);

  /// Writes [value] once through the host callback without transforming it.
  set cardStateCustomizer(String value) => _setString(_key, value);
}
