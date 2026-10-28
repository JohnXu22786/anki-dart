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
 * Source-derived from DeckPickerViewModel.kt:389–428 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planDeckPickerReloadDeckCounts', () {
    test('preserves the source read and publication sequence', () {
      const currentMenuState = DeckPickerOptionsMenuState(
        searchIcon: true,
        undoLabel: 'Previous undo',
        syncIcon: DeckPickerSyncIconState.oneWay,
        undoAvailable: false,
        isColEmpty: false,
      );
      final initial = planDeckPickerReloadDeckCounts(
        dueTree: 'resolved due tree',
        collectionHasNoCards: false,
      );
      final studied = initial.afterStudiedToday('  3\n cards\r\n');
      final scheduler = studied.afterSchedulerVersion(
        schedulerVersion: 1,
        schedulerUpgradeDialogShownForVersion: null,
      );
      final focused = scheduler.afterFocusedDeck(42);
      final complete = focused.afterUndoMenuState(
        collectionAccessible: true,
        currentState: currentMenuState,
        undoLabel: 'Undo',
        undoAvailable: true,
      );

      expect(
        [
          ...initial.effects,
          ...studied.effects,
          ...scheduler.effects,
          ...focused.effects,
          ...complete.effects,
        ],
        const [
          DeckPickerReloadDeckCountsEffect.publishDueTree,
          DeckPickerReloadDeckCountsEffect.publishCollectionHasNoCards,
          DeckPickerReloadDeckCountsEffect.readStudiedToday,
          DeckPickerReloadDeckCountsEffect.publishStudiedToday,
          DeckPickerReloadDeckCountsEffect.readSchedulerVersion,
          DeckPickerReloadDeckCountsEffect.updateSchedulerUpgradeShownVersion,
          DeckPickerReloadDeckCountsEffect.emitSchedulerUpgradePrompt,
          DeckPickerReloadDeckCountsEffect.readFocusedDeck,
          DeckPickerReloadDeckCountsEffect.publishFocusedDeck,
          DeckPickerReloadDeckCountsEffect.readUndoMenuState,
          DeckPickerReloadDeckCountsEffect.refreshUndoMenu,
          DeckPickerReloadDeckCountsEffect.emitDecksReloaded,
        ],
      );
      expect(studied.studiedToday, '  3  cards\r ');
      expect(scheduler.schedulerUpgradePrompt.shouldShowPrompt, isTrue);
      expect(
        scheduler
            .schedulerUpgradePrompt
            .nextSchedulerUpgradeDialogShownForVersion,
        1,
      );
      expect(focused.focusedDeckId, 42);
      expect(complete.undoMenuRefresh.shouldUpdateState, isTrue);
      expect(
        complete.undoMenuRefresh.state,
        const DeckPickerOptionsMenuState(
          searchIcon: true,
          undoLabel: 'Undo',
          syncIcon: DeckPickerSyncIconState.oneWay,
          undoAvailable: true,
          isColEmpty: false,
        ),
      );
    });

    test(
      'omits the prompt effect when the scheduler projection does not request it',
      () {
        final initial = planDeckPickerReloadDeckCounts(
          dueTree: null,
          collectionHasNoCards: true,
        );
        final studied = initial.afterStudiedToday('today');
        final scheduler = studied.afterSchedulerVersion(
          schedulerVersion: 2,
          schedulerUpgradeDialogShownForVersion: null,
        );

        expect(scheduler.effects, const [
          DeckPickerReloadDeckCountsEffect.updateSchedulerUpgradeShownVersion,
          DeckPickerReloadDeckCountsEffect.readFocusedDeck,
        ]);
        expect(scheduler.schedulerUpgradePrompt.shouldShowPrompt, isFalse);
      },
    );

    test('replaces LF only and preserves CR and other whitespace', () {
      final initial = planDeckPickerReloadDeckCounts(
        dueTree: null,
        collectionHasNoCards: true,
      );
      final studied = initial.afterStudiedToday('\nA\r\nB\t\r C\n');

      expect(studied.studiedToday, ' A\r B\t\r C ');
    });
  });
}
