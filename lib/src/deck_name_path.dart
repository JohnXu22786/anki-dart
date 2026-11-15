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
 * Behavioral reference: Decks.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Splits a hierarchical deck name at AnkiDroid's exact `::` delimiter.
///
/// Empty and repeated components are preserved, matching Kotlin's
/// `String.split("::")` behavior.
List<String> deckNamePath(String name) => name.split('::');

/// Returns the final component of [name]'s hierarchical path.
String deckNameBasename(String name) => deckNamePath(name).last;

/// Returns all but the final component of [name]'s hierarchical path.
List<String> immediateParentDeckNamePath(String name) {
  final path = deckNamePath(name);
  return path.take(path.length - 1).toList(growable: false);
}

/// Joins [name]'s parent path, or returns null when it has no parent path.
String? immediateParentDeckName(String name) {
  final parentPath = immediateParentDeckNamePath(name);
  return parentPath.isEmpty ? null : parentPath.join('::');
}
