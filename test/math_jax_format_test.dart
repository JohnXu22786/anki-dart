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
 * Behavioral reference: MathJaxFormat.kt and Toolbar.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('MathJaxFormat pinned output strings', () {
    test('BLOCK wraps nonempty input exactly', () {
      expect(MathJaxFormat.BLOCK.toTextWrapper('x^2').text, r'\[x^2\]');
    });

    test('CHEMISTRY wraps nonempty input exactly', () {
      expect(
        MathJaxFormat.CHEMISTRY.toTextWrapper('H2O').text,
        r'\( \ce{H2O} \)',
      );
    });
  });

  group('MathJaxFormat source-derived selection behavior', () {
    test('empty BLOCK selection is at the prefix end', () {
      final result = MathJaxFormat.BLOCK.toTextWrapper('');

      expect(result.text, r'\[\]');
      expect(result.selectionStart, 2);
      expect(result.selectionEnd, 2);
    });

    test('empty CHEMISTRY selection is at the prefix end', () {
      final result = MathJaxFormat.CHEMISTRY.toTextWrapper('');

      expect(result.text, r'\( \ce{} \)');
      expect(result.selectionStart, 7);
      expect(result.selectionEnd, 7);
    });

    test('nonempty selections span all wrapped UTF-16 text', () {
      final block = MathJaxFormat.BLOCK.toTextWrapper('🙂');
      final chemistry = MathJaxFormat.CHEMISTRY.toTextWrapper('🙂');

      expect(block.selectionStart, 0);
      expect(block.selectionEnd, block.text.length);
      expect(block.selectionEnd, 6);
      expect(chemistry.selectionStart, 0);
      expect(chemistry.selectionEnd, chemistry.text.length);
      expect(chemistry.selectionEnd, 13);
    });
  });

  test(
    'StringFormat is mutable and follows Kotlin data-class value behavior',
    () {
      final first = StringFormat('value', 1, 6);
      final equal = StringFormat('value', 1, 6);

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(first.hashCode, 231602518);
      expect(
        first.toString(),
        'StringFormat(text=value, selectionStart=1, selectionEnd=6)',
      );

      first.text = 'changed';
      first.selectionStart = 2;
      first.selectionEnd = 4;

      expect(first.text, 'changed');
      expect(first.selectionStart, 2);
      expect(first.selectionEnd, 4);
      expect(first, isNot(equal));
    },
  );
}
