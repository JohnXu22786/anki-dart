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
 * Source-derived from AnkiDroid 2.25.3 BrowserColumnSelectionAdapter.kt;
 * upstream tests cover layout and drag callbacks, not these getter projections.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Browser column-selection row projection', () {
    test('splits columns around the first Available heading in row order', () {
      final projection = projectBrowserColumnSelectionRows(
        items: [
          const BrowserColumnSelectionUsageItem(
            BrowserColumnSelectionUsage.active,
          ),
          const BrowserColumnSelectionColumnItem(BrowserColumn.question),
          const BrowserColumnSelectionColumnItem(BrowserColumn.answer),
          const BrowserColumnSelectionUsageItem(
            BrowserColumnSelectionUsage.available,
          ),
          const BrowserColumnSelectionColumnItem(BrowserColumn.deck),
          const BrowserColumnSelectionColumnItem(BrowserColumn.tags),
        ],
      );

      expect(projection.availableHeadingPosition, 3);
      expect(projection.displayed, [
        BrowserColumn.question,
        BrowserColumn.answer,
      ]);
      expect(projection.available, [BrowserColumn.deck, BrowserColumn.tags]);
      expect(projection.selected, [
        BrowserColumn.question,
        BrowserColumn.answer,
      ]);
    });

    test(
      'uses strict comparisons and the first duplicate Available heading',
      () {
        final projection = projectBrowserColumnSelectionRows(
          items: [
            const BrowserColumnSelectionUsageItem(
              BrowserColumnSelectionUsage.available,
            ),
            const BrowserColumnSelectionColumnItem(BrowserColumn.question),
            const BrowserColumnSelectionUsageItem(
              BrowserColumnSelectionUsage.available,
            ),
            const BrowserColumnSelectionColumnItem(BrowserColumn.deck),
          ],
        );

        expect(projection.availableHeadingPosition, 0);
        expect(projection.displayed, isEmpty);
        expect(projection.available, [
          BrowserColumn.question,
          BrowserColumn.deck,
        ]);
      },
    );

    test(
      'missing Available heading returns -1 and projects all columns as available',
      () {
        final projection = projectBrowserColumnSelectionRows(
          items: [
            const BrowserColumnSelectionUsageItem(
              BrowserColumnSelectionUsage.active,
            ),
            const BrowserColumnSelectionColumnItem(BrowserColumn.question),
            const BrowserColumnSelectionColumnItem(BrowserColumn.deck),
          ],
        );

        expect(projection.availableHeadingPosition, -1);
        expect(projection.displayed, isEmpty);
        expect(projection.available, [
          BrowserColumn.question,
          BrowserColumn.deck,
        ]);
        expect(projection.selected, isEmpty);
      },
    );
  });
}
