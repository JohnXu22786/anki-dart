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
 * Source-derived from CardBrowserFragment.kt; pane-state tests do not assert
 * the positions notified by onPaneRowChanged.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Browser pane-row notification positions', () {
    test('returns previous then new row positions', () {
      expect(
        browserPaneRowNotificationPositions(
          previousPaneRow: const BrowserRowId(20),
          newPaneRow: const BrowserRowId(30),
          rowIds: const [BrowserRowId(10), BrowserRowId(20), BrowserRowId(30)],
        ),
        [1, 2],
      );
    });

    test('omits null and duplicate pane IDs in source order', () {
      expect(
        browserPaneRowNotificationPositions(
          previousPaneRow: const BrowserRowId(20),
          newPaneRow: const BrowserRowId(20),
          rowIds: const [BrowserRowId(20), BrowserRowId(30)],
        ),
        [0],
      );
      expect(
        browserPaneRowNotificationPositions(
          previousPaneRow: null,
          newPaneRow: const BrowserRowId(30),
          rowIds: const [BrowserRowId(20), BrowserRowId(30)],
        ),
        [1],
      );
      expect(
        browserPaneRowNotificationPositions(
          previousPaneRow: null,
          newPaneRow: null,
          rowIds: const [BrowserRowId(20)],
        ),
        isEmpty,
      );
    });

    test('omits IDs with no current position and uses first duplicate row', () {
      expect(
        browserPaneRowNotificationPositions(
          previousPaneRow: const BrowserRowId(40),
          newPaneRow: const BrowserRowId(20),
          rowIds: const [BrowserRowId(20), BrowserRowId(20), BrowserRowId(30)],
        ),
        [0],
      );
    });
  });
}
