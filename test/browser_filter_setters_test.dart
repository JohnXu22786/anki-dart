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
 * Source-derived cases for CardBrowserSearchViewModel.kt filter setters. The
 * pinned SearchFilters tests do not directly exercise these ViewModel methods.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser filter setter projections', () {
    final noteType = BrowserNoteTypeNameId(name: 'Basic', id: 17);
    final originalDeck = BrowserDeckNameId(name: 'Original', id: 1);
    final originalDecks = [originalDeck];
    final originalFlags = [1, 4];
    final originalTags = ['old-tag'];
    final originalNoteTypes = [noteType];
    final originalCardStates = [0, 2];
    final current = BrowserSearchFilters(
      decks: originalDecks,
      flags: originalFlags,
      tags: originalTags,
      noteTypes: originalNoteTypes,
      cardStateCodes: originalCardStates,
    );

    test('deck setter changes only decks and still emits for equal values', () {
      final incoming = [BrowserDeckNameId(name: 'New', id: 2)];
      final update = browserSetDecksFilter(
        currentFilters: current,
        decks: incoming,
      );

      expect(update, isA<BrowserFilterUpdateUser>());
      _expectDeckUpdate(update.state, current, incoming);
      expect(update.state.decks, [BrowserDeckNameId(name: 'New', id: 2)]);

      final equalIncoming = [BrowserDeckNameId(name: 'Original', id: 1)];
      final equalUpdate = browserSetDecksFilter(
        currentFilters: current,
        decks: equalIncoming,
      );
      expect(equalUpdate, isA<BrowserFilterUpdateUser>());
      expect(equalUpdate.state, current);
      expect(identical(equalUpdate.state, current), isFalse);
      expect(identical(equalUpdate.state.decks, equalIncoming), isTrue);
    });

    test('tag setter changes only tags and still emits for equal values', () {
      final incoming = ['new-tag', 'another-tag'];
      final update = browserSetTagsFilter(
        currentFilters: current,
        tags: incoming,
      );

      expect(update, isA<BrowserFilterUpdateUser>());
      _expectTagUpdate(update.state, current, incoming);
      expect(update.state.tags, ['new-tag', 'another-tag']);

      final equalIncoming = ['old-tag'];
      final equalUpdate = browserSetTagsFilter(
        currentFilters: current,
        tags: equalIncoming,
      );
      expect(equalUpdate, isA<BrowserFilterUpdateUser>());
      expect(equalUpdate.state, current);
      expect(identical(equalUpdate.state, current), isFalse);
      expect(identical(equalUpdate.state.tags, equalIncoming), isTrue);
    });

    test(
        'card-state setter changes only card states and emits for equal values',
        () {
      final incoming = [1, 3, 4];
      final update = browserSetCardStateFilter(
        currentFilters: current,
        cardStateCodes: incoming,
      );

      expect(update, isA<BrowserFilterUpdateUser>());
      _expectCardStateUpdate(update.state, current, incoming);
      expect(update.state.cardStateCodes, [1, 3, 4]);

      final equalIncoming = [0, 2];
      final equalUpdate = browserSetCardStateFilter(
        currentFilters: current,
        cardStateCodes: equalIncoming,
      );
      expect(equalUpdate, isA<BrowserFilterUpdateUser>());
      expect(equalUpdate.state, current);
      expect(identical(equalUpdate.state, current), isFalse);
      expect(
          identical(equalUpdate.state.cardStateCodes, equalIncoming), isTrue);
    });

    test('flag setter changes only flags and still emits for equal values', () {
      final incoming = [2, 3];
      final update = browserSetFlagsFilter(
        currentFilters: current,
        flags: incoming,
      );

      expect(update, isA<BrowserFilterUpdateUser>());
      _expectFlagUpdate(update.state, current, incoming);
      expect(update.state.flags, [2, 3]);

      final equalIncoming = [1, 4];
      final equalUpdate = browserSetFlagsFilter(
        currentFilters: current,
        flags: equalIncoming,
      );
      expect(equalUpdate, isA<BrowserFilterUpdateUser>());
      expect(equalUpdate.state, current);
      expect(identical(equalUpdate.state, current), isFalse);
      expect(identical(equalUpdate.state.flags, equalIncoming), isTrue);
    });
  });
}

void _expectDeckUpdate(
  BrowserSearchFilters result,
  BrowserSearchFilters current,
  List<BrowserDeckNameId> incoming,
) {
  expect(identical(result, current), isFalse);
  expect(identical(result.decks, incoming), isTrue);
  expect(identical(result.flags, current.flags), isTrue);
  expect(identical(result.tags, current.tags), isTrue);
  expect(identical(result.noteTypes, current.noteTypes), isTrue);
  expect(identical(result.cardStateCodes, current.cardStateCodes), isTrue);
}

void _expectTagUpdate(
  BrowserSearchFilters result,
  BrowserSearchFilters current,
  List<String> incoming,
) {
  expect(identical(result, current), isFalse);
  expect(identical(result.decks, current.decks), isTrue);
  expect(identical(result.flags, current.flags), isTrue);
  expect(identical(result.tags, incoming), isTrue);
  expect(identical(result.noteTypes, current.noteTypes), isTrue);
  expect(identical(result.cardStateCodes, current.cardStateCodes), isTrue);
}

void _expectCardStateUpdate(
  BrowserSearchFilters result,
  BrowserSearchFilters current,
  List<int> incoming,
) {
  expect(identical(result, current), isFalse);
  expect(identical(result.decks, current.decks), isTrue);
  expect(identical(result.flags, current.flags), isTrue);
  expect(identical(result.tags, current.tags), isTrue);
  expect(identical(result.noteTypes, current.noteTypes), isTrue);
  expect(identical(result.cardStateCodes, incoming), isTrue);
}

void _expectFlagUpdate(
  BrowserSearchFilters result,
  BrowserSearchFilters current,
  List<int> incoming,
) {
  expect(identical(result, current), isFalse);
  expect(identical(result.decks, current.decks), isTrue);
  expect(identical(result.flags, incoming), isTrue);
  expect(identical(result.tags, current.tags), isTrue);
  expect(identical(result.noteTypes, current.noteTypes), isTrue);
  expect(identical(result.cardStateCodes, current.cardStateCodes), isTrue);
}
