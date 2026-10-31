/*
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Dart input model for the deck-tree fields consumed by the deck picker.
 */

import 'dart:collection';

class DeckNode extends IterableBase<DeckNode> {
  DeckNode({
    required this.did,
    required this.fullDeckName,
    required this.depth,
    String? lastDeckNameComponent,
    this.collapsed = false,
    this.filtered = false,
    this.newCount = 0,
    this.lrnCount = 0,
    this.revCount = 0,
    this.children = const [],
    bool? isSyntheticDeck,
  })  : _lastDeckNameComponent = lastDeckNameComponent,
        isSyntheticDeck = isSyntheticDeck ?? depth < 0;

  factory DeckNode.syntheticRoot({
    List<DeckNode> children = const [],
    bool collapsed = false,
  }) =>
      DeckNode(
        did: 0,
        fullDeckName: '',
        lastDeckNameComponent: '',
        depth: -1,
        children: children,
        collapsed: collapsed,
        isSyntheticDeck: true,
      );

  final int did;
  final String fullDeckName;
  final String? _lastDeckNameComponent;
  final int depth;
  bool collapsed;
  final bool filtered;
  final int newCount;
  final int lrnCount;
  final int revCount;
  final List<DeckNode> children;
  final bool isSyntheticDeck;

  /// Whether any review, learning, or new cards are ready to study.
  bool hasCardsReadyToStudy() =>
      revCount > 0 || newCount > 0 || lrnCount > 0;

  @override
  String toString() =>
      '$fullDeckName, $did, $revCount, $lrnCount, $newCount';

  String get lastDeckNameComponent =>
      _lastDeckNameComponent ?? fullDeckName.split('::').last;

  /// Returns this node or the first descendant with [deckId].
  ///
  /// The current node is checked before children, which are searched in order.
  /// Synthetic nodes participate in lookup just like other nodes.
  DeckNode? find(int deckId) {
    if (did == deckId) {
      return this;
    }
    for (final child in children) {
      final found = child.find(deckId);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  /// The source-order preorder traversal of this node and its descendants.
  ///
  /// Synthetic nodes are omitted, while their descendants are still visited.
  Iterable<DeckNode> get preorder sync* {
    if (!isSyntheticDeck) {
      yield this;
    }
    for (final child in children) {
      yield* child.preorder;
    }
  }

  @override
  Iterator<DeckNode> get iterator => preorder.iterator;

  /// Calls [action] on this node and descendants in preorder.
  ///
  /// Synthetic nodes are omitted, matching [preorder].
  @override
  void forEach(void Function(DeckNode) action) => preorder.forEach(action);

  /// Returns the total due count across this node's immediate children.
  ///
  /// The backend caps the root aggregate, while subdecks share their parent's
  /// limits, so this sums each top-level child exactly once.
  int totalCardsDue() => children.fold(0, (total, child) {
        final childDue = _addInt32(
          _addInt32(child.newCount, child.revCount),
          child.lrnCount,
        );
        return _addInt32(total, childDue);
      });
}

/// Returns whether [childDeckIds] contains only the default deck.
///
/// This matches `DeckNode.onlyHasDefaultDeck()` in AnkiDroid: the single child
/// must have ID 1; empty or multi-child lists return false.
bool onlyHasDefaultDeck(List<int> childDeckIds) =>
    childDeckIds.length == 1 && childDeckIds.single == 1;

/// Returns the IDs AnkiDroid emits when disabling shortcuts for [deckId].
///
/// Lookup uses [DeckNode.find]'s first depth-first match, then iterates that
/// subtree in source order. Synthetic nodes are omitted by the iterator.
List<String> deckIdsForShortcutDisable(DeckNode? dueTree, int deckId) =>
    dueTree?.find(deckId)?.map((node) => node.did.toString()).toList() ??
    const <String>[];

int _addInt32(int left, int right) => (left + right).toSigned(32);
