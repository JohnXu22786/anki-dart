/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This file is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from StudyOptionsViewModel.rebuildCram() and emptyCram() in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for filtered-deck rebuild and empty actions in Study Options.
///
/// The host retains logging, selected-deck access, scheduler calls, undoable
/// operation execution, collection access, and collection-derived state updates.
final class StudyOptionsFilteredDeckActions<TDecks> {
  const StudyOptionsFilteredDeckActions({
    required this.logDiagnostic,
    required this.selectedDecks,
    required this.rebuildFilteredDeck,
    required this.emptyFilteredDeck,
    required this.undoableOp,
    required this.withCol,
    required this.updateStateFromCollection,
  });

  final void Function(String message) logDiagnostic;
  final TDecks Function() selectedDecks;
  final Future<void> Function(TDecks decks) rebuildFilteredDeck;
  final Future<void> Function(TDecks decks) emptyFilteredDeck;
  final Future<void> Function(Future<void> Function() operation) undoableOp;
  final Future<void> Function(Future<void> Function() operation) withCol;
  final Future<void> Function() updateStateFromCollection;

  /// Rebuilds the selected filtered deck, then refreshes collection state.
  ///
  /// The scheduler call runs once inside the host undoable operation and reads
  /// the host's selected-decks value there. The refresh runs only after that
  /// operation succeeds. Callback failures propagate unchanged.
  Future<void> rebuildCram() async {
    logDiagnostic('doInBackground - RebuildCram');
    await undoableOp(() async {
      await rebuildFilteredDeck(selectedDecks());
    });
    await withCol(updateStateFromCollection);
  }

  /// Empties the selected filtered deck, then refreshes collection state.
  ///
  /// The scheduler call runs once inside the host undoable operation and reads
  /// the host's selected-decks value there. The refresh runs only after that
  /// operation succeeds. Callback failures propagate unchanged.
  Future<void> emptyCram() async {
    logDiagnostic('doInBackgroundEmptyCram');
    await undoableOp(() async {
      await emptyFilteredDeck(selectedDecks());
    });
    await withCol(updateStateFromCollection);
  }
}
