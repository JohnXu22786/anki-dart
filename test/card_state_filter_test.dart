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
 * Behavioral reference: CardStateFilter.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CardStateFilter', () {
    test('keeps each source search fragment exactly', () {
      const expected = <CardStateFilter, String>{
        CardStateFilter.ALL_CARDS: '',
        CardStateFilter.NEW: 'is:new ',
        CardStateFilter.DUE: 'is:due ',
      };

      for (final filter in CardStateFilter.values) {
        expect(filter.toSearch, expected[filter], reason: filter.name);
      }
      expect(CardStateFilter.NEW.toSearch.endsWith(' '), isTrue);
      expect(CardStateFilter.DUE.toSearch.endsWith(' '), isTrue);
    });

    test('preserves source declaration order, names, and enum identity', () {
      expect(CardStateFilter.values.map((filter) => filter.name), [
        'ALL_CARDS',
        'NEW',
        'DUE',
      ]);

      for (final filter in CardStateFilter.values) {
        expect(identical(filter, CardStateFilter.values[filter.index]), isTrue);
        expect(filter, CardStateFilter.values[filter.index]);
      }
    });
  });
}
