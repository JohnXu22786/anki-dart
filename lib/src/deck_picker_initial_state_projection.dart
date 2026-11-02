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
 * Source-derived from DeckPickerViewModel.kt:150–171 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'deck_node.dart';

/// Projects `flowOfDeckListInInitialState` for one due-tree emission.
///
/// A missing tree produces null. Otherwise initial state is true only when the
/// tree has exactly the default deck as its sole child and the collection has
/// no cards. The host combines flow emissions and publishes StateFlow values.
bool? projectDeckPickerInitialState(
  DeckNode? dueTree, {
  required bool collectionHasNoCards,
}) {
  if (dueTree == null) {
    return null;
  }
  return onlyHasDefaultDeck(
        dueTree.children.map((child) => child.did).toList(),
      ) &&
      collectionHasNoCards;
}

/// Projects `flowOfCardsDue` for the supplied due-tree and initial-state values.
///
/// The source emits null when the tree is missing or initial state is anything
/// other than exactly false; otherwise it uses the tree's top-level due sum.
/// The host combines flow emissions and publishes StateFlow values.
int? projectDeckPickerCardsDue(
  DeckNode? dueTree, {
  required bool? isInInitialState,
}) {
  if (dueTree == null || isInInitialState != false) {
    return null;
  }
  return dueTree.totalCardsDue();
}

/// Projects `flowOfResizingDividerVisible` for one combined emission.
///
/// A null initial-state value is not equal to true, matching the source's exact
/// nullable comparison. The host combines flow emissions and publishes the
/// result.
bool projectDeckPickerResizingDividerVisible({
  required bool? isInInitialState,
  required bool collectionHasNoCards,
}) => !(isInInitialState == true || collectionHasNoCards);
