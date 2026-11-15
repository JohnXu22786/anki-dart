/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
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
 * Source-derived from Collection.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Calls the host collection's [getCard] callback and returns its card, or null
/// when the callback throws.
///
/// The callback receives the exact [id] once. All thrown Dart [Object]s are
/// caught to match Kotlin's `runCatching`; collection, card, and ID types remain
/// host-side.
TCard? collectionGetCardOrNull<TId, TCard>(
  TId id,
  TCard Function(TId) getCard,
) {
  try {
    return getCard(id);
  } on Object {
    return null;
  }
}
