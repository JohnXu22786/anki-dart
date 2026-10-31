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

import 'deck_filters.dart';
import 'deck_node.dart';
import 'display_deck_node.dart';

/// The flattened deck rows and subdeck flag emitted by the deck picker.
final class FlattenedDeckList {
  FlattenedDeckList({
    required Iterable<DisplayDeckNode> data,
    required this.hasSubDecks,
  }) : data = List.unmodifiable(data);

  /// The source's empty value for a missing due tree.
  static final empty = FlattenedDeckList(data: const [], hasSubDecks: false);

  final List<DisplayDeckNode> data;
  final bool hasSubDecks;

  @override
  bool operator ==(Object other) =>
      other is FlattenedDeckList &&
      other.hasSubDecks == hasSubDecks &&
      _sameData(other.data);

  @override
  int get hashCode => Object.hash(Object.hashAll(data), hasSubDecks);

  bool _sameData(List<DisplayDeckNode> otherData) {
    if (data.length != otherData.length) {
      return false;
    }
    for (var i = 0; i < data.length; i++) {
      if (data[i] != otherData[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Projects one due-tree emission into the deck picker's flattened list.
///
/// A missing tree returns the source empty value. The host resolves the
/// selected deck ID from its collection and supplies it here; it retains the
/// combined flow, StateFlow, logging, and UI behavior.
FlattenedDeckList projectFlattenedDeckList(
  DeckNode? dueTree,
  DeckFilters filter, {
  required int selectedDeckId,
}) {
  if (dueTree == null) {
    return FlattenedDeckList.empty;
  }

  return FlattenedDeckList(
    data: dueTree.filterAndFlattenDisplay(
      filter,
      selectedDeckId: selectedDeckId,
    ),
    hasSubDecks: dueTree.children.any((child) => child.children.isNotEmpty),
  );
}
