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
 * Source-derived from AddEditReminderDialogViewModel.kt, ReviewReminder.kt,
 * and AddEditReminderDialog.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Review reminder form state', () {
    const allDecksId = -1;
    const defaultDeckId = 1;
    final now = ReviewReminderTime(hour: 9, minute: 30);

    test(
      'Add initializes source defaults and projects host-selected scope',
      () {
        final global = ReviewReminderFormState.add(
          currentTime: now,
          scope: const GlobalReminderScope(),
          allDecksId: allDecksId,
        );

        expect(global.time, now);
        expect(global.deckSelected, allDecksId);
        expect(global.cardTriggerThreshold, 1);
        expect(global.onlyNotifyIfNoReviews, isFalse);
        expect(global.advancedSettingsOpen, isFalse);
        expect(
          global.outputStateAsReminder(
            currentTime: ReviewReminderTime(hour: 10, minute: 0),
            allDecksId: allDecksId,
            defaultDeckId: defaultDeckId,
          ),
          isA<ReviewReminderProjection>()
              .having((r) => r.scope, 'scope', isA<GlobalReminderScope>())
              .having((r) => r.enabled, 'enabled', isTrue),
        );

        final deck = ReviewReminderFormState.add(
          currentTime: now,
          scope: const DeckSpecificReminderScope(42),
          allDecksId: allDecksId,
        );
        expect(deck.deckSelected, 42);
        expect(
          deck
              .outputStateAsReminder(
                currentTime: now,
                allDecksId: allDecksId,
                defaultDeckId: defaultDeckId,
              )
              .scope,
          const DeckSpecificReminderScope(42),
        );
      },
    );

    test('time values reject source-invalid hours and minutes at runtime', () {
      expect(
        () => ReviewReminderTime(hour: -1, minute: 0),
        throwsArgumentError,
      );
      expect(
        () => ReviewReminderTime(hour: 24, minute: 0),
        throwsArgumentError,
      );
      expect(
        () => ReviewReminderTime(hour: 0, minute: -1),
        throwsArgumentError,
      );
      expect(
        () => ReviewReminderTime(hour: 0, minute: 60),
        throwsArgumentError,
      );
    });

    test('Edit copies reminder fields and preserves enabled in output', () {
      final existing = ReviewReminderProjection(
        time: ReviewReminderTime(hour: 6, minute: 15),
        cardTriggerThreshold: 4,
        scope: DeckSpecificReminderScope(73),
        enabled: false,
        onlyNotifyIfNoReviews: true,
      );
      final state = ReviewReminderFormState.edit(
        reminder: existing,
        allDecksId: allDecksId,
      );

      expect(state.time, existing.time);
      expect(state.deckSelected, 73);
      expect(state.cardTriggerThreshold, 4);
      expect(state.onlyNotifyIfNoReviews, isTrue);
      expect(state.advancedSettingsOpen, isFalse);
      final output = state.outputStateAsReminder(
        currentTime: now,
        allDecksId: allDecksId,
        defaultDeckId: defaultDeckId,
      );
      expect(output.enabled, isFalse);
      expect(output.time, existing.time);
      expect(output.cardTriggerThreshold, 4);
      expect(output.onlyNotifyIfNoReviews, isTrue);
    });

    test(
      'setters, toggle fallbacks, and output null defaults match source',
      () {
        final state = ReviewReminderFormState.add(
          currentTime: now,
          scope: const DeckSpecificReminderScope(4),
          allDecksId: allDecksId,
        );
        state.setTime(ReviewReminderTime(hour: 22, minute: 7));
        state.setDeckSelected(55);
        state.setCardTriggerThreshold(-2);
        expect(state.time, ReviewReminderTime(hour: 22, minute: 7));
        expect(state.deckSelected, 55);
        expect(state.cardTriggerThreshold, -2);
        state.onlyNotifyIfNoReviews = null;
        state.toggleOnlyNotifyIfNoReviews();
        expect(state.onlyNotifyIfNoReviews, isTrue);
        state.advancedSettingsOpen = null;
        state.toggleAdvancedSettingsOpen();
        expect(state.advancedSettingsOpen, isTrue);
        state.cardTriggerThreshold = 0;
        expect(
          state
              .outputStateAsReminder(
                currentTime: now,
                allDecksId: allDecksId,
                defaultDeckId: defaultDeckId,
              )
              .scope,
          const DeckSpecificReminderScope(55),
        );
        state.cardTriggerThreshold = -2;
        expect(
          () => state.outputStateAsReminder(
            currentTime: now,
            allDecksId: allDecksId,
            defaultDeckId: defaultDeckId,
          ),
          throwsArgumentError,
        );
        state.cardTriggerThreshold = 0;
        expect(
          state
              .outputStateAsReminder(
                currentTime: now,
                allDecksId: allDecksId,
                defaultDeckId: defaultDeckId,
              )
              .cardTriggerThreshold,
          0,
        );

        state.time = null;
        state.cardTriggerThreshold = null;
        state.deckSelected = null;
        state.onlyNotifyIfNoReviews = null;
        final output = state.outputStateAsReminder(
          currentTime: ReviewReminderTime(hour: 17, minute: 2),
          allDecksId: allDecksId,
          defaultDeckId: defaultDeckId,
        );
        expect(output.time, ReviewReminderTime(hour: 17, minute: 2));
        expect(output.cardTriggerThreshold, 1);
        expect(output.scope, const DeckSpecificReminderScope(defaultDeckId));
        expect(output.enabled, isTrue);
        expect(output.onlyNotifyIfNoReviews, isFalse);

        expect(
          () =>
              ReviewReminderFormState.add(
                  currentTime: now,
                  scope: const DeckSpecificReminderScope(4),
                  allDecksId: allDecksId,
                )
                ..cardTriggerThreshold = -2
                ..outputStateAsReminder(
                  currentTime: now,
                  allDecksId: allDecksId,
                  defaultDeckId: defaultDeckId,
                ),
          throwsArgumentError,
        );
      },
    );
  });
}
