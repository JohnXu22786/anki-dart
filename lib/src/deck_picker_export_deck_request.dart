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
 * Source-derived from DeckPickerViewModel.kt:127,455–458 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:fixnum/fixnum.dart';

/// The host-facing request to export one deck from the Deck Picker.
final class DeckPickerExportDeckRequest {
  const DeckPickerExportDeckRequest({required this.deckId});

  /// Exact deck identity retained for host flow publication.
  final Int64 deckId;
}

/// Projects the source Deck Picker action to its host-facing request payload.
///
/// Uses [exactDeckId] whenever supplied. [legacyDeckId] is widened to `Int64`
/// only for callers that do not provide an exact ID.
/// The host owns flow publication, coroutine scheduling, and export execution.
DeckPickerExportDeckRequest projectDeckPickerExportDeck({
  required int legacyDeckId,
  Int64? exactDeckId,
}) => DeckPickerExportDeckRequest(deckId: exactDeckId ?? Int64(legacyDeckId));
