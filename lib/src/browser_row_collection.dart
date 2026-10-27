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
 * Behavioral reference: CardOrNoteId.kt, BrowserRowCollection.kt, and
 * CardBrowserViewModel.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';
import 'dart:collection';

import 'browser_column_collection.dart';

/// Resolves the note IDs represented by a list of card IDs.
///
/// The host supplies the collection-backed lookup; this package only preserves
/// how the browser passes IDs to it.
typedef BrowserNotesOfCards = FutureOr<List<int>> Function(List<int> cardIds);

/// Resolves all card IDs belonging to one note ID.
///
/// The host supplies the collection-backed lookup.
typedef BrowserCardIdsOfNote = FutureOr<List<int>> Function(int noteId);

/// The numeric ID stored by one Card Browser row.
///
/// Its meaning is determined by the associated [BrowserColumnMode].
final class BrowserRowId {
  const BrowserRowId(this.value);

  final int value;

  /// Selects the card or note identity used by a browser row.
  factory BrowserRowId.fromCard({
    required int cardId,
    required int noteId,
    required BrowserColumnMode mode,
  }) =>
      BrowserRowId(mode == BrowserColumnMode.cards ? cardId : noteId);

  /// Returns this ID as a card ID, resolving a note to its first card if needed.
  ///
  /// A note with no cards returns `null`, matching `firstOrNull` in the source.
  Future<int?> toCardId(
    BrowserColumnMode mode, {
    BrowserCardIdsOfNote? cardIdsOfNote,
  }) async {
    if (mode == BrowserColumnMode.cards) return value;
    final lookup = cardIdsOfNote;
    if (lookup == null) {
      throw StateError('cardIdsOfNote is required in Notes mode');
    }
    final cardIds = await lookup(value);
    return cardIds.isEmpty ? null : cardIds.first;
  }

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other) =>
      other is BrowserRowId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Returns the first position of [rowId] or `null` when it is not in [rowIds].
///
/// This matches `CardBrowserViewModel.getPositionOfId` and its
/// `indexOfOrNull` helper. [BrowserRowId] value equality supplies the source
/// ID comparison; duplicates resolve to their first occurrence.
int? browserRowPositionOfId({
  required List<BrowserRowId> rowIds,
  required BrowserRowId rowId,
}) {
  final position = rowIds.indexOf(rowId);
  return position >= 0 ? position : null;
}

/// IDs for rows in either Cards or Notes mode.
///
/// This list delegates its mutable operations to the supplied backing list,
/// matching AnkiDroid's `MutableList` delegation. Collection lookups remain
/// explicit host callbacks on the query methods.
final class BrowserRowCollection extends ListBase<BrowserRowId> {
  BrowserRowCollection(BrowserColumnMode mode, List<BrowserRowId> backingRows)
      : _mode = mode,
        _backingRows = backingRows;

  BrowserColumnMode _mode;
  final List<BrowserRowId> _backingRows;

  BrowserColumnMode get mode => _mode;

  @override
  int get length => _backingRows.length;

  @override
  set length(int newLength) => _backingRows.length = newLength;

  @override
  BrowserRowId operator [](int index) => _backingRows[index];

  @override
  void operator []=(int index, BrowserRowId value) {
    _backingRows[index] = value;
  }

  /// Changes the mode and replaces rows in the existing backing list.
  ///
  /// The mode is changed before the list is cleared. Passing [newRows] as the
  /// backing list itself therefore leaves the list empty, as in the source.
  void replaceWith(BrowserColumnMode mode, List<BrowserRowId> newRows) {
    _mode = mode;
    _backingRows.clear();
    _backingRows.addAll(newRows);
  }

  /// Clears rows without changing the current mode.
  void reset() => _backingRows.clear();

  /// Returns row note IDs directly in Notes mode, otherwise using [notesOfCards].
  Future<List<int>> queryNoteIds({BrowserNotesOfCards? notesOfCards}) async {
    final rowIds = _backingRows.map((row) => row.value).toList();
    if (_mode == BrowserColumnMode.notes) return rowIds;
    final lookup = notesOfCards;
    if (lookup == null) {
      throw StateError('notesOfCards is required in Cards mode');
    }
    return await lookup(rowIds);
  }

  /// Returns card IDs directly in Cards mode or expands note rows in order.
  ///
  /// Notes-mode IDs are snapshotted before the first asynchronous lookup, so a
  /// later mutation of the aliased row list does not change this query.
  Future<List<int>> queryCardIds({
    BrowserCardIdsOfNote? cardIdsOfNote,
  }) async {
    if (_mode == BrowserColumnMode.cards) {
      return _backingRows.map((row) => row.value).toList();
    }
    final noteIds = _backingRows.map((row) => row.value).toList();
    if (noteIds.isEmpty) return [];
    final lookup = cardIdsOfNote;
    if (lookup == null) {
      throw StateError('cardIdsOfNote is required in Notes mode');
    }
    final cardIds = <int>[];
    for (final noteId in noteIds) {
      cardIds.addAll(await lookup(noteId));
    }
    return cardIds;
  }

  /// Returns one first card ID per row in Notes mode.
  ///
  /// An empty card list raises Dart's `StateError`, corresponding to the
  /// source's failing `first()` call. Note IDs are snapshotted before the first
  /// asynchronous lookup, as in the source.
  Future<List<int>> queryOneCardIdPerRow({
    BrowserCardIdsOfNote? cardIdsOfNote,
  }) async {
    if (_mode == BrowserColumnMode.cards) {
      return _backingRows.map((row) => row.value).toList();
    }
    final noteIds = _backingRows.map((row) => row.value).toList();
    if (noteIds.isEmpty) return [];
    final lookup = cardIdsOfNote;
    if (lookup == null) {
      throw StateError('cardIdsOfNote is required in Notes mode');
    }
    final cardIds = <int>[];
    for (final noteId in noteIds) {
      cardIds.add((await lookup(noteId)).first);
    }
    return cardIds;
  }

  /// Resolves only the row at [position] to card IDs.
  Future<List<int>> queryCardIdsAt(
    int position, {
    BrowserCardIdsOfNote? cardIdsOfNote,
  }) async {
    final rowId = _backingRows[position].value;
    if (_mode == BrowserColumnMode.cards) return [rowId];
    final lookup = cardIdsOfNote;
    if (lookup == null) {
      throw StateError('cardIdsOfNote is required in Notes mode');
    }
    return await lookup(rowId);
  }
}
