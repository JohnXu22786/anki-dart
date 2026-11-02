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
 * Source-derived from DeckPickerViewModel.kt:627–656 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planDeckPickerOptionsMenuRefresh', () {
    test(
      'inaccessible collection clears menu state without fetching sync icon',
      () {
        final plan = planDeckPickerOptionsMenuRefresh(
          collectionAccessible: false,
          deckCount: 0,
          isEmpty: true,
          undoLabel: null,
          undoAvailable: false,
        );

        expect(plan.placeholderState, isNull);
        expect(plan.shouldFetchSyncIcon, isFalse);
      },
    );

    test(
      'builds the source placeholder before projecting fetched sync state',
      () {
        final plan = planDeckPickerOptionsMenuRefresh(
          collectionAccessible: true,
          deckCount: 10,
          isEmpty: true,
          undoLabel: 'Undo',
          undoAvailable: true,
        );
        final initial = plan.placeholderState!;

        expect(plan.shouldFetchSyncIcon, isTrue);
        expect(initial.searchIcon, isTrue);
        expect(initial.undoLabel, 'Undo');
        expect(initial.syncIcon, DeckPickerSyncIconState.normal);
        expect(initial.undoAvailable, isTrue);
        expect(initial.isColEmpty, isFalse);
        expect(
          completeDeckPickerOptionsMenuRefresh(
            plan,
            DeckPickerSyncIconState.oneWay,
          ),
          DeckPickerOptionsMenuState(
            searchIcon: true,
            undoLabel: 'Undo',
            syncIcon: DeckPickerSyncIconState.oneWay,
            undoAvailable: true,
            isColEmpty: false,
          ),
        );
      },
    );

    test(
      'search icon threshold and empty-collection formula match the source',
      () {
        final underThreshold = planDeckPickerOptionsMenuRefresh(
          collectionAccessible: true,
          deckCount: 9,
          isEmpty: true,
          undoLabel: null,
          undoAvailable: false,
        );
        final exactlyOneEmptyDeck = planDeckPickerOptionsMenuRefresh(
          collectionAccessible: true,
          deckCount: 1,
          isEmpty: true,
          undoLabel: null,
          undoAvailable: false,
        );
        final nonEmptyCollection = planDeckPickerOptionsMenuRefresh(
          collectionAccessible: true,
          deckCount: 1,
          isEmpty: false,
          undoLabel: null,
          undoAvailable: false,
        );

        expect(underThreshold.placeholderState!.searchIcon, isFalse);
        expect(underThreshold.placeholderState!.isColEmpty, isFalse);
        expect(exactlyOneEmptyDeck.placeholderState!.isColEmpty, isTrue);
        expect(nonEmptyCollection.placeholderState!.isColEmpty, isFalse);
      },
    );
  });

  group('planDeckPickerUndoMenuRefresh', () {
    test(
      'copies only undo fields while preserving all other current fields',
      () {
        const current = DeckPickerOptionsMenuState(
          searchIcon: true,
          undoLabel: 'Old undo',
          syncIcon: DeckPickerSyncIconState.pendingChanges,
          undoAvailable: false,
          isColEmpty: true,
        );
        final plan = planDeckPickerUndoMenuRefresh(
          collectionAccessible: true,
          currentState: current,
          undoLabel: null,
          undoAvailable: true,
        );

        expect(plan.shouldUpdateState, isTrue);
        expect(
          plan.state,
          const DeckPickerOptionsMenuState(
            searchIcon: true,
            undoLabel: null,
            syncIcon: DeckPickerSyncIconState.pendingChanges,
            undoAvailable: true,
            isColEmpty: true,
          ),
        );
      },
    );

    test(
      'does not update when collection is inaccessible and preserves null state',
      () {
        const current = DeckPickerOptionsMenuState(
          searchIcon: false,
          undoLabel: null,
          syncIcon: DeckPickerSyncIconState.normal,
          undoAvailable: false,
          isColEmpty: false,
        );

        final inaccessible = planDeckPickerUndoMenuRefresh(
          collectionAccessible: false,
          currentState: current,
          undoLabel: 'Undo',
          undoAvailable: true,
        );
        final nullState = planDeckPickerUndoMenuRefresh(
          collectionAccessible: true,
          currentState: null,
          undoLabel: 'Undo',
          undoAvailable: true,
        );

        expect(inaccessible.shouldUpdateState, isFalse);
        expect(inaccessible.state, current);
        expect(nullState.shouldUpdateState, isTrue);
        expect(nullState.state, isNull);
      },
    );
  });
}
