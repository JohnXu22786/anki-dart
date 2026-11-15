/*
 * Copyright (c) 2025 David Allison <davidallisongithub@gmail.com>
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
 * SPDX-FileCopyrightText: 2025 David Allison <davidallisongithub@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from LibAnki.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Mutable global state for LibAnki, retained for CollectionManager users.
///
/// Production code should access these values through CollectionManagers
/// instead of using this global holder directly. The backend and collection
/// implementations remain owned by the host.
abstract final class LibAnki {
  /// The currently active backend. The host owns its concrete type and lifetime.
  @Deprecated('Only use this inside CollectionManagers')
  static Object? backend;

  /// The current collection. The host owns its concrete type and lifetime.
  @Deprecated('Only use this inside CollectionManagers')
  static Object? collection;
}
