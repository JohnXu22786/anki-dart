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
 * Source-derived from Note.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Adapts `Note.cardIds(col)` while keeping Note and Collection host-side.
/// The exact card ID list and callback failures pass through unchanged.
List<int> libankiNoteCardIds({
  required int noteId,
  required List<int> Function({required int nid}) cardIdsOfNote,
}) => cardIdsOfNote(nid: noteId);

/// Adapts `Note.numberOfCards(col)` by delegating to card ID lookup once.
int libankiNoteNumberOfCards({
  required int noteId,
  required List<int> Function({required int nid}) cardIdsOfNote,
}) => libankiNoteCardIds(noteId: noteId, cardIdsOfNote: cardIdsOfNote).length;

/// Adapts `Note.cards(col)` with eager, ordered card lookups.
/// Lookup failures stop the mapping and propagate unchanged.
List<TCard> libankiNoteCards<TCard>({
  required int noteId,
  required List<int> Function({required int nid}) cardIdsOfNote,
  required TCard Function(int id) getCard,
}) => libankiNoteCardIds(
  noteId: noteId,
  cardIdsOfNote: cardIdsOfNote,
).map(getCard).toList();

/// Adapts `Note.firstCard(col)` using the source SQL and host query/card APIs.
TCard libankiNoteFirstCard<TCard>({
  required int noteId,
  required int Function(String query, int argument) queryLongScalar,
  required TCard Function(int id) getCard,
}) => getCard(
  queryLongScalar(
    'SELECT id FROM cards WHERE nid = ? ORDER BY ord LIMIT 1',
    noteId,
  ),
);
