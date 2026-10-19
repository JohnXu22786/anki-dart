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
 * Behavioral reference: `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/
 * CardBrowserSearchViewModel.kt`, methods `submitSavedSearch`, `syncState`, and
 * `resetSearchState`. The pinned source marks reset as `@NeedsTest("reset")`;
 * no direct upstream test covers sync/reset. Direct tests cover saved-search
 * results but not the internal effect order. See ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser search state effects', () {
    test('sync updates System filters before submitting the exact request', () {
      const filters = BrowserSearchFilters(
        decks: [BrowserDeckNameId(name: 'Languages', id: 7)],
        flags: [1, 4],
        tags: ['tag'],
        noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: 3)],
        cardStateCodes: [0, 2],
      );
      const request = BrowserSearchRequest(
        query: '  raw\n query  ',
        filters: filters,
      );

      final effects = browserSyncStateEffects(request);

      expect(
        effects.map((effect) => effect.runtimeType),
        [BrowserFilterUpdateEffect, BrowserSearchSubmittedEffect],
      );
      final filterEffect = effects[0] as BrowserFilterUpdateEffect;
      expect(filterEffect.update, isA<BrowserFilterUpdateSystem>());
      expect(identical(filterEffect.update.state, filters), isTrue);
      final submitEffect = effects[1] as BrowserSearchSubmittedEffect;
      expect(identical(submitEffect.search, request), isTrue);
      expect(submitEffect.search.query, '  raw\n query  ');

      const textState = BrowserSearchTextState(
        isAdvancedSearch: true,
        basicText: 'basic buffer',
        advancedText: 'advanced buffer',
      );
      final unchanged = effects.fold(
        textState,
        browserSearchTextStateAfterEffect,
      );
      expect(unchanged.isAdvancedSearch, textState.isAdvancedSearch);
      expect(unchanged.basicText, textState.basicText);
      expect(unchanged.advancedText, textState.advancedText);
    });

    test('sync emits no text, screen, history, or saved-state effects', () {
      const request = BrowserSearchRequest(query: 'sync');

      final effects = browserSyncStateEffects(request);

      expect(effects, hasLength(2));
      expect(
        effects.every(
          (effect) =>
              effect is BrowserFilterUpdateEffect ||
              effect is BrowserSearchSubmittedEffect,
        ),
        isTrue,
      );
    });

    test('reset effects preserve exact values and source order', () {
      const filters = BrowserSearchFilters(
        flags: [3],
        tags: ['reset-tag'],
        cardStateCodes: [4],
      );
      const request = BrowserSearchRequest(
        query: ' \tuntouched\nquery \r ',
        filters: filters,
      );

      final effects = browserResetSearchStateEffects(request);

      expect(
        effects.map((effect) => effect.runtimeType),
        [
          BrowserAdvancedSearchModeEffect,
          BrowserBasicSearchTextEffect,
          BrowserAdvancedSearchTextEffect,
          BrowserFilterUpdateEffect,
          BrowserSearchScreenOpenEffect,
          BrowserSavedStateKeyRemovalEffect,
          BrowserSavedStateKeyRemovalEffect,
          BrowserSavedStateKeyRemovalEffect,
        ],
      );
      expect((effects[0] as BrowserAdvancedSearchModeEffect).enabled, isFalse);
      expect((effects[1] as BrowserBasicSearchTextEffect).text, request.query);
      expect(
          (effects[2] as BrowserAdvancedSearchTextEffect).text, request.query);
      final filterEffect = effects[3] as BrowserFilterUpdateEffect;
      expect(filterEffect.update, isA<BrowserFilterUpdateSystem>());
      expect(identical(filterEffect.update.state, filters), isTrue);
      expect((effects[4] as BrowserSearchScreenOpenEffect).isOpen, isFalse);

      final textAfterReset = effects.fold(
        const BrowserSearchTextState(
          isAdvancedSearch: true,
          basicText: 'old basic',
          advancedText: 'old advanced',
        ),
        browserSearchTextStateAfterEffect,
      );
      expect(textAfterReset.isAdvancedSearch, isFalse);
      expect(textAfterReset.basicText, request.query);
      expect(textAfterReset.advancedText, request.query);
    });

    test('reset removes only the three source keys in order', () {
      final effects = browserResetSearchStateEffects(
        const BrowserSearchRequest(query: 'query'),
      );
      final removedKeys = effects
          .whereType<BrowserSavedStateKeyRemovalEffect>()
          .map((effect) => effect.key)
          .toList();

      expect(
        removedKeys,
        [
          browserAdvancedSearchStateKey,
          browserBasicSearchTextStateKey,
          browserAdvancedSearchTextStateKey,
        ],
      );
      expect(removedKeys, isNot(contains('historyExpanded')));
    });

    group('submitSavedSearch', () {
      test('edits Basic text before closing and preserves the query value', () {
        final filters = BrowserSearchFilters(
          decks: [const BrowserDeckNameId(name: 'Deck', id: 4)],
          flags: [1],
          tags: ['tag'],
          noteTypes: [const BrowserNoteTypeNameId(name: 'Basic', id: 2)],
          cardStateCodes: [3],
        );
        const textState = BrowserSearchTextState(
          isAdvancedSearch: false,
          basicText: 'old basic',
          advancedText: 'keep advanced',
        );
        const savedSearch = BrowserSavedSearch(
          name: 'saved',
          query: '  sample\nquery \r\nend  ',
        );

        final effects = browserSubmitSavedSearchEffects(
          savedSearch,
          currentFilters: filters,
          textState: textState,
        );

        expect(
          effects.map((effect) => effect.runtimeType),
          [
            BrowserFilterUpdateEffect,
            BrowserBasicSearchTextEffect,
            BrowserSearchScreenOpenEffect,
          ],
        );
        final update = (effects[0] as BrowserFilterUpdateEffect).update;
        expect(update, isA<BrowserFilterUpdateUser>());
        expect(identical(update.state, filters), isFalse);
        expect(identical(update.state.decks, filters.decks), isTrue);
        expect(identical(update.state.flags, filters.flags), isTrue);
        expect(identical(update.state.tags, filters.tags), isTrue);
        expect(identical(update.state.noteTypes, filters.noteTypes), isTrue);
        expect(
          identical(update.state.cardStateCodes, filters.cardStateCodes),
          isTrue,
        );
        expect(
          (effects[1] as BrowserBasicSearchTextEffect).text,
          '  sample query \r end  ',
        );
        expect((effects[2] as BrowserSearchScreenOpenEffect).isOpen, isFalse);

        final after =
            effects.fold(textState, browserSearchTextStateAfterEffect);
        expect(after.basicText, '  sample query \r end  ');
        expect(after.advancedText, 'keep advanced');
        expect(
          effects.every(
            (effect) =>
                effect is BrowserFilterUpdateEffect ||
                effect is BrowserBasicSearchTextEffect ||
                effect is BrowserSearchScreenOpenEffect,
          ),
          isTrue,
        );
      });

      test('edits Advanced text only when Advanced mode is selected', () {
        const textState = BrowserSearchTextState(
          isAdvancedSearch: true,
          basicText: 'keep basic',
          advancedText: 'old advanced',
        );

        final effects = browserSubmitSavedSearchEffects(
          const BrowserSavedSearch(name: 'saved', query: 'type:\ncloze'),
          currentFilters: const BrowserSearchFilters(tags: ['existing']),
          textState: textState,
        );

        expect(
          effects.map((effect) => effect.runtimeType),
          [
            BrowserFilterUpdateEffect,
            BrowserAdvancedSearchTextEffect,
            BrowserSearchScreenOpenEffect,
          ],
        );
        expect(
          (effects[1] as BrowserAdvancedSearchTextEffect).text,
          'type: cloze',
        );
        final after =
            effects.fold(textState, browserSearchTextStateAfterEffect);
        expect(after.basicText, 'keep basic');
        expect(after.advancedText, 'type: cloze');
        expect((effects.last as BrowserSearchScreenOpenEffect).isOpen, isFalse);
      });
    });
  });
}
