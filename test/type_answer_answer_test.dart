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
 * Source-derived checks for isolated `TypeAnswer.filterAnswer` placeholder
 * expansion. The pinned tests also exercise CollectionManager's comparator.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('filterTypeAnswerAnswer', () {
    test('replaces each placeholder and preserves surrounding content', () {
      const comparison =
          '<code id=typeans><span class=typeGood>hello</span></code>';
      expect(
        filterTypeAnswerAnswer(
          'before [[type:Back]] middle [[type:Front]] after',
          comparison,
        ),
        'before $comparison middle $comparison after',
      );
    });

    test('inserts dollar signs and backslashes literally', () {
      const comparison = r'<code>$! \saved\path</code>';
      expect(
        filterTypeAnswerAnswer('[[type:Back]]', comparison),
        comparison,
      );
    });

    test('empty comparison removes markers and empty answer stays empty', () {
      expect(
        filterTypeAnswerAnswer('before [[type:Back]] after', ''),
        'before  after',
      );
      expect(filterTypeAnswerAnswer('', '<code>anything</code>'), '');
    });

    test('leaves empty, malformed, case-mismatched, and line markers intact',
        () {
      for (final text in [
        '',
        'before [[type:]] after',
        'before [[type:Back after',
        '[[TYPE:Back]]',
        for (final lineTerminator in ['\n', '\r', '\u0085', '\u2028', '\u2029'])
          'before [[type:Back${lineTerminator}after]]',
      ]) {
        expect(filterTypeAnswerAnswer(text, '<code>value</code>'), text);
      }
    });

    test('lazy payload ends at the first close and keeps subsequent text', () {
      expect(
        filterTypeAnswerAnswer(
            'before [[type:Back]] after]] end', '<code>x</code>'),
        'before <code>x</code> after]] end',
      );
    });
  });
}
