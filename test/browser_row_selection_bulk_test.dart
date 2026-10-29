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
  group('planBrowserSelectAll', () {
    test('adds distinct rows in input order and emits mode before refresh', () {
      final before = [const BrowserRowId(10), const BrowserRowId(20)];
      final available = [
        const BrowserRowId(20),
        const BrowserRowId(30),
        const BrowserRowId(40),
        const BrowserRowId(30),
      ];

      final transition = planBrowserSelectAll(
        selectedRows: before,
        availableRows: available,
        isInMultiSelectMode: false,
      );

      expect(transition.changed, isTrue);
      expect(transition.selectedRows, [
        const BrowserRowId(10),
        const BrowserRowId(20),
        const BrowserRowId(30),
        const BrowserRowId(40),
      ]);
      expect(before, [const BrowserRowId(10), const BrowserRowId(20)]);
      expect(transition.isInMultiSelectMode, isTrue);
      expect(transition.previouslySelectedRows, isNull);
      expect(transition.effects, [
        BrowserBulkSelectionEffect.emitMultiSelectOther,
        BrowserBulkSelectionEffect.refreshSelectedRows,
      ]);
    });

    test('does nothing when addAll would add no distinct rows', () {
      final transition = planBrowserSelectAll(
        selectedRows: const [BrowserRowId(10), BrowserRowId(20)],
        availableRows: const [
          BrowserRowId(20),
          BrowserRowId(10),
          BrowserRowId(20)
        ],
        isInMultiSelectMode: true,
      );

      expect(transition.changed, isFalse);
      expect(
          transition.selectedRows, const [BrowserRowId(10), BrowserRowId(20)]);
      expect(transition.isInMultiSelectMode, isTrue);
      expect(transition.effects, isEmpty);
    });
  });

  group('planBrowserSelectNone', () {
    test('snapshots selection, clears rows, and refreshes without ending mode',
        () {
      final transition = planBrowserSelectNone(
        selectedRows: const [
          BrowserRowId(30),
          BrowserRowId(10),
          BrowserRowId(20),
        ],
        isInMultiSelectMode: true,
      );

      expect(transition.changed, isTrue);
      expect(transition.previouslySelectedRows, const [
        BrowserRowId(30),
        BrowserRowId(10),
        BrowserRowId(20),
      ]);
      expect(transition.selectedRows, isEmpty);
      expect(transition.isInMultiSelectMode, isTrue);
      expect(
          transition.effects, [BrowserBulkSelectionEffect.refreshSelectedRows]);
    });

    test('does nothing when selection is already empty', () {
      final transition = planBrowserSelectNone(
        selectedRows: const [],
        isInMultiSelectMode: true,
      );

      expect(transition.changed, isFalse);
      expect(transition.previouslySelectedRows, isNull);
      expect(transition.selectedRows, isEmpty);
      expect(transition.isInMultiSelectMode, isTrue);
      expect(transition.effects, isEmpty);
    });
  });

  group('planBrowserEndMultiSelectMode', () {
    test('snapshots rows in insertion order and retains the cause object', () {
      final reason = Object();
      final transition = planBrowserEndMultiSelectMode(
        selectedRows: const [
          BrowserRowId(30),
          BrowserRowId(10),
          BrowserRowId(30),
          BrowserRowId(20),
        ],
        reason: reason,
      );

      expect(transition.previouslySelectedRows, const [
        BrowserRowId(30),
        BrowserRowId(10),
        BrowserRowId(20),
      ]);
      expect(transition.selectedRows, isEmpty);
      expect(transition.isInMultiSelectMode, isFalse);
      expect(identical(transition.reason, reason), isTrue);
    });

    test('keeps an empty prior snapshot distinct from no snapshot', () {
      final transition = planBrowserEndMultiSelectMode(
        selectedRows: const [],
        reason: 'navigate back',
      );

      expect(transition.previouslySelectedRows, isEmpty);
      expect(transition.selectedRows, isEmpty);
      expect(transition.isInMultiSelectMode, isFalse);
      expect(transition.reason, 'navigate back');
    });
  });

  group('planBrowserToggleSelectAllOrNone', () {
    test('uses the supplied cached state to select all', () {
      final transition = planBrowserToggleSelectAllOrNone(
        state: BrowserSelectAllOrNoneState.selectAll,
        selectedRows: const [BrowserRowId(10)],
        availableRows: const [BrowserRowId(10), BrowserRowId(20)],
        isInMultiSelectMode: false,
      );

      expect(
          transition.selectedRows, const [BrowserRowId(10), BrowserRowId(20)]);
      expect(transition.effects, [
        BrowserBulkSelectionEffect.emitMultiSelectOther,
        BrowserBulkSelectionEffect.refreshSelectedRows,
      ]);
    });

    test('uses the supplied cached state to select none', () {
      final transition = planBrowserToggleSelectAllOrNone(
        state: BrowserSelectAllOrNoneState.selectNone,
        selectedRows: const [BrowserRowId(10), BrowserRowId(20)],
        availableRows: const [
          BrowserRowId(10),
          BrowserRowId(20),
          BrowserRowId(30)
        ],
        isInMultiSelectMode: true,
      );

      expect(transition.selectedRows, isEmpty);
      expect(transition.previouslySelectedRows, const [
        BrowserRowId(10),
        BrowserRowId(20),
      ]);
      expect(transition.isInMultiSelectMode, isTrue);
      expect(
          transition.effects, [BrowserBulkSelectionEffect.refreshSelectedRows]);
    });
  });
}
