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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from DeckPickerViewModel.kt:215–222 and 482–498 in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

import 'shortcut_data.dart';

/// Projects `deleteSelectedDeck()`'s selected-deck lookup and delegation.
///
/// [deleteDeckAndJoin] represents launching `deleteDeck(deckId)` and joining
/// its Job. Kotlin `Job.join()` waits for completion without rethrowing the
/// joined Job's failure; the host owns that job behavior. This function does
/// not read or mutate collection state itself.
Future<void> deleteSelectedDeckPickerDeck({
  required FutureOr<int> Function() readSelectedDeckId,
  required FutureOr<void> Function(int deckId) deleteDeckAndJoin,
}) async {
  final deckId = await readSelectedDeckId();
  await deleteDeckAndJoin(deckId);
}

/// Resolves a deck name and emits the `ShortcutData` payload for `createIcon`.
///
/// The lookup completes before the basename is derived and the payload is
/// emitted. Collection access, IO scheduling, and Flow delivery remain with
/// the host; callback failures propagate and stop later work.
Future<void> createDeckPickerIcon({
  required int deckId,
  required FutureOr<String> Function(int deckId) readDeckName,
  required FutureOr<void> Function(ShortcutData value) emit,
}) async {
  final fullName = await readDeckName(deckId);
  await emit(ShortcutData(deckId, fullName));
}
