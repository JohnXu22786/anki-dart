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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeForSearch', () {
    test('matches the pinned AnkiDroid examples', () {
      const cases = <(String, String)>[
        ('café Ábaco naïve résumé', 'cafe Abaco naive resume'),
        ('élégant déjà vu', 'elegant deja vu'),
        ('hello world', 'hello world'),
        ('', ''),
        ('1234!@# café', '1234!@# cafe'),
      ];

      for (final (input, expected) in cases) {
        expect(normalizeForSearch(input), expected, reason: input);
      }
    });

    test(
      'decomposes first, then removes every mark in the specified block',
      () {
        expect(normalizeForSearch('Ångström'), 'Angstrom');
        expect(normalizeForSearch('s\u0323\u0307'), 's');
      },
    );

    test('preserves marks outside U+0300..U+036F', () {
      expect(normalizeForSearch('x\u036f'), 'x');
      expect(normalizeForSearch('x\u0370'), 'x\u0370');
      expect(normalizeForSearch('x\u1ab0'), 'x\u1ab0');
      expect(normalizeForSearch('ש\u05b0'), 'ש\u05b0');
      // U+0622 decomposes to U+0627 and a combining mark outside the block.
      expect(normalizeForSearch('\u0622'), '\u0627\u0653');
    });

    test(
      'preserves supplementary characters and isolated UTF-16 surrogates',
      () {
        const input = '😀\ud800 café';
        final actual = normalizeForSearch(input);

        expect(actual, '😀\ud800 cafe');
        expect(actual.codeUnits, [
          0xd83d,
          0xde00,
          0xd800,
          0x20,
          0x63,
          0x61,
          0x66,
          0x65,
        ]);
      },
    );
  });
}
