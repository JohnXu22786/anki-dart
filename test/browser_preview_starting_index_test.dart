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
  group('Browser preview payload', () {
    const rowIds = [BrowserRowId(10), BrowserRowId(20), BrowserRowId(30)];

    test('uses selected card IDs in order for multiple selected rows', () {
      final selectedCardIds = [303, 101, 202];
      final rowCardIds = [10, 20, 30];

      final payload = browserPreviewPayload(
        rowIds: rowIds,
        selectedRows: const [BrowserRowId(30), BrowserRowId(10)],
        oneCardPerRowIds: rowCardIds,
        selectedCardIds: selectedCardIds,
      );

      expect(payload.currentIndex, 0);
      expect(payload.cardIds, same(selectedCardIds));
      expect(payload.cardIds, [303, 101, 202]);
    });

    test('uses one-card-per-row IDs and zero when no row is selected', () {
      final rowCardIds = [30, 10, 20];

      final payload = browserPreviewPayload(
        rowIds: rowIds,
        selectedRows: const [],
        oneCardPerRowIds: rowCardIds,
        selectedCardIds: const [999],
      );

      expect(payload.currentIndex, 0);
      expect(payload.cardIds, same(rowCardIds));
      expect(payload.cardIds, [30, 10, 20]);
    });

    test('uses one-card-per-row IDs and the selected row index', () {
      final rowCardIds = [30, 10, 20];

      final payload = browserPreviewPayload(
        rowIds: rowIds,
        selectedRows: const [BrowserRowId(20)],
        oneCardPerRowIds: rowCardIds,
        selectedCardIds: const [999],
      );

      expect(payload.currentIndex, 1);
      expect(payload.cardIds, same(rowCardIds));
      expect(payload.cardIds, [30, 10, 20]);
    });

    test('preserves stale selected row index instead of defaulting it', () {
      final payload = browserPreviewPayload(
        rowIds: rowIds,
        selectedRows: const [BrowserRowId(99)],
        oneCardPerRowIds: const [10, 20, 30],
        selectedCardIds: const [999],
      );

      expect(payload.currentIndex, -1);
      expect(payload.cardIds, [10, 20, 30]);
    });
  });

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
