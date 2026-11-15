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
 * Source-derived from AnkiDroid 2.25.3 CardBrowserViewModel.kt and List.kt;
 * upstream tests cover the generic list helper but not getPositionOfId itself.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Browser row position lookup', () {
    test('returns the first matching row using value equality', () {
      const rows = [BrowserRowId(10), BrowserRowId(20), BrowserRowId(10)];

      expect(
        browserRowPositionOfId(rowIds: rows, rowId: const BrowserRowId(10)),
        0,
      );
      expect(
        browserRowPositionOfId(rowIds: rows, rowId: const BrowserRowId(20)),
        1,
      );
    });

    test('returns null for a missing ID or an empty row list', () {
      expect(
        browserRowPositionOfId(
          rowIds: const [BrowserRowId(10)],
          rowId: const BrowserRowId(30),
        ),
        isNull,
      );
      expect(
        browserRowPositionOfId(rowIds: const [], rowId: const BrowserRowId(10)),
        isNull,
      );
    });
  });
}
