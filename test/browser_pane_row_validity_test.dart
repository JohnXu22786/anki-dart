/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This file is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardBrowserViewModel.kt; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser pane row validity', () {
    test('phone mode clears a supplied pane row', () {
      final paneRow = _Row(1);

      expect(
        ensureBrowserPaneRowValid(
          isFragmented: false,
          rows: [_Row(1)],
          paneRow: paneRow,
        ),
        isNull,
      );
    });

    test('fragmented mode clears pane row when there are no current rows', () {
      expect(
        ensureBrowserPaneRowValid(
          isFragmented: true,
          rows: const [],
          paneRow: _Row(1),
        ),
        isNull,
      );
    });

    test(
      'retains the supplied pane value when an equal current row exists',
      () {
        final paneRow = _Row(2);

        final result = ensureBrowserPaneRowValid(
          isFragmented: true,
          rows: [_Row(1), _Row(2)],
          paneRow: paneRow,
        );

        expect(result, same(paneRow));
      },
    );

    test('falls back to the first row for a null or stale pane value', () {
      final firstRow = _Row(1);
      final rows = [firstRow, _Row(2)];

      expect(
        ensureBrowserPaneRowValid(
          isFragmented: true,
          rows: rows,
          paneRow: null,
        ),
        same(firstRow),
      );
      expect(
        ensureBrowserPaneRowValid(
          isFragmented: true,
          rows: rows,
          paneRow: _Row(3),
        ),
        same(firstRow),
      );
    });
  });
}

final class _Row {
  const _Row(this.id);

  final int id;

  @override
  bool operator ==(Object other) => other is _Row && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
