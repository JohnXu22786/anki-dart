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
 * Source-derived from NoteUtil.kt and Note.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// A host-independent snapshot of the backend fields produced from an Anki note.
///
/// Backend protobuf construction remains host-side. [tags] and [fields] are
/// copied in source order and exposed as unmodifiable lists.
final class BackendNoteProjection {
  BackendNoteProjection._({
    required this.id,
    required this.guid,
    required this.notetypeId,
    required this.mtimeSecs,
    required this.usn,
    required this.tags,
    required this.fields,
  });

  /// Projects the portable field mapping from `Note.toBackendNote()`.
  ///
  /// [guId] is asserted non-null, matching the source's `guId!!`; malformed
  /// notes fail rather than receiving a generated GUID or fallback.
  factory BackendNoteProjection.fromNote({
    required int id,
    required String? guId,
    required int noteTypeId,
    required int mod,
    required int usn,
    required Iterable<String> tags,
    required Iterable<String> fields,
  }) => BackendNoteProjection._(
    id: id,
    guid: guId!,
    notetypeId: noteTypeId,
    mtimeSecs: mod,
    usn: usn,
    tags: List<String>.unmodifiable(tags),
    fields: List<String>.unmodifiable(fields),
  );

  /// The note's source `id`.
  final int id;

  /// The note's non-null source `guId`.
  final String guid;

  /// The note's source `noteTypeId`.
  final int notetypeId;

  /// The note's source `mod` value in seconds.
  final int mtimeSecs;

  /// The note's source `usn`.
  final int usn;

  /// The source note's tags in order, copied into an unmodifiable snapshot.
  final List<String> tags;

  /// The source note's fields in order, copied into an unmodifiable snapshot.
  final List<String> fields;
}
