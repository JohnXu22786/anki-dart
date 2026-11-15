/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from CardBrowserViewModel.kt:1514–1528 and its tests at
 * CardBrowserViewModelTest.kt:1535–1571 in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser search result message', () {
    test('non-user searches do not produce a result message', () {
      expect(
        browserSearchResultMessage(
          fromUserSearch: false,
          hasSelectedAllDecks: true,
          rowCount: 0,
        ),
        isNull,
      );
    });

    test('all-decks user searches omit the all-decks action', () {
      expect(
        browserSearchResultMessage(
          fromUserSearch: true,
          hasSelectedAllDecks: true,
          rowCount: 3,
        ),
        const BrowserSearchResultCardCount(includeSearchAllDecksAction: false),
      );
    });

    test('all-decks takes precedence over a zero row count', () {
      expect(
        browserSearchResultMessage(
          fromUserSearch: true,
          hasSelectedAllDecks: true,
          rowCount: 0,
        ),
        const BrowserSearchResultCardCount(includeSearchAllDecksAction: false),
      );
    });

    test('empty selected-deck user searches produce the no-cards message', () {
      expect(
        browserSearchResultMessage(
          fromUserSearch: true,
          hasSelectedAllDecks: false,
          rowCount: 0,
        ),
        isA<BrowserSearchResultNoCardsInSelectedDeck>(),
      );
    });

    test('selected-deck user searches with rows include the all-decks action',
        () {
      expect(
        browserSearchResultMessage(
          fromUserSearch: true,
          hasSelectedAllDecks: false,
          rowCount: 1,
        ),
        const BrowserSearchResultCardCount(includeSearchAllDecksAction: true),
      );
    });
  });
}
