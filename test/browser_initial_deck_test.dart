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
 * Source-derived from CardBrowserViewModel.kt:449–477 in AnkiDroid 2.25.3;
 * upstream direct assertions and gaps are recorded in ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void expectDeck(
  BrowserInitialDeckSelection actual, {
  required int id,
  required String name,
}) {
  expect(
    actual,
    isA<BrowserDeckSelection>()
        .having((deck) => deck.id, 'id', id)
        .having((deck) => deck.name, 'name', name),
  );
}

void main() {
  const allDecksId = 1;
  const current = BrowserDeckSelection(7, 'Current');
  const persisted = BrowserDeckSelection(8, 'Persisted');
  const intent = BrowserDeckSelection(9, 'From intent');

  group('Card Browser initial deck selection', () {
    test(
      'first launch is consumed even without a valid resolved intent deck',
      () {
        final plan = planBrowserInitialDeck(
          launchIntentConsumed: false,
          intentDeck: null,
          lastDeckId: 8,
          allDecksId: allDecksId,
          validLastDeck: persisted,
          currentSelectedDeck: current,
        );

        expect(plan.consumeLaunchIntent, isTrue);
        expectDeck(plan.selectedDeck, id: 8, name: 'Persisted');

        final alreadyConsumed = planBrowserInitialDeck(
          launchIntentConsumed: true,
          intentDeck: intent,
          lastDeckId: 8,
          allDecksId: allDecksId,
          validLastDeck: persisted,
          currentSelectedDeck: current,
        );
        expect(alreadyConsumed.consumeLaunchIntent, isFalse);
        expectDeck(alreadyConsumed.selectedDeck, id: 8, name: 'Persisted');
      },
    );

    test('valid launch deck takes precedence over every other candidate', () {
      final plan = planBrowserInitialDeck(
        launchIntentConsumed: false,
        intentDeck: intent,
        lastDeckId: allDecksId,
        allDecksId: allDecksId,
        validLastDeck: persisted,
        currentSelectedDeck: current,
      );

      expect(plan.consumeLaunchIntent, isTrue);
      expectDeck(plan.selectedDeck, id: 9, name: 'From intent');
    });

    test('all-decks sentinel takes precedence over a valid persisted deck', () {
      final plan = planBrowserInitialDeck(
        launchIntentConsumed: true,
        intentDeck: null,
        lastDeckId: allDecksId,
        allDecksId: allDecksId,
        validLastDeck: persisted,
        currentSelectedDeck: current,
      );

      expect(plan.selectedDeck, isA<BrowserAllDecksSelection>());
    });

    test(
      'valid persisted deck is selected and invalid persisted deck falls back',
      () {
        final valid = planBrowserInitialDeck(
          launchIntentConsumed: true,
          intentDeck: null,
          lastDeckId: 8,
          allDecksId: allDecksId,
          validLastDeck: persisted,
          currentSelectedDeck: current,
        );
        final invalid = planBrowserInitialDeck(
          launchIntentConsumed: true,
          intentDeck: null,
          lastDeckId: 404,
          allDecksId: allDecksId,
          validLastDeck: null,
          currentSelectedDeck: current,
        );

        expectDeck(valid.selectedDeck, id: 8, name: 'Persisted');
        expectDeck(invalid.selectedDeck, id: 7, name: 'Current');
      },
    );

    test(
      'host selected deck is the fallback when no persisted deck is present',
      () {
        final plan = planBrowserInitialDeck(
          launchIntentConsumed: true,
          intentDeck: null,
          lastDeckId: null,
          allDecksId: allDecksId,
          validLastDeck: null,
          currentSelectedDeck: current,
        );

        expectDeck(plan.selectedDeck, id: 7, name: 'Current');
      },
    );
  });
}
