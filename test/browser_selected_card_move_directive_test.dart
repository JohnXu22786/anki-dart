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
 * Source-derived cases for CardBrowserViewModel.moveSelectedCardsToDeck();
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserSelectedCardsMove', () {
    test(
      'forwards the exact IDs and deck to one effect and returns host result',
      () {
        final ids = <int>[8, 3, 8, 5];
        final deckId = Object();
        final operationResult = Object();

        final directive = planBrowserSelectedCardsMove(
          selectedCardIds: ids,
          deckId: deckId,
        );

        expect(directive.selectedCardIds, same(ids));
        expect(directive.deckId, same(deckId));
        expect(directive.effects, hasLength(1));
        final effect = directive.effects.single as BrowserSetCardsDeckEffect;
        expect(effect.cardIds, same(ids));
        expect(effect.deckId, same(deckId));
        expect(
          completeBrowserSelectedCardsMove(operationResult),
          same(operationResult),
        );
      },
    );

    test('an empty resolved ID list still emits the setDeck effect', () {
      const ids = <int>[];
      final directive = planBrowserSelectedCardsMove(
        selectedCardIds: ids,
        deckId: 12,
      );

      expect(directive.selectedCardIds, same(ids));
      expect(directive.effects, hasLength(1));
      final effect = directive.effects.single as BrowserSetCardsDeckEffect;
      expect(effect.cardIds, same(ids));
      expect(effect.deckId, 12);
    });
  });
}
