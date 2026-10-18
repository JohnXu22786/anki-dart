/*
 * Copyright (c) 2026 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-FileCopyrightText: 2026 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: AnkiDroid DeckFiltersTest.kt at v2.25.3.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('DeckFilters', () {
    test('requires all terms and anchors path terms at the deck suffix', () {
      final filters = DeckFilters.create('u o::ba');

      expect(filters.accept('foo::bar::buz'), isTrue);
      expect(filters.accept('buz::foo::bar'), isTrue);
      expect(filters.accept('foo::buz::bar'), isFalse);
      expect(filters.accept('foo::bar::buz::plop'), isFalse);
      expect(DeckFilters.create('foo\u00a0bar').accept('foo::bar'), isFalse);
    });

    test('keeps single-colon and double-colon partial path searches distinct',
        () {
      final singleColon = DeckFilters.create('u:');
      final doubleColon = DeckFilters.create('u::');

      expect(singleColon.accept('foo::bar::bu'), isTrue);
      expect(singleColon.accept('foo::bar::buz'), isFalse);
      expect(doubleColon.accept('foo::bar::bu'), isFalse);
      expect(doubleColon.accept('foo::bar::bu::plop'), isTrue);
    });

    test(
        'matches dotted and dotless i across path positions and Turkish casing',
        () {
      expect(DeckFilter.containsAtPosition('ı', 1, 'i', 1), isTrue);
      expect(DeckFilter.containsAtPosition('I', 1, 'ı', 1), isTrue);
      expect(DeckFilter.containsAtPosition('i', 1, 'İ', 1), isTrue);
      expect(DeckFilters.create('i', localeName: 'tr_TR').accept('I'), isTrue);
      expect(DeckFilters.create('ı', localeName: 'tr_TR').accept('I'), isTrue);
    });
  });
}
