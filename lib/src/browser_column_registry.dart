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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserViewModel.refreshBackendColumns() in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Indexes host-resolved backend columns by their keys in source order.
///
/// This matches Kotlin `associateBy { it.key }`: a later duplicate replaces
/// the value for that key while the key keeps its first insertion position.
/// Backend retrieval, labels, samples, rows, and localization stay host-side.
Map<String, T> browserColumnRegistryByKey<T>(
  Iterable<T> columns,
  String Function(T column) keyOf,
) {
  final registry = <String, T>{};
  for (final column in columns) {
    registry[keyOf(column)] = column;
  }
  return registry;
}
