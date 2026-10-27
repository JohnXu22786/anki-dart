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
 * Source-derived from CardBrowserViewModel.kt; pinned tests cover Cards and
 * Notes no-selection/single-selection indices, not multi-selection, stale IDs,
 * or duplicate browser rows.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Browser preview starting index', () {
    const rowIds = [BrowserRowId(10), BrowserRowId(20), BrowserRowId(30)];

    test('uses zero when there are no selected rows', () {
      expect(
        browserPreviewStartingIndex(rowIds: rowIds, selectedRows: const []),
        0,
      );
    });

    test('uses zero with multiple selected rows without reordering them', () {
      expect(
        browserPreviewStartingIndex(
          rowIds: rowIds,
          selectedRows: const [BrowserRowId(30), BrowserRowId(10)],
        ),
        0,
      );
    });

    test('uses the position of the one selected row', () {
      expect(
        browserPreviewStartingIndex(
          rowIds: rowIds,
          selectedRows: const [BrowserRowId(20)],
        ),
        1,
      );
    });

    test('preserves negative one when the selected row is stale', () {
      expect(
        browserPreviewStartingIndex(
          rowIds: rowIds,
          selectedRows: const [BrowserRowId(99)],
        ),
        -1,
      );
    });

    test('uses the first matching position for a repeated browser row ID', () {
      expect(
        browserPreviewStartingIndex(
          rowIds: const [BrowserRowId(10), BrowserRowId(20), BrowserRowId(20)],
          selectedRows: const [BrowserRowId(20)],
        ),
        1,
      );
    });
  });
}
