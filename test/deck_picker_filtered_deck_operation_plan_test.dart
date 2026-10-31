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
 * Source-derived DeckPicker cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('DeckPicker empty filtered-deck operation plan', () {
    test(
      'selects in collection, empties undoably by selected ID, then notifies',
      () {
        const deckId = 73;
        final plan = planDeckPickerEmptyFilteredDeck(deckId);

        expect(plan.steps, hasLength(3));
        final selectCollection = plan.steps[0] as DeckPickerWithCollection;
        expect(selectCollection.operations, hasLength(1));
        expect(
          (selectCollection.operations.single as DeckPickerSelectFilteredDeck)
              .deckId,
          deckId,
        );

        final undoable = plan.steps[1] as DeckPickerUndoableOperation;
        expect(undoable.operation, isA<DeckPickerEmptySelectedFilteredDeck>());
        expect(plan.steps[2], isA<DeckPickerPublishDeckCountsChanged>());
      },
    );
  });

  group('DeckPicker rebuild filtered-deck operation plan', () {
    test('selects and rebuilds in one collection operation, then notifies', () {
      const deckId = 91;
      final plan = planDeckPickerRebuildFilteredDeck(deckId);

      expect(plan.steps, hasLength(2));
      final collection = plan.steps.first as DeckPickerWithCollection;
      expect(collection.operations, hasLength(2));
      expect(
        (collection.operations[0] as DeckPickerSelectFilteredDeck).deckId,
        deckId,
      );
      expect(
        collection.operations[1],
        isA<DeckPickerRebuildSelectedFilteredDeck>(),
      );
      expect(plan.steps[1], isA<DeckPickerPublishDeckCountsChanged>());
    });
  });
}
