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
  group('planBrowserSelectionExport', () {
    test('returns null when there are no selected rows', () {
      expect(
        planBrowserSelectionExport(
          mode: BrowserColumnMode.cards,
          selectedRows: const [],
        ),
        isNull,
      );
    });

    test('uses Cards export kind and returns card IDs in source order', () {
      final plan = planBrowserSelectionExport(
        mode: BrowserColumnMode.cards,
        selectedRows: const [
          BrowserRowId(81),
          BrowserRowId(24),
        ],
      );

      expect(plan?.type, BrowserSelectionExportType.cards);
      expect(plan?.ids, [81, 24]);
    });

    test('uses Notes export kind and returns raw note IDs', () {
      final plan = planBrowserSelectionExport(
        mode: BrowserColumnMode.notes,
        selectedRows: const [BrowserRowId(72)],
      );

      expect(plan?.type, BrowserSelectionExportType.notes);
      expect(plan?.ids, [72]);
    });

    test('copies selected IDs while preserving their iteration order', () {
      final selectedRows = [
        const BrowserRowId(91),
        const BrowserRowId(15),
      ];

      final plan = planBrowserSelectionExport(
        mode: BrowserColumnMode.cards,
        selectedRows: selectedRows,
      );
      selectedRows.insert(0, const BrowserRowId(100));

      expect(plan?.ids, [91, 15]);
    });
  });
}
