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
  group('planBrowserSelectRowsBetween', () {
    test(
      'adds inclusive range rows in order and emits mode before refresh',
      () {
        final transition = planBrowserSelectRowsBetween(
          selectedRows: const [BrowserRowId(10)],
          rowIds: const [
            BrowserRowId(10),
            BrowserRowId(20),
            BrowserRowId(30),
            BrowserRowId(40),
          ],
          startRowId: const BrowserRowId(30),
          endRowId: const BrowserRowId(10),
          isInMultiSelectMode: false,
        );

        expect(transition.selectedRows, const [
          BrowserRowId(10),
          BrowserRowId(20),
          BrowserRowId(30),
        ]);
        expect(transition.changed, isTrue);
        expect(transition.isInMultiSelectMode, isTrue);
        expect(transition.effects, const [
          BrowserRangeSelectionEffect.emitMultiSelectOther,
          BrowserRangeSelectionEffect.refreshSelectedRows,
        ]);
      },
    );

    test('does not emit or change mode when every range row is selected', () {
      final transition = planBrowserSelectRowsBetween(
        selectedRows: const [BrowserRowId(10), BrowserRowId(20)],
        rowIds: const [BrowserRowId(10), BrowserRowId(20)],
        startRowId: const BrowserRowId(10),
        endRowId: const BrowserRowId(20),
        isInMultiSelectMode: false,
      );

      expect(transition.selectedRows, const [
        BrowserRowId(10),
        BrowserRowId(20),
      ]);
      expect(transition.changed, isFalse);
      expect(transition.isInMultiSelectMode, isFalse);
      expect(transition.effects, isEmpty);
    });

    test('keeps source range failure for an absent endpoint', () {
      expect(
        () => planBrowserSelectRowsBetween(
          selectedRows: const [],
          rowIds: const [BrowserRowId(10)],
          startRowId: const BrowserRowId(99),
          endRowId: const BrowserRowId(10),
          isInMultiSelectMode: false,
        ),
        throwsRangeError,
      );
    });
  });
}
