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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from AnkiDroid 2.25.3 CardBrowserViewModel.kt;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser selected-column replacement', () {
    test('replaces the column matching the selected heading key', () {
      final activeColumns = [
        BrowserColumn.question,
        BrowserColumn.deck,
        BrowserColumn.tags,
      ];

      final replacement = replaceBrowserSelectedColumn(
        activeColumns: activeColumns,
        selectedColumnKey: BrowserColumn.deck.key,
        replacementColumn: BrowserColumn.due,
      );

      expect(replacement, [
        BrowserColumn.question,
        BrowserColumn.due,
        BrowserColumn.tags,
      ]);
    });

    test('replaces every active entry with a repeated selected key', () {
      final replacement = replaceBrowserSelectedColumn(
        activeColumns: [
          BrowserColumn.deck,
          BrowserColumn.question,
          BrowserColumn.deck,
        ],
        selectedColumnKey: BrowserColumn.deck.key,
        replacementColumn: BrowserColumn.due,
      );

      expect(replacement, [
        BrowserColumn.due,
        BrowserColumn.question,
        BrowserColumn.due,
      ]);
    });

    test('preserves original order across matching and unaffected entries', () {
      final replacement = replaceBrowserSelectedColumn(
        activeColumns: [
          BrowserColumn.tags,
          BrowserColumn.deck,
          BrowserColumn.question,
          BrowserColumn.deck,
          BrowserColumn.answer,
        ],
        selectedColumnKey: BrowserColumn.deck.key,
        replacementColumn: BrowserColumn.due,
      );

      expect(replacement, [
        BrowserColumn.tags,
        BrowserColumn.due,
        BrowserColumn.question,
        BrowserColumn.due,
        BrowserColumn.answer,
      ]);
    });

    test('no match preserves content and still returns a copied list', () {
      final activeColumns = [BrowserColumn.question, BrowserColumn.tags];

      final replacement = replaceBrowserSelectedColumn(
        activeColumns: activeColumns,
        selectedColumnKey: BrowserColumn.deck.key,
        replacementColumn: BrowserColumn.due,
      );

      expect(replacement, activeColumns);
      expect(replacement, isNot(same(activeColumns)));
    });
  });
}
