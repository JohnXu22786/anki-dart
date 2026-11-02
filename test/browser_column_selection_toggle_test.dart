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
 * Source-derived cases from AnkiDroid 2.25.3 BrowserColumnSelectionAdapter.kt.
 * Upstream tests cover drag refresh and screenshots, not this click transition.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Browser column selection click toggle', () {
    test('active column moves after the original available heading', () {
      final kinds = [
        BrowserColumnSelectionRowKind.activeHeading,
        BrowserColumnSelectionRowKind.column,
        BrowserColumnSelectionRowKind.column,
        BrowserColumnSelectionRowKind.availableHeading,
        BrowserColumnSelectionRowKind.column,
      ];
      final rows = ['active', 'a', 'b', 'available', 'c'];
      final plan = planBrowserColumnSelectionToggle(
        rowKinds: kinds,
        fromPosition: 1,
      );

      expect(plan.fromPosition, 1);
      expect(plan.availableHeadingPosition, 3);
      expect(plan.isBeforeAvailableHeading, isTrue);

      plan.applyTo(rows);

      expect(rows, ['active', 'b', 'available', 'a', 'c']);
    });

    test('available column moves before the available heading', () {
      final kinds = [
        BrowserColumnSelectionRowKind.activeHeading,
        BrowserColumnSelectionRowKind.column,
        BrowserColumnSelectionRowKind.availableHeading,
        BrowserColumnSelectionRowKind.column,
        BrowserColumnSelectionRowKind.column,
      ];
      final rows = ['active', 'a', 'available', 'b', 'c'];
      final plan = planBrowserColumnSelectionToggle(
        rowKinds: kinds,
        fromPosition: 3,
      );

      expect(plan.availableHeadingPosition, 2);
      expect(plan.isBeforeAvailableHeading, isFalse);

      plan.applyTo(rows);

      expect(rows, ['active', 'a', 'b', 'available', 'c']);
    });

    test('the first available heading supplies the target index', () {
      final kinds = [
        BrowserColumnSelectionRowKind.activeHeading,
        BrowserColumnSelectionRowKind.column,
        BrowserColumnSelectionRowKind.availableHeading,
        BrowserColumnSelectionRowKind.column,
        BrowserColumnSelectionRowKind.availableHeading,
        BrowserColumnSelectionRowKind.column,
      ];
      final rows = ['active', 'a', 'available-1', 'b', 'available-2', 'c'];
      final plan = planBrowserColumnSelectionToggle(
        rowKinds: kinds,
        fromPosition: 3,
      );

      expect(plan.availableHeadingPosition, 2);
      plan.applyTo(rows);

      expect(rows, ['active', 'a', 'b', 'available-1', 'available-2', 'c']);
    });

    test('missing heading keeps -1 and failed insertion follows removal', () {
      final plan = planBrowserColumnSelectionToggle(
        rowKinds: const [
          BrowserColumnSelectionRowKind.activeHeading,
          BrowserColumnSelectionRowKind.column,
          BrowserColumnSelectionRowKind.column,
        ],
        fromPosition: 1,
      );
      final rows = ['a', 'b'];

      expect(plan.availableHeadingPosition, -1);
      expect(plan.isBeforeAvailableHeading, isFalse);
      expect(() => plan.applyTo(rows), throwsRangeError);

      // The pinned adapter removes first, then its negative-index insertion
      // fails, so this malformed state has already lost the moved row.
      expect(rows, ['a']);
    });

    test('invalid source position is passed through and fails before mutation',
        () {
      final plan = planBrowserColumnSelectionToggle(
        rowKinds: const [
          BrowserColumnSelectionRowKind.activeHeading,
          BrowserColumnSelectionRowKind.availableHeading,
        ],
        fromPosition: -1,
      );
      final rows = ['a', 'b'];

      expect(plan.fromPosition, -1);
      expect(plan.availableHeadingPosition, 1);
      expect(() => plan.applyTo(rows), throwsRangeError);
      expect(rows, ['a', 'b']);
    });
  });
}
