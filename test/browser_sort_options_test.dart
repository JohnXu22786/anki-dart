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
  test(
    'options group active and hidden sortable columns before unavailable',
    () {
      final options = buildBrowserSortOptions(
        mode: BrowserColumnMode.cards,
        activeColumns: const [BrowserColumn.deck, BrowserColumn.sortField],
        labels: const {BrowserColumn.deck: 'Projected deck'},
        selectedSort: const BrowserSortCollectionOrdering(
          key: 'deck',
          reverse: false,
        ),
      );

      expect(options.take(2).map((option) => option.column), [
        BrowserColumn.deck,
        BrowserColumn.sortField,
      ]);
      expect(
        options
            .take(2)
            .every(
              (option) => option.section == BrowserSortOptionSection.active,
            ),
        isTrue,
      );
      expect(options.first.label, 'Projected deck');
      expect(options.first.selected, isTrue);
      expect(
        options.first.selectedExplanation,
        BrowserSortExplanation.textAscending,
      );
      expect(options.last.section, BrowserSortOptionSection.unavailable);
      expect(options.last.column, BrowserColumn.answer);
    },
  );

  test('notes mode keeps FSRS columns unavailable and card type numeric', () {
    final options = buildBrowserSortOptions(
      mode: BrowserColumnMode.notes,
      activeColumns: const [BrowserColumn.cardType],
      labels: const {},
      selectedSort: const BrowserSortNoOrdering(),
    );
    final cardType = options.firstWhere(
      (option) => option.column == BrowserColumn.cardType,
    );
    final fsrs = options.firstWhere(
      (option) => option.column == BrowserColumn.fsrsDifficulty,
    );

    expect(cardType.section, BrowserSortOptionSection.active);
    expect(cardType.mode, BrowserColumnMode.notes);
    expect(fsrs.section, BrowserSortOptionSection.unavailable);
    expect(
      fsrs.unavailableReason,
      BrowserColumnSortUnavailableReason.cardsModeOnly,
    );
    expect(
      browserSortKeyAvailable('difficulty', BrowserColumnMode.cards),
      isTrue,
    );
    expect(
      browserSortKeyAvailable('difficulty', BrowserColumnMode.notes),
      isFalse,
    );
    expect(
      browserSortKeyAvailable('unknown', BrowserColumnMode.cards),
      isFalse,
    );
  });
}
