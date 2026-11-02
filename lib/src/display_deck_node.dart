/*
 * Copyright (c) 2025 Gautam Bhetanabhotla <gautamarcturus@gmail.com>
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
 * SPDX-FileCopyrightText: 2025 Gautam Bhetanabhotla <gautamarcturus@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Dart adaptation of AnkiDroid's DisplayDeckNode.kt from the pinned upstream
 * revision recorded in ANKIDROID_UPSTREAM.md.
 */

import 'deck_filters.dart';
import 'deck_node.dart';

/// The fields needed to render one row in AnkiDroid's deck picker.
class DisplayDeckNode {
  DisplayDeckNode._({
    required this.deckNode,
    required this.did,
    required this.fullDeckName,
    required this.lastDeckNameComponent,
    required this.collapsed,
    required this.canCollapse,
    required this.depth,
    required this.filtered,
    required this.newCount,
    required this.lrnCount,
    required this.revCount,
    required this.isSelected,
  });

  final DeckNode deckNode;
  final int did;
  final String fullDeckName;
  final String lastDeckNameComponent;
  final bool collapsed;
  final bool canCollapse;
  final int depth;
  final bool filtered;
  final int newCount;
  final int lrnCount;
  final int revCount;
  final bool isSelected;

  // AnkiDroid keeps the mutable DeckNode outside the data class constructor.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisplayDeckNode &&
          other.did == did &&
          other.fullDeckName == fullDeckName &&
          other.lastDeckNameComponent == lastDeckNameComponent &&
          other.collapsed == collapsed &&
          other.canCollapse == canCollapse &&
          other.depth == depth &&
          other.filtered == filtered &&
          other.newCount == newCount &&
          other.lrnCount == lrnCount &&
          other.revCount == revCount &&
          other.isSelected == isSelected;

  @override
  int get hashCode => Object.hash(
        did,
        fullDeckName,
        lastDeckNameComponent,
        collapsed,
        canCollapse,
        depth,
        filtered,
        newCount,
        lrnCount,
        revCount,
        isSelected,
      );

  DisplayDeckNode withUpdatedDeckId(int deckId) => _copyWith(
        isSelected: did == deckId,
      );

  DisplayDeckNode _copyWith({bool? isSelected}) => DisplayDeckNode._(
        deckNode: deckNode,
        did: did,
        fullDeckName: fullDeckName,
        lastDeckNameComponent: lastDeckNameComponent,
        collapsed: collapsed,
        canCollapse: canCollapse,
        depth: depth,
        filtered: filtered,
        newCount: newCount,
        lrnCount: lrnCount,
        revCount: revCount,
        isSelected: isSelected ?? this.isSelected,
      );

  static DisplayDeckNode from(
    DeckNode node, {
    required bool matchesSearchOrChild,
    required int selectedDeckId,
  }) =>
      DisplayDeckNode._(
        deckNode: node,
        did: node.did,
        fullDeckName: node.fullDeckName,
        lastDeckNameComponent: node.lastDeckNameComponent,
        collapsed: node.collapsed,
        canCollapse: node.children.isNotEmpty && matchesSearchOrChild,
        depth: node.depth,
        filtered: node.filtered,
        newCount: node.newCount,
        lrnCount: node.lrnCount,
        revCount: node.revCount,
        isSelected: node.did == selectedDeckId,
      );
}

/// Flattens matching deck rows, including their ancestor path and visible
/// descendants, using AnkiDroid's deck picker rules.
List<DisplayDeckNode> filterAndFlattenDisplay(
  DeckNode root,
  DeckFilters filter, {
  required int selectedDeckId,
}) =>
    _flattenDeckTree(root, filter, selectedDeckId);

extension DeckNodeDisplay on DeckNode {
  List<DisplayDeckNode> filterAndFlattenDisplay(
    DeckFilters filter, {
    required int selectedDeckId,
  }) =>
      _flattenDeckTree(this, filter, selectedDeckId);
}

List<DisplayDeckNode> _flattenDeckTree(
  DeckNode root,
  DeckFilters filter,
  int selectedDeckId,
) {
  final rows = <DisplayDeckNode>[];
  _filterAndFlattenDisplayInner(
    root,
    filter,
    rows,
    parentMatched: false,
    selectedDeckId: selectedDeckId,
  );
  return rows;
}

void _filterAndFlattenDisplayInner(
  DeckNode node,
  DeckFilters filter,
  List<DisplayDeckNode> rows, {
  required bool parentMatched,
  required int selectedDeckId,
}) {
  if (!node.isSyntheticDeck &&
      (filter.accept(node.fullDeckName) || parentMatched)) {
    _addVisibleToList(
      node,
      rows,
      matchesSearchOrChild: true,
      selectedDeckId: selectedDeckId,
    );
    return;
  }

  final searching = filter.isActive();
  if (node.collapsed && !searching) {
    return;
  }

  if (!node.isSyntheticDeck) {
    rows.add(
      DisplayDeckNode.from(
        node,
        matchesSearchOrChild: false,
        selectedDeckId: selectedDeckId,
      ),
    );
  }

  final startingLength = rows.length;
  for (final child in node.children) {
    _filterAndFlattenDisplayInner(
      child,
      filter,
      rows,
      parentMatched: false,
      selectedDeckId: selectedDeckId,
    );
  }

  if (!node.isSyntheticDeck && startingLength == rows.length) {
    rows.removeLast();
  }
}

void _addVisibleToList(
  DeckNode node,
  List<DisplayDeckNode> rows, {
  required bool matchesSearchOrChild,
  required int selectedDeckId,
}) {
  rows.add(
    DisplayDeckNode.from(
      node,
      matchesSearchOrChild: matchesSearchOrChild,
      selectedDeckId: selectedDeckId,
    ),
  );
  if (!node.collapsed) {
    for (final child in node.children) {
      _addVisibleToList(
        child,
        rows,
        matchesSearchOrChild: matchesSearchOrChild,
        selectedDeckId: selectedDeckId,
      );
    }
  }
}
