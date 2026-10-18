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

class DeckNode {
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
    this.isSyntheticDeck = false,
  }) : _lastDeckNameComponent = lastDeckNameComponent;

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

  String get lastDeckNameComponent =>
      _lastDeckNameComponent ?? fullDeckName.split('::').last;
}
