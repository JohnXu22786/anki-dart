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
 * Source-derived from DeckPickerViewModel.kt:94–118 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('projectFlattenedDeckList', () {
    test('projects a null tree as the source empty value', () {
      final result = projectFlattenedDeckList(
        null,
        DeckFilters.create(''),
        selectedDeckId: 0,
      );

      expect(result.data, isEmpty);
      expect(result.hasSubDecks, isFalse);
    });

    test('an empty tree has no rows or subdecks', () {
      final result = projectFlattenedDeckList(
        DeckNode.syntheticRoot(),
        DeckFilters.create(''),
        selectedDeckId: 0,
      );

      expect(result.data, isEmpty);
      expect(result.hasSubDecks, isFalse);
    });

    test('a top-level deck with a child has subdecks', () {
      final result = projectFlattenedDeckList(
        DeckNode.syntheticRoot(
          children: [
            _deck(1, 'Science', 0, children: [_deck(2, 'Science::Math', 1)]),
          ],
        ),
        DeckFilters.create(''),
        selectedDeckId: 0,
      );

      expect(result.hasSubDecks, isTrue);
      expect(result.data.map((deck) => deck.fullDeckName), [
        'Science',
        'Science::Math',
      ]);
    });

    test(
      'deep descendants use the existing flattening and source flag rules',
      () {
        final result = projectFlattenedDeckList(
          DeckNode.syntheticRoot(
            children: [
              _deck(
                1,
                'Science',
                0,
                children: [
                  _deck(
                    2,
                    'Science::Math',
                    1,
                    children: [_deck(3, 'Science::Math::Algebra', 2)],
                  ),
                ],
              ),
            ],
          ),
          DeckFilters.create(''),
          selectedDeckId: 0,
        );

        expect(result.hasSubDecks, isTrue);
        expect(result.data.map((deck) => deck.fullDeckName), [
          'Science',
          'Science::Math',
          'Science::Math::Algebra',
        ]);
      },
    );

    test('uses structural value equality like the source data class', () {
      final first = projectFlattenedDeckList(
        DeckNode.syntheticRoot(children: [_deck(1, 'Science', 0)]),
        DeckFilters.create(''),
        selectedDeckId: 1,
      );
      final equal = projectFlattenedDeckList(
        DeckNode.syntheticRoot(children: [_deck(1, 'Science', 0)]),
        DeckFilters.create(''),
        selectedDeckId: 1,
      );

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(
        first,
        isNot(FlattenedDeckList(data: equal.data, hasSubDecks: true)),
      );
    });

    test('passes filters and selected deck ID to display flattening', () {
      final result = projectFlattenedDeckList(
        DeckNode.syntheticRoot(
          children: [
            _deck(
              1,
              'Science',
              0,
              children: [
                _deck(
                  2,
                  'Science::Math',
                  1,
                  children: [_deck(3, 'Science::Math::Algebra', 2)],
                ),
                _deck(4, 'Science::Physics', 1),
              ],
            ),
          ],
        ),
        DeckFilters.create('algebra'),
        selectedDeckId: 3,
      );

      expect(result.data.map((deck) => deck.fullDeckName), [
        'Science',
        'Science::Math',
        'Science::Math::Algebra',
      ]);
      expect(result.data.map((deck) => deck.isSelected), [false, false, true]);
    });
  });
}

DeckNode _deck(
  int did,
  String fullDeckName,
  int depth, {
  List<DeckNode> children = const [],
}) => DeckNode(
  did: did,
  fullDeckName: fullDeckName,
  depth: depth,
  children: children,
);
