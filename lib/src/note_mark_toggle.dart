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
 * Behavioral reference: NoteService.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The source operation applied to the note's literal `marked` tag.
enum NoteServiceMarkTagAction { add, remove }

/// One ordered host-side operation in the NoteService mark-toggle plan.
sealed class NoteServiceMarkEffect {
  const NoteServiceMarkEffect();
}

/// Changes the `marked` tag on a host-resolved note.
final class NoteServiceUpdateMarkTagEffect extends NoteServiceMarkEffect {
  const NoteServiceUpdateMarkTagEffect(this.action) : tag = 'marked', super();

  final NoteServiceMarkTagAction action;
  final String tag;
}

/// Persists the preceding tag change through the host's undoable update.
final class NoteServicePersistNoteUndoablyEffect extends NoteServiceMarkEffect {
  const NoteServicePersistNoteUndoablyEffect() : super();
}

/// Projects `NoteService.toggleMark(note)` from its host-resolved mark state.
///
/// The host reads the current state, applies the returned tag change to the
/// note, then runs the undoable update. Tag mutation and persistence are kept
/// outside the projection.
List<NoteServiceMarkEffect> planNoteServiceToggleMark({
  required bool isMarked,
}) => List.unmodifiable([
  NoteServiceUpdateMarkTagEffect(
    isMarked ? NoteServiceMarkTagAction.remove : NoteServiceMarkTagAction.add,
  ),
  const NoteServicePersistNoteUndoablyEffect(),
]);
