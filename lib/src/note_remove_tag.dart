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
 * Source-derived from Note.removeTag() in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Host-provided Kotlin/JVM-compatible `String.equals(ignoreCase = true)`.
///
/// The first argument is the tag being checked; the second is the requested
/// tag. Dart's own case folding does not define the source comparison.
typedef NoteTagEqualsIgnoreCase = bool Function(String tag, String other);

/// Removes all tags matching [tag] from [tags], preserving other tags' order.
///
/// Matching is delegated to [equalsIgnoreCase]. The source first collects all
/// matching strings, then removes each collected string with exact list
/// equality. Comparison failures propagate before any removal occurs.
void removeNoteTag(
  List<String> tags,
  String tag, {
  required NoteTagEqualsIgnoreCase equalsIgnoreCase,
}) {
  final matchingTags = <String>[];
  for (final candidate in tags) {
    if (equalsIgnoreCase(candidate, tag)) {
      matchingTags.add(candidate);
    }
  }
  for (final matchingTag in matchingTags) {
    tags.remove(matchingTag);
  }
}
