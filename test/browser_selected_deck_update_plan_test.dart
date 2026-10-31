/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
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
 * Source-derived cases for CardBrowserViewModel.setSelectedDeck(); see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserSelectedDeckUpdate', () {
    test(
      'AllDecks persists the sentinel before requesting an empty deck filter',
      () {
        final noteType = BrowserNoteTypeNameId(name: 'Basic', id: 5);
        final currentRequest = BrowserSearchRequest(
          query: '  keep exact query\n',
          filters: BrowserSearchFilters(
            decks: [const BrowserDeckNameId(name: 'Old', id: 8)],
            flags: [1, 4],
            tags: ['marked'],
            noteTypes: [noteType],
            cardStateCodes: [0, 3],
          ),
        );

        final plan = planBrowserSelectedDeckUpdate(
          selectedDeck: const BrowserSelectAllDecks(),
          allDecksId: -1,
          currentRequest: currentRequest,
        );

        expect(plan.lastDeckId, -1);
        expect(plan.deckFilter, isEmpty);
        expect(plan.updatedRequest.query, currentRequest.query);
        expect(plan.updatedRequest.filters.decks, isEmpty);
        expect(plan.updatedRequest.filters.flags, currentRequest.filters.flags);
        expect(plan.updatedRequest.filters.tags, currentRequest.filters.tags);
        expect(
          plan.updatedRequest.filters.noteTypes,
          same(currentRequest.filters.noteTypes),
        );
        expect(
          plan.updatedRequest.filters.cardStateCodes,
          currentRequest.filters.cardStateCodes,
        );
        expect(plan.effects, hasLength(2));
        expect(plan.effects.first, isA<BrowserPersistLastDeckIdEffect>());
        expect(
          (plan.effects.first as BrowserPersistLastDeckIdEffect).deckId,
          -1,
        );
        final search =
            plan.effects.last as BrowserLaunchSelectedDeckSearchEffect;
        expect(search.request, same(plan.updatedRequest));
        expect(search.forceRefresh, isFalse);
      },
    );

    test('specific deck retains its exact ID and resolved DeckNameId', () {
      final selectedDeck = BrowserSelectSpecificDeck(
        id: 42,
        deckNameId: const BrowserDeckNameId(name: 'Resolved::Name', id: 42),
      );
      final currentFilters = BrowserSearchFilters(
        flags: [2],
        tags: ['keep'],
        noteTypes: [BrowserNoteTypeNameId(name: 'Cloze', id: 7)],
        cardStateCodes: [1],
      );
      final currentRequest = BrowserSearchRequest(
        query: 'unchanged',
        filters: currentFilters,
      );

      final plan = planBrowserSelectedDeckUpdate(
        selectedDeck: selectedDeck,
        allDecksId: -1,
        currentRequest: currentRequest,
      );

      expect(plan.lastDeckId, 42);
      expect(plan.deckFilter, [selectedDeck.deckNameId]);
      expect(plan.deckFilter.single, same(selectedDeck.deckNameId));
      expect(plan.updatedRequest.query, currentRequest.query);
      expect(plan.updatedRequest.filters.decks, [selectedDeck.deckNameId]);
      expect(plan.updatedRequest.filters.flags, same(currentFilters.flags));
      expect(plan.updatedRequest.filters.tags, same(currentFilters.tags));
      expect(
        plan.updatedRequest.filters.noteTypes,
        same(currentFilters.noteTypes),
      );
      expect(
        plan.updatedRequest.filters.cardStateCodes,
        same(currentFilters.cardStateCodes),
      );
      expect(plan.effects.map((effect) => effect.runtimeType), [
        BrowserPersistLastDeckIdEffect,
        BrowserLaunchSelectedDeckSearchEffect,
      ]);
      expect((plan.effects.first as BrowserPersistLastDeckIdEffect).deckId, 42);
      final search = plan.effects.last as BrowserLaunchSelectedDeckSearchEffect;
      expect(search.request, same(plan.updatedRequest));
      expect(search.forceRefresh, isFalse);
    });
  });
}
