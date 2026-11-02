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
 * Source-derived from CardBrowserViewModel.generateExpensiveSavedState() in
 * AnkiDroid 2.25.3; its pinned tests do not assert the exact ordered saved IDs.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Browser saved selection payload', () {
    test('pending restore wins and does not mutate either selection', () {
      final pending = [
        const BrowserRowId(31),
        const BrowserRowId(12),
        const BrowserRowId(31),
      ];
      final selected = [const BrowserRowId(90)];

      final payload = browserSavedSelectionPayloadIds(
        pendingSelectionRestore: pending,
        selectedRows: selected,
      );

      expect(payload, [31, 12, 31]);
      expect(pending, [
        const BrowserRowId(31),
        const BrowserRowId(12),
        const BrowserRowId(31),
      ]);
      expect(selected, [const BrowserRowId(90)]);
    });

    test('empty restore snapshots selected rows in order with duplicates', () {
      final selected = [
        const BrowserRowId(8),
        const BrowserRowId(4),
        const BrowserRowId(8),
      ];

      final payload = browserSavedSelectionPayloadIds(
        pendingSelectionRestore: const [],
        selectedRows: selected,
      );

      expect(payload, [8, 4, 8]);
      expect(selected, [
        const BrowserRowId(8),
        const BrowserRowId(4),
        const BrowserRowId(8),
      ]);
    });

    test('empty restore and selected rows produce no payload', () {
      expect(
        browserSavedSelectionPayloadIds(
          pendingSelectionRestore: const [],
          selectedRows: const [],
        ),
        isNull,
      );
    });
  });
}
