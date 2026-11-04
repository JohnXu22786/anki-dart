/*
 * Copyright © 2021 David Allison for the upstream aliases.
 * Copyright © 2026 John Tsui for the Dart adaptation.
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
 * SPDX-FileCopyrightText: 2021 David Allison (upstream aliases)
 * SPDX-FileCopyrightText: 2026 John Tsui (Dart adaptation)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from PythonTypes.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void _acceptsInt(int _) {}

void _compileTypeAssignments() {
  const DeckId deckId = 1428219222352;
  const EpochMilliseconds deckCreatedAt = deckId;
  const int deckIdAsInt = deckCreatedAt;

  const CardId cardId = 1;
  const DeckConfigId deckConfigId = 2;
  const NoteId noteId = 3;
  const NoteTypeId noteTypeId = 4;
  const EpochSeconds epochSeconds = 1707246949;
  const EpochMilliseconds epochMilliseconds = 1428219222352;

  _acceptsInt(deckIdAsInt);
  _acceptsInt(cardId);
  _acceptsInt(deckConfigId);
  _acceptsInt(noteId);
  _acceptsInt(noteTypeId);
  _acceptsInt(epochSeconds);
  _acceptsInt(epochMilliseconds);
}

void main() {
  test('public PythonTypes aliases compile as Dart int values', () {
    _compileTypeAssignments();
  });
}
