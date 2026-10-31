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
 * Behavioral references: CardBrowserViewModel.kt, SearchFilters.kt, and
 * CardBrowserViewModelTest.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser all-decks projection', () {
    test('empty deck filters represent the initial all-decks state', () {
      expect(browserHasSelectedAllDecks(const BrowserSearchFilters()), isTrue);
    });

    test('any selected deck makes the projection false', () {
      final filters = BrowserSearchFilters(
        decks: [
          BrowserDeckNameId(name: 'Language::Spanish', id: 2),
          BrowserDeckNameId(name: 'Default', id: 1),
        ],
      );

      expect(browserHasSelectedAllDecks(filters), isFalse);
    });

    test('other filter categories do not affect the deck projection', () {
      final filters = BrowserSearchFilters(
        flags: [1],
        tags: ['marked'],
        noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: 3)],
        cardStateCodes: [0, 2],
      );

      expect(browserHasSelectedAllDecks(filters), isTrue);
    });
  });
}
