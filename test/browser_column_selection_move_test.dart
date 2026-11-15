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
 * Behavioral references: BrowserColumnSelectionAdapter.kt and MutableList.kt
 * in AnkiDroid 2.25.3; the callback assertions below are source-derived because
 * upstream tests exercise RecyclerView drop-refresh timing instead.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Browser Column Selection move plan', () {
    test('usage rows cannot start a drag while other row types move vertically',
        () {
      expect(
        browserColumnSelectionDragMode(isUsageItem: true),
        BrowserColumnSelectionDragMode.disabled,
      );
      expect(
        browserColumnSelectionDragMode(isUsageItem: false),
        BrowserColumnSelectionDragMode.vertical,
      );
    });

    test('target position zero rejects the move before producing swaps', () {
      final plan = planBrowserColumnSelectionMove(
        fromPosition: 3,
        toPosition: 0,
      );

      expect(plan.accepted, isFalse);
      expect(plan.fromPosition, 3);
      expect(plan.toPosition, 0);
      expect(plan.adjacentSwaps, isEmpty);
    });

    test('forward moves emit ascending adjacent swaps', () {
      final plan = planBrowserColumnSelectionMove(
        fromPosition: 1,
        toPosition: 4,
      );

      expect(plan.accepted, isTrue);
      expect(plan.adjacentSwaps, const [
        BrowserColumnPositionSwap(1, 2),
        BrowserColumnPositionSwap(2, 3),
        BrowserColumnPositionSwap(3, 4),
      ]);
    });

    test('backward moves emit descending adjacent swaps', () {
      final plan = planBrowserColumnSelectionMove(
        fromPosition: 4,
        toPosition: 1,
      );

      expect(plan.accepted, isTrue);
      expect(plan.adjacentSwaps, const [
        BrowserColumnPositionSwap(4, 3),
        BrowserColumnPositionSwap(3, 2),
        BrowserColumnPositionSwap(2, 1),
      ]);
    });

    test('same-position moves are accepted without swaps', () {
      final plan = planBrowserColumnSelectionMove(
        fromPosition: 2,
        toPosition: 2,
      );

      expect(plan.accepted, isTrue);
      expect(plan.adjacentSwaps, isEmpty);
    });

    test('positions are passed through without normalization or validation',
        () {
      final plan = planBrowserColumnSelectionMove(
        fromPosition: -1,
        toPosition: 2,
      );

      expect(plan.accepted, isTrue);
      expect(plan.adjacentSwaps, const [
        BrowserColumnPositionSwap(-1, 0),
        BrowserColumnPositionSwap(0, 1),
        BrowserColumnPositionSwap(1, 2),
      ]);
    });
  });
}
