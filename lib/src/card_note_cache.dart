/*
 * Copyright (c) 2009 Daniel Svärd <daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host-neutral cache behavior for AnkiDroid's `Card.note` and `noteType`.
///
/// The host supplies card note IDs, `Collection.getNote`, and note type access;
/// note and collection implementations remain host-owned.
final class CardNoteCache<TNote extends Object> {
  CardNoteCache({TNote? cachedNote}) : _cachedNote = cachedNote;

  TNote? _cachedNote;

  /// Returns the cached note, loading it when absent or when [reload] is true.
  ///
  /// The note is cached only after [getNote] succeeds, so a failed reload keeps
  /// the previous cached note and propagates the original failure.
  TNote note({
    required int noteId,
    required TNote Function(int noteId) getNote,
    bool reload = false,
  }) {
    if (_cachedNote == null || reload) {
      final loadedNote = getNote(noteId);
      _cachedNote = loadedNote;
    }
    return _cachedNote!;
  }

  /// Returns the host notetype for the note obtained through [note].
  TNoteType noteType<TNoteType extends Object>({
    required int noteId,
    required TNote Function(int noteId) getNote,
    required TNoteType Function(TNote note) getNoteType,
  }) => getNoteType(note(noteId: noteId, getNote: getNote));
}
