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
 * Behavioral references: SearchRequestTest.kt, SearchRequest.kt,
 * SearchFilters.kt, Flag.kt, CardState.kt, and Collection.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser structured search-node plan', () {
    test('keeps an empty parsable-text node for the default search', () {
      final plan = buildBrowserSearchNodePlan(
        const BrowserSearchRequest(query: ''),
      );

      expect(plan, isA<BrowserSearchTextTermPlan>());
      expect((plan as BrowserSearchTextTermPlan).text, '');
    });

    test('trims simple query text with Kotlin whitespace rules', () {
      final plan = buildBrowserSearchNodePlan(
        const BrowserSearchRequest(query: '\u00a0\t hello \u00a0'),
      );

      expect(plan, isA<BrowserSearchTextTermPlan>());
      expect((plan as BrowserSearchTextTermPlan).text, 'hello');
    });

    test('collapses a single deck filter to its term', () {
      final plan = buildBrowserSearchNodePlan(
        const BrowserSearchRequest(
          query: '',
          filters: BrowserSearchFilters(
            decks: [BrowserDeckNameId(name: 'Default', id: 1)],
          ),
        ),
      );

      expect(plan, isA<BrowserSearchDeckTermPlan>());
      expect((plan as BrowserSearchDeckTermPlan).name, 'Default');
    });

    test('omits a Kotlin-blank query when filters are active', () {
      final plan = buildBrowserSearchNodePlan(
        const BrowserSearchRequest(
          query: ' \t\u00a0',
          filters: BrowserSearchFilters(tags: ['tag']),
        ),
      );

      expect(plan, isA<BrowserSearchTagTermPlan>());
      expect((plan as BrowserSearchTagTermPlan).tag, 'tag');
    });

    test('keeps U+0085 nonblank while trimming surrounding whitespace', () {
      final plan = buildBrowserSearchNodePlan(
        const BrowserSearchRequest(
          query: ' \u0085 ',
          filters: BrowserSearchFilters(tags: ['tag']),
        ),
      );

      expect(plan, isA<BrowserSearchGroupPlan>());
      final root = plan as BrowserSearchGroupPlan;
      expect(root.joiner, BrowserSearchJoiner.and);
      expect(root.children, hasLength(2));
      expect((root.children.first as BrowserSearchTextTermPlan).text, '\u0085');
      expect(root.children.last, isA<BrowserSearchTagTermPlan>());
    });

    test('orders complex terms and groups exactly like SearchRequest', () {
      final plan = buildBrowserSearchNodePlan(
        const BrowserSearchRequest(
          query: ' queryString ',
          filters: BrowserSearchFilters(
            decks: [
              BrowserDeckNameId(name: 'Default', id: 1),
              BrowserDeckNameId(name: 'Other', id: 2),
            ],
            flags: [1, 4],
            tags: ['Hello::World', 'tag'],
            noteTypes: [
              BrowserNoteTypeNameId(name: 'Basic', id: 3),
              BrowserNoteTypeNameId(name: 'Cloze', id: 4),
            ],
            cardStateCodes: [0, 1, 2, 3, 4],
          ),
        ),
      );

      expect(plan, isA<BrowserSearchGroupPlan>());
      final root = plan as BrowserSearchGroupPlan;
      expect(root.joiner, BrowserSearchJoiner.and);
      expect(root.children, hasLength(6));
      expect(
          (root.children[0] as BrowserSearchTextTermPlan).text, 'queryString');

      final decks = root.children[1] as BrowserSearchGroupPlan;
      expect(decks.joiner, BrowserSearchJoiner.or);
      expect(
          decks.children
              .map((node) => (node as BrowserSearchDeckTermPlan).name),
          ['Default', 'Other']);

      final flags = root.children[2] as BrowserSearchGroupPlan;
      expect(flags.joiner, BrowserSearchJoiner.or);
      expect(
        flags.children.map((node) => (node as BrowserSearchFlagTermPlan).value),
        [BrowserSearchFlagValue.red, BrowserSearchFlagValue.blue],
      );

      final tags = root.children[3] as BrowserSearchGroupPlan;
      expect(tags.joiner, BrowserSearchJoiner.or);
      expect(
          tags.children.map((node) => (node as BrowserSearchTagTermPlan).tag),
          ['Hello::World', 'tag']);

      final noteTypes = root.children[4] as BrowserSearchGroupPlan;
      expect(noteTypes.joiner, BrowserSearchJoiner.or);
      expect(
        noteTypes.children
            .map((node) => (node as BrowserSearchNoteTypeTermPlan).name),
        ['Basic', 'Cloze'],
      );

      final cardStates = root.children[5] as BrowserSearchGroupPlan;
      expect(cardStates.joiner, BrowserSearchJoiner.or);
      expect(
        cardStates.children
            .map((node) => (node as BrowserSearchCardStateTermPlan).value),
        [
          BrowserSearchCardStateValue.newCard,
          BrowserSearchCardStateValue.learning,
          BrowserSearchCardStateValue.review,
          BrowserSearchCardStateValue.buried,
          BrowserSearchCardStateValue.suspended,
        ],
      );
    });

    test('leaves a multi-term category OR group at the root', () {
      final plan = buildBrowserSearchNodePlan(
        const BrowserSearchRequest(
          query: '',
          filters: BrowserSearchFilters(tags: ['one', 'two']),
        ),
      );

      expect(plan, isA<BrowserSearchGroupPlan>());
      final root = plan as BrowserSearchGroupPlan;
      expect(root.joiner, BrowserSearchJoiner.or);
      expect(
          root.children.map((node) => (node as BrowserSearchTagTermPlan).tag),
          ['one', 'two']);
    });

    test('maps every persisted code to its explicit semantic search value', () {
      final plan = buildBrowserSearchNodePlan(
        const BrowserSearchRequest(
          query: '',
          filters: BrowserSearchFilters(
            flags: [0, 1, 2, 3, 4, 5, 6, 7],
            cardStateCodes: [0, 1, 2, 3, 4],
          ),
        ),
      );
      final root = plan as BrowserSearchGroupPlan;
      final flags = root.children[0] as BrowserSearchGroupPlan;
      final cardStates = root.children[1] as BrowserSearchGroupPlan;

      expect(
        flags.children.map((node) => (node as BrowserSearchFlagTermPlan).value),
        [
          BrowserSearchFlagValue.none,
          BrowserSearchFlagValue.red,
          BrowserSearchFlagValue.orange,
          BrowserSearchFlagValue.green,
          BrowserSearchFlagValue.blue,
          BrowserSearchFlagValue.pink,
          BrowserSearchFlagValue.turquoise,
          BrowserSearchFlagValue.purple,
        ],
      );
      expect(
        cardStates.children
            .map((node) => (node as BrowserSearchCardStateTermPlan).value),
        [
          BrowserSearchCardStateValue.newCard,
          BrowserSearchCardStateValue.learning,
          BrowserSearchCardStateValue.review,
          BrowserSearchCardStateValue.buried,
          BrowserSearchCardStateValue.suspended,
        ],
      );
    });

    test('fails instead of coercing an unsupported flag code', () {
      expect(
        () => buildBrowserSearchNodePlan(
          const BrowserSearchRequest(
            query: '',
            filters: BrowserSearchFilters(flags: [8]),
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fails instead of coercing an unsupported card-state code', () {
      expect(
        () => buildBrowserSearchNodePlan(
          const BrowserSearchRequest(
            query: '',
            filters: BrowserSearchFilters(cardStateCodes: [5]),
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
