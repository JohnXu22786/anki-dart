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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserRepositionCards', () {
    test('partitions in source order and counts skipped cards exactly', () {
      final plan = planBrowserRepositionCards(
        selectedCards: const [
          BrowserRepositionCardState(
            cardId: 8,
            hasNewType: false,
            hasNewQueue: false,
          ),
          BrowserRepositionCardState(
            cardId: 4,
            hasNewType: true,
            hasNewQueue: false,
          ),
          BrowserRepositionCardState(
            cardId: 12,
            hasNewType: false,
            hasNewQueue: false,
          ),
          BrowserRepositionCardState(
            cardId: 2,
            hasNewType: false,
            hasNewQueue: true,
          ),
        ],
      );

      expect(plan, isA<BrowserRepositionCards>());
      final result = plan as BrowserRepositionCards;
      expect(result.repositionableCardIds, [4, 2]);
      expect(result.skippedCardIds, [8, 12]);
      expect(result.unsupportedCardCount, 2);
    });

    test('a New queue qualifies even when card type is not New', () {
      final plan = planBrowserRepositionCards(
        selectedCards: const [
          BrowserRepositionCardState(
            cardId: 5,
            hasNewType: false,
            hasNewQueue: true,
          ),
        ],
      );

      expect(plan, isA<BrowserRepositionCards>());
      expect((plan as BrowserRepositionCards).repositionableCardIds, [5]);
    });

    test('all eligible cards produce an exact zero skipped count', () {
      final plan = planBrowserRepositionCards(
        selectedCards: const [
          BrowserRepositionCardState(
            cardId: 3,
            hasNewType: true,
            hasNewQueue: false,
          ),
          BrowserRepositionCardState(
            cardId: 6,
            hasNewType: false,
            hasNewQueue: true,
          ),
        ],
      );

      expect(plan, isA<BrowserRepositionCards>());
      final result = plan as BrowserRepositionCards;
      expect(result.repositionableCardIds, [3, 6]);
      expect(result.skippedCardIds, isEmpty);
      expect(result.unsupportedCardCount, 0);
    });

    test('all ineligible cards return the error despite skipped IDs', () {
      expect(
        planBrowserRepositionCards(
          selectedCards: const [
            BrowserRepositionCardState(
              cardId: 3,
              hasNewType: false,
              hasNewQueue: false,
            ),
            BrowserRepositionCardState(
              cardId: 6,
              hasNewType: false,
              hasNewQueue: false,
            ),
          ],
        ),
        isA<BrowserNoRepositionableCards>(),
      );
    });

    test('empty selection returns the source error', () {
      expect(
        planBrowserRepositionCards(selectedCards: const []),
        isA<BrowserNoRepositionableCards>(),
      );
    });
  });
}
