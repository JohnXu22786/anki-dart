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
 * Source-derived from CustomStudyViewModel.kt and CustomStudyDialog.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// The portable CramKind values used by AnkiDroid's Custom Study choices.
enum CustomStudyCramKind {
  CRAM_KIND_NEW,
  CRAM_KIND_DUE,
  CRAM_KIND_REVIEW,
  CRAM_KIND_ALL,
}

/// Custom Study card-state choices in the source spinner's order.
enum CustomStudyCardState {
  NewCardsOnly(CustomStudyCramKind.CRAM_KIND_NEW),
  DueCardsOnly(CustomStudyCramKind.CRAM_KIND_DUE),
  ReviewCardsRandom(CustomStudyCramKind.CRAM_KIND_REVIEW),
  AllCardsRandom(CustomStudyCramKind.CRAM_KIND_ALL);

  const CustomStudyCardState(this.kind);

  final CustomStudyCramKind kind;
}

/// Projects the selected source spinner index to its scheduler kind.
///
/// The host owns the persisted selection index and Android spinner. Exactly
/// `-1` is the source's invalid-position default; other values are indexed
/// directly, preserving the source's out-of-range failure.
CustomStudyCramKind projectCustomStudySelectedKind(int selectedCardStateIndex) {
  if (selectedCardStateIndex == -1) {
    return CustomStudyCramKind.CRAM_KIND_NEW;
  }
  return CustomStudyCardState.values[selectedCardStateIndex].kind;
}
