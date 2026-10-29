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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('selected browser row count', () {
    test('empty selection has count zero and no selected rows', () {
      expect(browserSelectedRowCount(const []), 0);
      expect(browserHasSelectedAnyRows(const []), isFalse);
    });

    test('counts distinct IDs using source set semantics', () {
      const selectedRows = [
        BrowserRowId(12),
        BrowserRowId(8),
        BrowserRowId(12),
      ];

      expect(browserSelectedRowCount(selectedRows), 2);
      expect(browserHasSelectedAnyRows(selectedRows), isTrue);
    });

    test('a single selected row reports count one', () {
      const selectedRows = [BrowserRowId(7)];

      expect(browserSelectedRowCount(selectedRows), 1);
      expect(browserHasSelectedAnyRows(selectedRows), isTrue);
    });
  });
}
