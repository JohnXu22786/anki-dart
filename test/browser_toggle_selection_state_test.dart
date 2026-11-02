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
  group('projectBrowserSelectAllOrNoneState', () {
    test('initial state is SELECT_NONE before a flow emission', () {
      expect(
        initialBrowserSelectAllOrNoneState,
        BrowserSelectAllOrNoneState.selectNone,
      );
    });

    test('selection is hidden when multi-select mode is inactive', () {
      expect(
        projectBrowserSelectAllOrNoneState(
          selectedRows: const [BrowserRowId(1), BrowserRowId(2)],
          isInMultiSelectMode: false,
          rowCount: 2,
        ),
        BrowserSelectAllOrNoneState.selectAll,
      );
    });

    test('uses the source greater-than-or-equal row-count boundary', () {
      expect(
        projectBrowserSelectAllOrNoneState(
          selectedRows: const [BrowserRowId(1)],
          isInMultiSelectMode: true,
          rowCount: 2,
        ),
        BrowserSelectAllOrNoneState.selectAll,
      );
      expect(
        projectBrowserSelectAllOrNoneState(
          selectedRows: const [BrowserRowId(1), BrowserRowId(2)],
          isInMultiSelectMode: true,
          rowCount: 2,
        ),
        BrowserSelectAllOrNoneState.selectNone,
      );
      expect(
        projectBrowserSelectAllOrNoneState(
          selectedRows: const [
            BrowserRowId(1),
            BrowserRowId(2),
            BrowserRowId(3),
          ],
          isInMultiSelectMode: true,
          rowCount: 2,
        ),
        BrowserSelectAllOrNoneState.selectNone,
      );
    });

    test('zero and negative row counts follow the direct source comparison',
        () {
      expect(
        projectBrowserSelectAllOrNoneState(
          selectedRows: const [],
          isInMultiSelectMode: true,
          rowCount: 0,
        ),
        BrowserSelectAllOrNoneState.selectNone,
      );
      expect(
        projectBrowserSelectAllOrNoneState(
          selectedRows: const [],
          isInMultiSelectMode: true,
          rowCount: -1,
        ),
        BrowserSelectAllOrNoneState.selectNone,
      );
    });

    test('duplicate row IDs count once like the source selected-row Set', () {
      expect(
        projectBrowserSelectAllOrNoneState(
          selectedRows: const [
            BrowserRowId(1),
            BrowserRowId(1),
            BrowserRowId(2),
            BrowserRowId(2),
          ],
          isInMultiSelectMode: true,
          rowCount: 3,
        ),
        BrowserSelectAllOrNoneState.selectAll,
      );
    });
  });
}
