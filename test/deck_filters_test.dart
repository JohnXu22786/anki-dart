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

    test('uses invariant query casing with Turkish deck-name casing', () {
      expect(DeckFilter.containsAtPosition('ı', 1, 'i', 1), isTrue);
      expect(DeckFilter.containsAtPosition('I', 1, 'ı', 1), isTrue);
      expect(DeckFilter.containsAtPosition('i', 1, 'İ', 1), isTrue);
      expect(DeckFilters.create('I', localeName: 'tr_TR').accept('ı'), isFalse);
      expect(DeckFilters.create('I', localeName: 'tr_TR').accept('i'), isTrue);
      expect(DeckFilters.create('i', localeName: 'tr_TR').accept('I'), isTrue);
      expect(DeckFilters.create('ı', localeName: 'tr_TR').accept('I'), isTrue);
    });

    test('reads the default locale when matching a reused filter', () {
      var currentLocale = 'en_US';
      final filters = DeckFilters.create(
        'ı',
        localeNameProvider: () => currentLocale,
      );

      expect(filters.accept('I'), isFalse);
      currentLocale = 'tr_TR';
      expect(filters.accept('I'), isTrue);
    });

    test('adds Lithuanian dot above before an acute accent', () {
      expect(
        DeckFilters.create('i\u0307\u0301', localeName: 'lt_LT')
            .accept('I\u0301'),
        isTrue,
      );
    });

    test('adds Lithuanian dot above across lower-class combining marks', () {
      expect(
        DeckFilters.create('i\u0307\u0327\u0301', localeName: 'lt_LT')
            .accept('I\u0327\u0301'),
        isTrue,
      );
    });

    test('stops Lithuanian More Above at a class-zero mark', () {
      expect(
        DeckFilter('i\u0307\u0903\u0301')
            .deckNameMatchesFilter('I\u0903\u0301', 'lt_LT'),
        isFalse,
      );
    });

    test('removes the Turkish dot after I across lower-class marks', () {
      expect(
        DeckFilters.create('i\u0327', localeName: 'tr_TR')
            .accept('I\u0327\u0307'),
        isTrue,
      );
    });

    test('removes the Lithuanian dot after a soft-dotted letter', () {
      expect(
        DeckFilters.create('i\u0327', localeName: 'lt_LT')
            .accept('i\u0327\u0307'),
        isTrue,
      );
    });

    test('matches a precomposed Lithuanian I accent without a second dot', () {
      expect(
        DeckFilter('i\u0307\u0300').deckNameMatchesFilter('Ì', 'lt_LT'),
        isTrue,
      );
    });

    test('uses contextual final sigma when lowercasing deck names', () {
      expect(
        DeckFilters.create('ος', localeName: 'en_US').accept('ΟΣ'),
        isTrue,
      );
      expect(
        DeckFilters.create('ος\u0301', localeName: 'en_US').accept('ΟΣ\u0301'),
        isTrue,
      );
      expect(
        DeckFilters.create('ος\u02B0', localeName: 'en_US').accept('ΟΣ\u02B0'),
        isTrue,
      );
      expect(
        DeckFilters.create('ος', localeName: 'tr_TR').accept('ΟΣ'),
        isTrue,
      );
      expect(
        DeckFilters.create("οσ'α", localeName: 'en_US').accept("ΟΣ'Α"),
        isTrue,
      );
    });

    test('uses full lowercase mappings that expand to multiple characters', () {
      expect(
        DeckFilters.create('i\u0307', localeName: 'en_US').accept('İ'),
        isTrue,
      );
    });

    test('trims Kotlin whitespace without trimming next-line characters', () {
      expect(
        DeckFilters.create('\u001Cfoo\u001C', localeName: 'en_US')
            .accept('foo'),
        isTrue,
      );
      expect(
        DeckFilters.create('foo\u0085', localeName: 'en_US').accept('foo'),
        isFalse,
      );
      expect(
        DeckFilters.create('foo\u0085', localeName: 'en_US')
            .accept('foo\u0085'),
        isTrue,
      );
    });
  });
}
