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
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('browser row interaction directives', () {
    const selection = BrowserRowSelection(
      rowId: BrowserRowId(30),
      topOffset: 7,
    );

    test(
      'long-press and right-click select a range in active multi-select',
      () {
        const expected = BrowserRowRangeSelectionDirective(
          startRowId: BrowserRowId(10),
          endRowId: BrowserRowId(30),
        );

        expect(
          planBrowserRowLongPress(
            selection: selection,
            isInMultiSelectMode: true,
            lastSelectedRowId: const BrowserRowId(10),
          ),
          expected,
        );
        expect(
          planBrowserRowRightClick(
            selection: selection,
            isInMultiSelectMode: true,
            lastSelectedRowId: const BrowserRowId(10),
          ),
          expected,
        );
      },
    );

    test('both interactions toggle when multi-select has no last row', () {
      final expected = BrowserRowToggleSelectionDirective(selection);

      expect(
        planBrowserRowLongPress(
          selection: selection,
          isInMultiSelectMode: true,
          lastSelectedRowId: null,
        ),
        expected,
      );
      expect(
        planBrowserRowRightClick(
          selection: selection,
          isInMultiSelectMode: true,
          lastSelectedRowId: null,
        ),
        expected,
      );
    });

    test(
      'both interactions toggle outside multi-select even with a last row',
      () {
        final expected = BrowserRowToggleSelectionDirective(selection);

        expect(
          planBrowserRowLongPress(
            selection: selection,
            isInMultiSelectMode: false,
            lastSelectedRowId: const BrowserRowId(10),
          ),
          expected,
        );
        expect(
          planBrowserRowRightClick(
            selection: selection,
            isInMultiSelectMode: false,
            lastSelectedRowId: const BrowserRowId(10),
          ),
          expected,
        );
      },
    );
  });
}
