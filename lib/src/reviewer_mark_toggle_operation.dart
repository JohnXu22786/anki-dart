/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

/// Runs Reviewer's mark toggle through host-supplied callbacks.
///
/// The operation resolves one current card and its note, toggles that note,
/// reads its marked state after the toggle succeeds, and publishes the returned
/// state after the read succeeds. Callback failures propagate unchanged and
/// stop later callbacks. Current-card and collection access, NoteService
/// mutation, coroutine scheduling, and StateFlow delivery remain host-side.
Future<void> executeReviewerMarkToggleOperation<TCard, TNote>({
  required FutureOr<TCard> Function() currentCard,
  required FutureOr<TNote> Function(TCard card) noteForCard,
  required FutureOr<void> Function(TNote note) toggleMark,
  required FutureOr<bool> Function(TNote note) isMarked,
  required FutureOr<void> Function(bool isMarked) publishMarkState,
}) async {
  final card = await currentCard();
  final note = await noteForCard(card);
  await toggleMark(note);
  final marked = await isMarked(note);
  await publishMarkState(marked);
}
