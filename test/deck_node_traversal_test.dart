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
 * Behavioral reference: AnkiDroid DeckNode.kt at v2.25.3.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('DeckNode.find', () {
    test('checks self before the first matching descendant', () {
      final tree = _node(1, [
        _node(2, [_node(7)]),
        _node(7),
      ]);

      expect(tree.find(1), same(tree));
      expect(tree.find(7), same(tree.children[0].children.single));
    });

    test('searches children depth first in order and returns null if absent',
        () {
      final first = _node(7);
      final tree = _node(0, [
        _node(2, [first]),
        _node(3, [_node(7)]),
      ]);

      expect(tree.find(7), same(first));
      expect(tree.find(99), isNull);
    });

    test('find includes a matching synthetic node', () {
      final synthetic = DeckNode.syntheticRoot(children: [_node(1)]);

      expect(synthetic.find(0), same(synthetic));
    });
  });

  group('DeckNode preorder traversal', () {
    test('visits self and descendants in child order, skipping synthetic nodes',
        () {
      final tree = DeckNode.syntheticRoot(children: [
        _node(1, [
          _node(2),
          DeckNode.syntheticRoot(children: [_node(3)]),
        ]),
        _node(4),
      ]);

      expect(tree.preorder.map((node) => node.did), [1, 2, 3, 4]);
    });

    test('supports direct iteration with the same preorder', () {
      final tree = DeckNode.syntheticRoot(children: [_node(1), _node(2)]);
      final visited = <int>[];

      for (final node in tree) {
        visited.add(node.did);
      }

      expect(visited, [1, 2]);
    });

    test('forEach uses the same order and synthetic-node filtering', () {
      final tree = DeckNode.syntheticRoot(children: [_node(1), _node(2)]);
      final visited = <DeckNode>[];

      tree.forEach(visited.add);

      expect(visited.map((node) => node.did), [1, 2]);
    });
  });
}

DeckNode _node(int did, [List<DeckNode> children = const []]) => DeckNode(
      did: did,
      fullDeckName: 'Deck $did',
      depth: 0,
      children: children,
    );
