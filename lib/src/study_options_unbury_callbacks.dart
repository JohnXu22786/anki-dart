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
 * Source-derived from StudyOptionsViewModel.unbury() in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for Study Options' unbury action.
///
/// The host retains lifecycle scheduling, current-deck access, the scheduler,
/// undo execution, and operation results.
final class StudyOptionsUnburyCallbacks<TDeckId> {
  const StudyOptionsUnburyCallbacks({
    required this.currentDeckId,
    required this.unburyDeck,
    required this.undoableOp,
  });

  final TDeckId Function() currentDeckId;
  final Future<void> Function(TDeckId deckId) unburyDeck;
  final Future<void> Function(Future<void> Function() operation) undoableOp;

  /// Runs one unbury scheduler callback using the current deck within the
  /// host's undoable operation.
  ///
  /// The deck lookup happens when the host invokes the operation callback.
  /// Callback failures propagate unchanged; no collection refresh or scheduler
  /// result is exposed.
  Future<void> unbury() async {
    await undoableOp(() async {
      await unburyDeck(currentDeckId());
    });
  }
}
