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
 * Source-derived from CardBrowserViewModel.kt:883–890 and its sound-tags
 * regression test in AnkiDroid 2.25.3; that test checks row content, not the
 * selected value or lookup order.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('transformBrowserRow', () {
    test('looks up the row before selection and preserves opaque values', () {
      final id = Object();
      final row = Object();
      final calls = <String>[];

      final result = transformBrowserRow(
        id: id,
        browserRowForId: (lookupId) {
          calls.add('row');
          expect(identical(lookupId, id), isTrue);
          return row;
        },
        containsSelectedRow: (selectedId) {
          calls.add('selected');
          expect(identical(selectedId, id), isTrue);
          return true;
        },
      );

      expect(calls, ['row', 'selected']);
      expect(identical(result.row, row), isTrue);
      expect(result.isSelected, isTrue);
    });

    test('returns selected membership as true or false unchanged', () {
      for (final isSelected in [true, false]) {
        final result = transformBrowserRow(
          id: 12,
          browserRowForId: (_) => 'host row',
          containsSelectedRow: (_) => isSelected,
        );

        expect(result, (row: 'host row', isSelected: isSelected));
      }
    });

    test('propagates row lookup failure before checking selected rows', () {
      final error = StateError('backend lookup failed');
      var selectedLookups = 0;

      expect(
        () => transformBrowserRow(
          id: 12,
          browserRowForId: (_) => throw error,
          containsSelectedRow: (_) {
            selectedLookups++;
            return false;
          },
        ),
        throwsA(same(error)),
      );
      expect(selectedLookups, 0);
    });

    test('propagates selected membership failure after row lookup', () {
      final error = StateError('selection lookup failed');
      final calls = <String>[];

      expect(
        () => transformBrowserRow(
          id: 12,
          browserRowForId: (_) {
            calls.add('row');
            return 'host row';
          },
          containsSelectedRow: (_) {
            calls.add('selected');
            throw error;
          },
        ),
        throwsA(same(error)),
      );
      expect(calls, ['row', 'selected']);
    });
  });
}
