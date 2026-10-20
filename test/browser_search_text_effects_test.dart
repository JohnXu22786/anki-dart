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
 * Source-derived effect-order cases for CardBrowserSearchViewModel.kt;
 * pinned tests exercise text changes but do not assert this combined sequence.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser search-text update effects', () {
    const filters = BrowserSearchFilters(
      decks: [BrowserDeckNameId(name: 'Deck', id: 7)],
      flags: [1, 4],
      tags: ['tag-a', 'tag-b'],
      noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: 3)],
      cardStateCodes: [0, 2],
    );

    test('Basic edit emits a copied User update before Basic text', () {
      const state = BrowserSearchTextState(
        basicText: 'old basic',
        advancedText: 'keep advanced',
      );

      final effects = browserOnSearchTextChangedEffects(
        '\nfirst\r\n🙂\tlast\n',
        currentFilters: filters,
        textState: state,
      );

      expect(effects, hasLength(2));
      expect(
        effects.map((effect) => effect.runtimeType),
        [BrowserFilterUpdateEffect, BrowserBasicSearchTextEffect],
      );
      final update = (effects[0] as BrowserFilterUpdateEffect).update;
      expect(update, isA<BrowserFilterUpdateUser>());
      _expectShallowFilterCopy(update.state, filters);
      expect((effects[1] as BrowserBasicSearchTextEffect).text,
          ' first\r 🙂\tlast ');

      final updatedText =
          effects.fold(state, browserSearchTextStateAfterEffect);
      expect(updatedText.isAdvancedSearch, isFalse);
      expect(updatedText.basicText, ' first\r 🙂\tlast ');
      expect(updatedText.advancedText, state.advancedText);
      _expectNoSubmissionOrClose(effects);
    });

    test('Advanced edit emits a copied User update before Advanced text', () {
      const state = BrowserSearchTextState(
        isAdvancedSearch: true,
        basicText: 'keep basic',
        advancedText: 'old advanced',
      );

      final effects = browserOnSearchTextChangedEffects(
        'left\r\nright\n',
        currentFilters: filters,
        textState: state,
      );

      expect(effects, hasLength(2));
      expect(
        effects.map((effect) => effect.runtimeType),
        [BrowserFilterUpdateEffect, BrowserAdvancedSearchTextEffect],
      );
      final update = (effects[0] as BrowserFilterUpdateEffect).update;
      expect(update, isA<BrowserFilterUpdateUser>());
      _expectShallowFilterCopy(update.state, filters);
      expect((effects[1] as BrowserAdvancedSearchTextEffect).text,
          'left\r right ');

      final updatedText =
          effects.fold(state, browserSearchTextStateAfterEffect);
      expect(updatedText.isAdvancedSearch, isTrue);
      expect(updatedText.basicText, state.basicText);
      expect(updatedText.advancedText, 'left\r right ');
      _expectNoSubmissionOrClose(effects);
    });
  });
}

void _expectShallowFilterCopy(
  BrowserSearchFilters copied,
  BrowserSearchFilters original,
) {
  expect(copied, original);
  expect(identical(copied, original), isFalse);
  expect(identical(copied.decks, original.decks), isTrue);
  expect(identical(copied.flags, original.flags), isTrue);
  expect(identical(copied.tags, original.tags), isTrue);
  expect(identical(copied.noteTypes, original.noteTypes), isTrue);
  expect(identical(copied.cardStateCodes, original.cardStateCodes), isTrue);
}

void _expectNoSubmissionOrClose(List<BrowserSearchStateEffect> effects) {
  expect(effects.whereType<BrowserSearchSubmittedEffect>(), isEmpty);
  expect(effects.whereType<BrowserCloseSearchViewEventEffect>(), isEmpty);
  expect(effects.whereType<BrowserSearchScreenOpenEffect>(), isEmpty);
}
