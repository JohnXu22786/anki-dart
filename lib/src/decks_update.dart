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
 * Source-derived from Deck.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Resolves a deck, applies [block], then saves that same deck.
///
/// The host supplies lookup and save operations because decks and collection
/// storage remain host-side. A null lookup result throws Dart's [TypeError]
/// through `!`, corresponding to Kotlin's `!!` null assertion. Lookup, block,
/// and save failures propagate in source order; a failure skips later steps.
void decksUpdate<TId, TDeck>({
  required TId deckId,
  required TDeck? Function(TId id) getLegacy,
  required void Function(TDeck deck) block,
  required void Function(TDeck deck) save,
}) {
  final deck = getLegacy(deckId)!;
  block(deck);
  save(deck);
}
