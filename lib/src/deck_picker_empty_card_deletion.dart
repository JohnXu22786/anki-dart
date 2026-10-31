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
 * Behavioral reference: `deleteEmptyCards` in DeckPickerViewModel.kt,
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// The source note fields used by `deleteEmptyCards` for card-ID projection.
final class DeckPickerEmptyCardDeletionNote {
  const DeckPickerEmptyCardDeletionNote({
    required this.willDeleteNote,
    required this.cardIds,
  });

  final bool willDeleteNote;
  final List<int> cardIds;
}

/// The ordered notes in the host's empty-card deletion report.
final class DeckPickerEmptyCardDeletionReport {
  const DeckPickerEmptyCardDeletionReport(this.notes);

  final List<DeckPickerEmptyCardDeletionNote> notes;
}

/// Projects the card IDs passed to the host's undoable removal operation.
///
/// When preserving notes, the source keeps the first card for a note marked
/// for deletion. IDs remain in report order and are not deduplicated. The host
/// owns report creation, removal, orphan-note handling, undo, and result count.
List<int> deckPickerEmptyCardDeletionIds(
  DeckPickerEmptyCardDeletionReport report, {
  required bool preserveNotes,
}) => report.notes
    .expand(
      (note) => preserveNotes && note.willDeleteNote
          ? note.cardIds.skip(1)
          : note.cardIds,
    )
    .toList();
