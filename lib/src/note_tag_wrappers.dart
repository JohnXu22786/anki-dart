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
 * Source-derived from Note tag wrappers in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Host-provided `Collection.tags.inList(tag, noteTags)` operation.
typedef NoteTagInList = bool Function(String tag, Iterable<String> noteTags);

/// Host-provided `Collection.tags.canonify(noteTags)` operation.
typedef NoteTagCanonify = Iterable<String> Function(Iterable<String> noteTags);

/// Host-provided `Collection.tags.join(canonicalTags)` operation.
typedef NoteTagJoin = String Function(Iterable<String> canonicalTags);

/// Host-provided `Collection.tags.split(value)` operation.
typedef NoteTagSplit = List<String> Function(String value);

/// Host setter for a Note's mutable tag list.
typedef NoteTagsSetter = void Function(List<String> tags);

/// Returns the host `inList` result, passing the requested tag first.
bool hasNoteTag(
  Iterable<String> noteTags,
  String tag, {
  required NoteTagInList inList,
}) => inList(tag, noteTags);

/// Appends [tag] once, preserving duplicates for the host's later save step.
void addNoteTag(List<String> tags, String tag) {
  tags.add(tag);
}

/// Canonifies the Note tags and joins that exact result through host callbacks.
String stringNoteTags(
  Iterable<String> noteTags, {
  required NoteTagCanonify canonify,
  required NoteTagJoin join,
}) => join(canonify(noteTags));

/// Splits [value] and replaces the Note tag list with the exact returned list.
void setNoteTagsFromStr(
  String value, {
  required NoteTagSplit split,
  required NoteTagsSetter setTags,
}) {
  setTags(split(value));
}
