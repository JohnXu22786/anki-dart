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
  group('planBrowserSelectionRestore', () {
    test('filters stale IDs and merges valid rows in pending order', () {
      final transition = planBrowserSelectionRestore(
        selectedRows: const [BrowserRowId(20)],
        pendingSelectionRestore: const [
          BrowserRowId(40),
          BrowserRowId(10),
          BrowserRowId(99),
          BrowserRowId(30),
          BrowserRowId(40),
        ],
        currentRows: const [
          BrowserRowId(10),
          BrowserRowId(20),
          BrowserRowId(30),
          BrowserRowId(40),
        ],
        isInMultiSelectMode: false,
      );

      expect(transition.restoredRows, const [
        BrowserRowId(40),
        BrowserRowId(10),
        BrowserRowId(30),
        BrowserRowId(40),
      ]);
      expect(transition.selectedRows, const [
        BrowserRowId(20),
        BrowserRowId(40),
        BrowserRowId(10),
        BrowserRowId(30),
      ]);
      expect(transition.changed, isTrue);
      expect(transition.isInMultiSelectMode, isTrue);
      expect(transition.effects, const [
        BrowserSelectionRestoreEffect.emitMultiSelectOther,
        BrowserSelectionRestoreEffect.refreshSelectedRows,
      ]);
      expect(transition.clearsPendingSelectionRestore, isTrue);
    });

    test('stale or already-selected IDs produce no effects', () {
      final transition = planBrowserSelectionRestore(
        selectedRows: const [BrowserRowId(10), BrowserRowId(20)],
        pendingSelectionRestore: const [BrowserRowId(20), BrowserRowId(99)],
        currentRows: const [BrowserRowId(10), BrowserRowId(20)],
        isInMultiSelectMode: false,
      );

      expect(transition.restoredRows, const [BrowserRowId(20)]);
      expect(transition.selectedRows, const [
        BrowserRowId(10),
        BrowserRowId(20),
      ]);
      expect(transition.changed, isFalse);
      expect(transition.isInMultiSelectMode, isFalse);
      expect(transition.effects, isEmpty);
      expect(transition.clearsPendingSelectionRestore, isTrue);
    });

    test(
      'empty saved state is still consumed without changing the selection',
      () {
        final transition = planBrowserSelectionRestore(
          selectedRows: const [BrowserRowId(10)],
          pendingSelectionRestore: const [],
          currentRows: const [BrowserRowId(10), BrowserRowId(20)],
          isInMultiSelectMode: true,
        );

        expect(transition.selectedRows, const [BrowserRowId(10)]);
        expect(transition.changed, isFalse);
        expect(transition.isInMultiSelectMode, isTrue);
        expect(transition.effects, isEmpty);
        expect(transition.clearsPendingSelectionRestore, isTrue);
      },
    );
  });
}
