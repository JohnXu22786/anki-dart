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
  group('browserEditorCardIds', () {
    test(
      'unresolved row returns empty before using sibling or selected IDs',
      () {
        final siblings = [101, 102];
        final selected = [201, 202];

        final result = browserEditorCardIds(
          resolvedRowCardId: null,
          mode: BrowserColumnMode.notes,
          isInMultiSelectMode: true,
          noteCardIds: siblings,
          selectedCardIds: selected,
        );

        expect(result, isEmpty);
        expect(result, isNot(same(siblings)));
        expect(result, isNot(same(selected)));
      },
    );

    test('Notes mode returns the exact sibling IDs in source order', () {
      final siblings = [103, 101, 102];

      final result = browserEditorCardIds(
        resolvedRowCardId: 101,
        mode: BrowserColumnMode.notes,
        isInMultiSelectMode: false,
        noteCardIds: siblings,
        selectedCardIds: [201],
      );

      expect(result, [103, 101, 102]);
      expect(result, same(siblings));
    });

    test(
      'Cards multi-select returns the exact selected IDs in source order',
      () {
        final selected = [205, 203, 204];

        final result = browserEditorCardIds(
          resolvedRowCardId: 203,
          mode: BrowserColumnMode.cards,
          isInMultiSelectMode: true,
          noteCardIds: [203, 999],
          selectedCardIds: selected,
        );

        expect(result, [205, 203, 204]);
        expect(result, same(selected));
      },
    );

    test('Cards single-select returns only the resolved row ID', () {
      final result = browserEditorCardIds(
        resolvedRowCardId: 203,
        mode: BrowserColumnMode.cards,
        isInMultiSelectMode: false,
        noteCardIds: [203, 204],
        selectedCardIds: [201, 202],
      );

      expect(result, [203]);
    });
  });
}
