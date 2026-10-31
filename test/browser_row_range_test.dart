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
 * Source-derived from CardBrowserViewModel.kt; upstream tests verify range
 * selection effects but not ID-to-range projection or invalid endpoint errors.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Browser row range between IDs', () {
    const rows = [
      BrowserRowId(10),
      BrowserRowId(20),
      BrowserRowId(30),
      BrowserRowId(40),
    ];

    test('returns the inclusive source-ordered slice', () {
      expect(
        browserRowRangeBetweenIds(
          rowIds: rows,
          startRowId: const BrowserRowId(20),
          endRowId: const BrowserRowId(40),
        ),
        [
          const BrowserRowId(20),
          const BrowserRowId(30),
          const BrowserRowId(40),
        ],
      );

      const rowsWithRepeatedEndpoints = [
        BrowserRowId(10),
        BrowserRowId(20),
        BrowserRowId(30),
        BrowserRowId(20),
        BrowserRowId(40),
        BrowserRowId(40),
      ];
      expect(
        browserRowRangeBetweenIds(
          rowIds: rowsWithRepeatedEndpoints,
          startRowId: const BrowserRowId(20),
          endRowId: const BrowserRowId(40),
        ),
        [
          const BrowserRowId(20),
          const BrowserRowId(30),
          const BrowserRowId(20),
          const BrowserRowId(40),
        ],
      );
    });

    test('orders rows by position when endpoint arguments are reversed', () {
      expect(
        browserRowRangeBetweenIds(
          rowIds: rows,
          startRowId: const BrowserRowId(40),
          endRowId: const BrowserRowId(20),
        ),
        [
          const BrowserRowId(20),
          const BrowserRowId(30),
          const BrowserRowId(40),
        ],
      );
    });

    test('includes the row when both endpoint IDs resolve to the same row', () {
      expect(
        browserRowRangeBetweenIds(
          rowIds: rows,
          startRowId: const BrowserRowId(30),
          endRowId: const BrowserRowId(30),
        ),
        [const BrowserRowId(30)],
      );
    });

    test('preserves index failure for missing endpoints', () {
      expect(
        () => browserRowRangeBetweenIds(
          rowIds: rows,
          startRowId: const BrowserRowId(99),
          endRowId: const BrowserRowId(20),
        ),
        throwsRangeError,
      );
      expect(
        () => browserRowRangeBetweenIds(
          rowIds: rows,
          startRowId: const BrowserRowId(20),
          endRowId: const BrowserRowId(99),
        ),
        throwsRangeError,
      );
    });
  });
}
