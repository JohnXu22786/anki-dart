/*
 * Copyright (c) 2025 Shridhar Goel <shridhar.goel@gmail.com>
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
 * SPDX-FileCopyrightText: 2025 Shridhar Goel <shridhar.goel@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: AnkiDroid DeckNodeTest.kt at v2.25.3.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('filterAndFlattenDisplay', () {
    test('search opens collapsed ancestors and includes the matching path', () {
      final tree = _scienceTree();

      final visible = tree.filterAndFlattenDisplay(
        DeckFilters.create('group'),
        selectedDeckId: 4,
      );

      expect(
        visible.map((deck) => deck.lastDeckNameComponent),
        ['Science', 'Math', 'Algebra', 'Group'],
      );
      expect(visible.map((deck) => deck.depth), [0, 1, 2, 3]);
      expect(visible.last.isSelected, isTrue);
      expect(visible.first.canCollapse, isFalse);
    });

    test('a matching collapsed deck keeps its children hidden during search',
        () {
      final visible = _scienceTree().filterAndFlattenDisplay(
        DeckFilters.create('math'),
        selectedDeckId: 2,
      );

      expect(
        visible.map((deck) => deck.lastDeckNameComponent),
        ['Science', 'Math'],
      );
      expect(visible.last.canCollapse, isTrue);
      expect(visible.last.isSelected, isTrue);
    });

    test('search includes ancestor paths and excludes unrelated branches', () {
      final tree = DeckNode.syntheticRoot(
        children: [
          _deck(1, 'Science', 0, children: [
            _deck(2, 'Math', 1,
                collapsed: true, children: [_deck(3, 'Algebra', 2)])
          ]),
          _deck(10, 'Languages', 0, children: [_deck(11, 'French', 1)]),
        ],
      );

      final visible = tree.filterAndFlattenDisplay(
        DeckFilters.create('algebra'),
        selectedDeckId: 3,
      );

      expect(
        visible.map((deck) => deck.lastDeckNameComponent),
        ['Science', 'Math', 'Algebra'],
      );
      expect(visible.map((deck) => deck.isSelected), [false, false, true]);
    });

    test('an empty search respects collapsed decks', () {
      final visible = _scienceTree().filterAndFlattenDisplay(
        DeckFilters.create(''),
        selectedDeckId: 4,
      );

      expect(
        visible.map((deck) => deck.lastDeckNameComponent),
        ['Science', 'Math'],
      );
    });
  });
}

DeckNode _scienceTree() {
  final group = _deck(4, 'Science::Math::Algebra::Group', 3);
  final algebra = _deck(3, 'Science::Math::Algebra', 2, children: [group]);
  final math =
      _deck(2, 'Science::Math', 1, collapsed: true, children: [algebra]);
  final science = _deck(1, 'Science', 0, children: [math]);

  return DeckNode.syntheticRoot(children: [science]);
}

DeckNode _deck(
  int did,
  String fullDeckName,
  int depth, {
  bool collapsed = false,
  List<DeckNode> children = const [],
}) =>
    DeckNode(
      did: did,
      fullDeckName: fullDeckName,
      depth: depth,
      collapsed: collapsed,
      children: children,
    );
