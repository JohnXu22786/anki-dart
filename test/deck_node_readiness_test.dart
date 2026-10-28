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
  group('DeckNode.hasCardsReadyToStudy', () {
    test('requires at least one strictly positive count', () {
      expect(_node(newCount: 1).hasCardsReadyToStudy(), isTrue);
      expect(_node(lrnCount: 1).hasCardsReadyToStudy(), isTrue);
      expect(_node(revCount: 1).hasCardsReadyToStudy(), isTrue);
      expect(
        _node(newCount: -1, lrnCount: 0, revCount: -2)
            .hasCardsReadyToStudy(),
        isFalse,
      );
    });
  });

  test('toString preserves source field order and decimal values', () {
    final node = DeckNode(
      did: -1234567890123456789,
      fullDeckName: 'Parent::Deck, %s',
      depth: 0,
      revCount: -2147483648,
      lrnCount: 0,
      newCount: 2147483647,
    );

    expect(
      node.toString(),
      'Parent::Deck, %s, -1234567890123456789, -2147483648, 0, 2147483647',
    );
  });
}

DeckNode _node({int newCount = 0, int lrnCount = 0, int revCount = 0}) =>
    DeckNode(
      did: 1,
      fullDeckName: 'Deck',
      depth: 0,
      newCount: newCount,
      lrnCount: lrnCount,
      revCount: revCount,
    );
