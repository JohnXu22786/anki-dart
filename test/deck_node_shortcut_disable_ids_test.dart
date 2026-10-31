/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from DeckPickerViewModel.kt:502–504 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('deckIdsForShortcutDisable', () {
    test('projects the selected deck subtree in preorder as decimal strings', () {
      final tree = DeckNode.syntheticRoot(children: [
        _node(10, [
          _node(20, [
            _node(9007199254740993),
            _node(30),
          ]),
          _node(40),
        ]),
      ]);

      expect(deckIdsForShortcutDisable(tree, 20), [
        '20',
        '9007199254740993',
        '30',
      ]);
    });

    test('uses the first depth-first match when deck IDs repeat', () {
      final tree = DeckNode.syntheticRoot(children: [
        _node(2, [_node(7, [_node(8)])]),
        _node(7, [_node(9)]),
      ]);

      expect(deckIdsForShortcutDisable(tree, 7), ['7', '8']);
    });

    test('returns empty for missing input and omits synthetic matches', () {
      final tree = DeckNode.syntheticRoot(children: [
        _node(1, [
          DeckNode.syntheticRoot(children: [_node(2)]),
          _node(3),
        ]),
      ]);

      expect(deckIdsForShortcutDisable(null, 1), isEmpty);
      expect(deckIdsForShortcutDisable(tree, 99), isEmpty);
      expect(deckIdsForShortcutDisable(tree, 0), ['1', '2', '3']);
    });
  });
}

DeckNode _node(int did, [List<DeckNode> children = const []]) => DeckNode(
      did: did,
      fullDeckName: 'Deck $did',
      depth: 0,
      children: children,
    );
