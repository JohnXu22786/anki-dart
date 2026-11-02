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
 *
 * Source-derived from FilenameTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Filename.sanitize', () {
    test('leaves a valid name unchanged', () {
      expect(Filename.sanitize('Japanese Vocab').value, 'Japanese Vocab');
    });

    test('replaces each invalid character', () {
      expect(
        Filename.sanitize(r'a\b/c?d<e>f:g*h|i"j^k').value,
        'a_b_c_d_e_f_g_h_i_j_k',
      );
    });

    test('replaces a colon in a deck name', () {
      expect(Filename.sanitize('Ratio 1:2').value, 'Ratio 1_2');
    });

    test('replaces each subdeck separator character', () {
      expect(Filename.sanitize('Japanese::Kanji').value, 'Japanese__Kanji');
    });

    test('retains value equality, hash, and string projection', () {
      final first = Filename.sanitize('Japanese Vocab');
      final equal = Filename.sanitize('Japanese Vocab');
      final different = Filename.sanitize('Japanese Vocabulary');

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(first.hashCode, -1388859076);
      expect(Filename.sanitize('😊').hashCode, 1772909);
      expect(first, isNot(different));
      expect(first.toString(), 'Japanese Vocab');
    });
  });
}
