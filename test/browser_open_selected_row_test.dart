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
 * Source-derived from CardBrowserViewModel.kt; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser row to open in editor', () {
    final first = BrowserRowId(10);
    final second = BrowserRowId(20);

    test('uses the first current row outside multi-select mode', () {
      expect(
        browserRowToOpenEditor(
          rowIds: [first, second],
          selectedRows: [second],
          isInMultiSelectMode: false,
        ),
        first,
      );
    });

    test('uses first selected row order in multi-select mode', () {
      expect(
        browserRowToOpenEditor(
          rowIds: [first, second],
          selectedRows: [second, first],
          isInMultiSelectMode: true,
        ),
        second,
      );
    });

    test('does not fall back when multi-select has no selection', () {
      expect(
        browserRowToOpenEditor(
          rowIds: [first],
          selectedRows: const [],
          isInMultiSelectMode: true,
        ),
        isNull,
      );
    });

    test('returns null when there are no rows even with a selection', () {
      expect(
        browserRowToOpenEditor(
          rowIds: const [],
          selectedRows: [second],
          isInMultiSelectMode: true,
        ),
        isNull,
      );
    });

    test('does not validate selected IDs against the current row list', () {
      expect(
        browserRowToOpenEditor(
          rowIds: [first],
          selectedRows: [second],
          isInMultiSelectMode: true,
        ),
        second,
      );
    });
  });
}
