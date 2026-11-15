/*
 * Copyright (c) 2009 Daniel Svärd <daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold norbert.nagold@gmail.com
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'card_utils.dart';
import 'libanki_deck_config.dart';

/// Reads the card's deck time limit in milliseconds from its current deck.
///
/// The host supplies card deck IDs and the deck-config lookup. A nonzero
/// [oDid] selects the original deck for a filtered card. Multiplication keeps
/// Kotlin's signed 32-bit `Int` overflow behavior.
int cardTimeLimit({
  required int oDid,
  required int did,
  required LibAnkiDeckConfig Function(int deckId) configForDeckId,
}) => (configForDeckId(getDeckIdForCard(oDid: oDid, did: did)).maxTaken * 1000)
    .toSigned(32);

/// Returns the timer setting for the card's current deck.
///
/// The existing [LibAnkiDeckConfig.timer] getter retains JSON fallback,
/// logging, and error behavior.
bool cardShouldShowTimer({
  required int oDid,
  required int did,
  required LibAnkiDeckConfig Function(int deckId) configForDeckId,
}) => configForDeckId(getDeckIdForCard(oDid: oDid, did: did)).timer;

/// Returns whether to replay question audio on the answer side for this deck.
bool cardReplayQuestionAudioOnAnswerSide({
  required int oDid,
  required int did,
  required LibAnkiDeckConfig Function(int deckId) configForDeckId,
}) => configForDeckId(getDeckIdForCard(oDid: oDid, did: did)).replayq;

/// Returns the autoplay setting for the card's current deck.
bool cardAutoplay({
  required int oDid,
  required int did,
  required LibAnkiDeckConfig Function(int deckId) configForDeckId,
}) => configForDeckId(getDeckIdForCard(oDid: oDid, did: did)).autoplay;
