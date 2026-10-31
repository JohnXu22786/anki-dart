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
 * Behavioral reference: DeckPickerViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('findDeckPosition', () {
    test('returns the first visible index for a visible deck', () {
      expect(
        findDeckPosition(
          flattenedDeckIds: [5, 8, 8, 13],
          deckId: 8,
          parentDeckId: (_) => null,
        ),
        1,
      );
    });

    test('returns the visible parent index for a collapsed child', () {
      expect(
        findDeckPosition(
          flattenedDeckIds: [2, 7, 9],
          deckId: 12,
          parentDeckId: (deckId) => deckId == 12 ? 7 : null,
        ),
        1,
      );
    });

    test('climbs a nested collapsed chain to its visible ancestor', () {
      expect(
        findDeckPosition(
          flattenedDeckIds: [2, 7, 9],
          deckId: 15,
          parentDeckId: (deckId) {
            if (deckId == 15) return 12;
            if (deckId == 12) return 7;
            return null;
          },
        ),
        1,
      );
    });

    test('returns zero for an unknown deck', () {
      expect(
        findDeckPosition(
          flattenedDeckIds: [2, 7, 9],
          deckId: 15,
          parentDeckId: (_) => null,
        ),
        0,
      );
    });

    test('returns zero for a root deck with no parent', () {
      expect(
        findDeckPosition(
          flattenedDeckIds: [2, 7, 9],
          deckId: 1,
          parentDeckId: (_) => null,
        ),
        0,
      );
    });
  });
}
