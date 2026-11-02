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
  group('BrowserRowSelection', () {
    test('matches the source value equality over row and offset', () {
      const selection = BrowserRowSelection(
        rowId: BrowserRowId(12),
        topOffset: 8,
      );

      expect(
        selection,
        const BrowserRowSelection(rowId: BrowserRowId(12), topOffset: 8),
      );
      expect(
        selection.hashCode,
        const BrowserRowSelection(rowId: BrowserRowId(12), topOffset: 8)
            .hashCode,
      );
      expect(
        selection,
        isNot(
          const BrowserRowSelection(rowId: BrowserRowId(12), topOffset: 9),
        ),
      );
    });
  });

  group('toggleBrowserRowSelection', () {
    test('appends an unselected row and emits RowSelected', () {
      final before = [const BrowserRowId(10), const BrowserRowId(20)];
      final transition = toggleBrowserRowSelection(
        selectedRows: before,
        selection: const BrowserRowSelection(
          rowId: BrowserRowId(30),
          topOffset: 5,
        ),
        isInMultiSelectMode: false,
      );

      expect(transition.selectedRows, [
        const BrowserRowId(10),
        const BrowserRowId(20),
        const BrowserRowId(30),
      ]);
      expect(before, [const BrowserRowId(10), const BrowserRowId(20)]);
      expect(
        transition.modeChange,
        const BrowserRowSelectionModeChange(
          cause: BrowserRowSelectionModeCause.rowSelected,
          selection: BrowserRowSelection(
            rowId: BrowserRowId(30),
            topOffset: 5,
          ),
        ),
      );
      expect(transition.isInMultiSelectMode, isTrue);
      expect(transition.lastSelectedRowId, const BrowserRowId(30));
      expect(transition.refreshSelectedRows, isTrue);
    });

    test('removes one row without a mode event while others remain', () {
      final transition = toggleBrowserRowSelection(
        selectedRows: const [
          BrowserRowId(10),
          BrowserRowId(20),
          BrowserRowId(30),
        ],
        selection: const BrowserRowSelection(
          rowId: BrowserRowId(20),
          topOffset: 3,
        ),
        isInMultiSelectMode: true,
      );

      expect(
        transition.selectedRows,
        [const BrowserRowId(10), const BrowserRowId(30)],
      );
      expect(transition.modeChange, isNull);
      expect(transition.isInMultiSelectMode, isTrue);
      expect(transition.lastSelectedRowId, const BrowserRowId(20));
      expect(transition.refreshSelectedRows, isTrue);
    });

    test('removing the final row emits DeselectRow and exits selection mode',
        () {
      const selection = BrowserRowSelection(
        rowId: BrowserRowId(20),
        topOffset: 3,
      );
      final transition = toggleBrowserRowSelection(
        selectedRows: const [BrowserRowId(20)],
        selection: selection,
        isInMultiSelectMode: true,
      );

      expect(transition.selectedRows, isEmpty);
      expect(
        transition.modeChange,
        const BrowserRowSelectionModeChange(
          cause: BrowserRowSelectionModeCause.deselectRow,
          selection: selection,
        ),
      );
      expect(transition.isInMultiSelectMode, isFalse);
      expect(transition.refreshSelectedRows, isTrue);
    });

    test('adding after select-none keeps the active mode', () {
      final transition = toggleBrowserRowSelection(
        selectedRows: const [],
        selection: const BrowserRowSelection(
          rowId: BrowserRowId(7),
          topOffset: 0,
        ),
        isInMultiSelectMode: true,
      );

      expect(transition.selectedRows, [const BrowserRowId(7)]);
      expect(transition.modeChange?.resultedInMultiSelect, isTrue);
      expect(transition.isInMultiSelectMode, isTrue);
      expect(transition.refreshSelectedRows, isTrue);
    });
  });
}
