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
 * Source-derived from CardBrowserViewModel.kt; fragment tests cover successful
 * editor entry, not the row-choice boundaries.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Browser row to edit', () {
    test('empty browser rows return null before considering selected IDs', () {
      expect(
        browserRowToEdit(
          rowIds: const [],
          selectedRows: const [BrowserRowId(99)],
          isInMultiSelectMode: true,
        ),
        isNull,
      );
    });

    test(
      'multi-select returns the first selected ID without validating it',
      () {
        expect(
          browserRowToEdit(
            rowIds: const [BrowserRowId(10), BrowserRowId(20)],
            selectedRows: const [BrowserRowId(99), BrowserRowId(10)],
            isInMultiSelectMode: true,
          ),
          const BrowserRowId(99),
        );
      },
    );

    test('multi-select without a selected row returns null', () {
      expect(
        browserRowToEdit(
          rowIds: const [BrowserRowId(10)],
          selectedRows: const [],
          isInMultiSelectMode: true,
        ),
        isNull,
      );
    });

    test('normal mode returns the first browser row and ignores selection', () {
      expect(
        browserRowToEdit(
          rowIds: const [BrowserRowId(10), BrowserRowId(20)],
          selectedRows: const [BrowserRowId(20)],
          isInMultiSelectMode: false,
        ),
        const BrowserRowId(10),
      );
    });
  });
}
