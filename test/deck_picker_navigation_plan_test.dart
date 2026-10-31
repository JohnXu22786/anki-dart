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
 * Source-derived DeckPicker navigation cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('DeckPicker browse navigation plan', () {
    test('selects the supplied deck before browsing that same deck', () {
      const deckId = 73;
      final plan = planDeckPickerBrowseCards(deckId);

      expect(plan.steps, hasLength(2));
      final select = plan.steps[0] as DeckPickerSelectForNavigation;
      final navigate = plan.steps[1] as DeckPickerNavigateToBrowser;
      expect(select.deckId, deckId);
      expect(navigate.deckId, deckId);
    });
  });

  group('DeckPicker add-note navigation plan', () {
    test('selects only a non-null deck when requested, then keeps the ID', () {
      for (final deckId in [0, 24]) {
        final plan = planDeckPickerAddNote(deckId: deckId, setAsCurrent: true);

        expect(plan.steps, hasLength(2));
        expect(
          (plan.steps[0] as DeckPickerSelectForNavigation).deckId,
          deckId,
        );
        expect(
          (plan.steps[1] as DeckPickerNavigateToAddNote).deckId,
          deckId,
        );
      }
    });

    test('skips selection when setAsCurrent is false but retains deck ID', () {
      final plan = planDeckPickerAddNote(deckId: 24, setAsCurrent: false);

      expect(plan.steps, hasLength(1));
      expect((plan.steps.single as DeckPickerNavigateToAddNote).deckId, 24);
    });

    test(
      'null deck ID skips selection and stays null in navigation payload',
      () {
        final plan = planDeckPickerAddNote(deckId: null, setAsCurrent: true);

        expect(plan.steps, hasLength(1));
        expect(
          (plan.steps.single as DeckPickerNavigateToAddNote).deckId,
          isNull,
        );
      },
    );
  });

  group('DeckPicker deck-options navigation plan', () {
    test('uses either supplied filtered value without a collection lookup', () {
      for (final isFiltered in [false, true]) {
        final plan = planDeckPickerOpenDeckOptions(
          deckId: 58,
          isFiltered: isFiltered,
        );

        expect(plan.steps, hasLength(1));
        final navigate = plan.steps.single as DeckPickerNavigateToDeckOptions;
        expect(navigate.deckId, 58);
        final filteredState =
            navigate.filteredState as DeckPickerUseFilteredState;
        expect(filteredState.isFiltered, isFiltered);
      }
    });

    test('requests host filtered-state lookup only when the value is null', () {
      final plan = planDeckPickerOpenDeckOptions(deckId: 58);

      expect(plan.steps, hasLength(1));
      final navigate = plan.steps.single as DeckPickerNavigateToDeckOptions;
      expect(navigate.deckId, 58);
      final filteredState = navigate.filteredState
          as DeckPickerResolveFilteredStateFromCollection;
      expect(filteredState.deckId, 58);
    });
  });
}
