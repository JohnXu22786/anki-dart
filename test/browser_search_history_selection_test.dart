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
 * Behavioral reference: `selectSearchHistoryEntry` and
 * `onSearchTextChanged` in CardBrowserSearchViewModel.kt, AnkiDroid 2.25.3;
 * filter ID resolution follows SearchFilters.from. See ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser search-history selection effects', () {
    const existingFilters = BrowserSearchFilters(
      decks: [BrowserDeckNameId(name: 'Old deck', id: 10)],
      flags: [4],
      tags: ['old-tag'],
      noteTypes: [BrowserNoteTypeNameId(name: 'Old type', id: 20)],
      cardStateCodes: [2],
    );

    const entry = BrowserSearchHistoryEntry(
      query: 'first\nsecond\rthird\n',
      deckIds: [2, 1],
      flags: [1, 4],
      tags: ['new-tag'],
      noteTypeIds: [3],
      cardStateCodes: [0, 4],
    );

    const deckNameMap = [
      BrowserDeckNameId(name: 'Default', id: 1),
      BrowserDeckNameId(name: 'Language::Spanish', id: 2),
    ];
    const noteTypeMap = [BrowserNoteTypeNameId(name: 'Basic', id: 3)];

    test('Basic selection emits ordered updates and restores filters', () {
      const textState = BrowserSearchTextState(
        basicText: 'old basic',
        advancedText: 'old advanced',
      );

      final effects = browserSelectSearchHistoryEntryEffects(
        entry,
        currentFilters: existingFilters,
        textState: textState,
        deckNameMap: deckNameMap,
        noteTypeMap: noteTypeMap,
      );

      expect(
        effects.map((effect) => effect.runtimeType),
        [
          BrowserFilterUpdateEffect,
          BrowserBasicSearchTextEffect,
          BrowserFilterUpdateEffect,
          BrowserSearchScreenOpenEffect,
        ],
      );

      final textFilterUpdate = (effects[0] as BrowserFilterUpdateEffect).update;
      expect(textFilterUpdate, isA<BrowserFilterUpdateUser>());
      expect(textFilterUpdate.state, existingFilters);
      expect(identical(textFilterUpdate.state, existingFilters), isFalse);
      expect(
        identical(textFilterUpdate.state.decks, existingFilters.decks),
        isTrue,
      );
      expect(
        identical(textFilterUpdate.state.flags, existingFilters.flags),
        isTrue,
      );
      expect(
        identical(textFilterUpdate.state.tags, existingFilters.tags),
        isTrue,
      );
      expect(
        identical(textFilterUpdate.state.noteTypes, existingFilters.noteTypes),
        isTrue,
      );
      expect(
        identical(
          textFilterUpdate.state.cardStateCodes,
          existingFilters.cardStateCodes,
        ),
        isTrue,
      );
      expect(
        (effects[1] as BrowserBasicSearchTextEffect).text,
        'first second\rthird ',
      );

      final restoredUpdate = (effects[2] as BrowserFilterUpdateEffect).update;
      expect(restoredUpdate, isA<BrowserFilterUpdateUser>());
      expect(
        restoredUpdate.state,
        const BrowserSearchFilters(
          decks: [
            BrowserDeckNameId(name: 'Language::Spanish', id: 2),
            BrowserDeckNameId(name: 'Default', id: 1),
          ],
          flags: [1, 4],
          tags: ['new-tag'],
          noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: 3)],
          cardStateCodes: [0, 4],
        ),
      );
      expect((effects[3] as BrowserSearchScreenOpenEffect).isOpen, isFalse);

      final updatedText = effects.fold(
        textState,
        browserSearchTextStateAfterEffect,
      );
      expect(updatedText.basicText, 'first second\rthird ');
      expect(updatedText.advancedText, 'old advanced');
    });

    test('Advanced selection changes only the Advanced text buffer', () {
      const textState = BrowserSearchTextState(
        isAdvancedSearch: true,
        basicText: 'old basic',
        advancedText: 'old advanced',
      );

      final effects = browserSelectSearchHistoryEntryEffects(
        entry,
        currentFilters: existingFilters,
        textState: textState,
        deckNameMap: deckNameMap,
        noteTypeMap: noteTypeMap,
      );

      expect(effects[1], isA<BrowserAdvancedSearchTextEffect>());
      expect(
        (effects[1] as BrowserAdvancedSearchTextEffect).text,
        'first second\rthird ',
      );
      final updatedText = effects.fold(
        textState,
        browserSearchTextStateAfterEffect,
      );
      expect(updatedText.isAdvancedSearch, isTrue);
      expect(updatedText.basicText, 'old basic');
      expect(updatedText.advancedText, 'first second\rthird ');
    });

    test('missing deck or note-type IDs restore EMPTY filters', () {
      const entryWithIds = BrowserSearchHistoryEntry(
        query: 'history query',
        deckIds: [1],
        flags: [1],
        tags: ['tag'],
        noteTypeIds: [3],
        cardStateCodes: [2],
      );

      final missingDeck = browserSelectSearchHistoryEntryEffects(
        entryWithIds,
        currentFilters: existingFilters,
        textState: const BrowserSearchTextState(),
        deckNameMap: const [],
        noteTypeMap: noteTypeMap,
      );
      final missingNoteType = browserSelectSearchHistoryEntryEffects(
        entryWithIds,
        currentFilters: existingFilters,
        textState: const BrowserSearchTextState(),
        deckNameMap: deckNameMap,
        noteTypeMap: const [],
      );

      expect(
        (missingDeck[2] as BrowserFilterUpdateEffect).update.state,
        const BrowserSearchFilters(),
      );
      expect(
        (missingNoteType[2] as BrowserFilterUpdateEffect).update.state,
        const BrowserSearchFilters(),
      );
      expect(
        (missingDeck.last as BrowserSearchScreenOpenEffect).isOpen,
        isFalse,
      );
      expect(
        (missingNoteType.last as BrowserSearchScreenOpenEffect).isOpen,
        isFalse,
      );
    });
  });
}
