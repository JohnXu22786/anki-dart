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
 * Direct and source-derived checks for TypeAnswer.contentForCloze.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('typeAnswerContentForCloze', () {
    test('matches direct upstream repeated-word cases', () {
      const same =
          'This is {{c1::test}} which is containing {{c1::test}} word twice';
      const mixed =
          'This is {{c1::test}} which is containing {{c1::test}} word twice {{c1::test2}}';
      expect(typeAnswerContentForCloze(same, 1), 'test');
      expect(typeAnswerContentForCloze(mixed, 1), 'test, test, test2');
    });

    test('removes hint after the first delimiter without trimming content', () {
      expect(
        typeAnswerContentForCloze(
          'before {{c1::<b> A </b>::hint::tail}} after',
          1,
        ),
        '<b> A </b>',
      );
      expect(typeAnswerContentForCloze('{{c1::::hint}}', 1), '');
    });

    test('keeps capture order and duplicates when captures differ', () {
      expect(
        typeAnswerContentForCloze(
          '{{c1::a}} / {{c1::a}} / {{c1::b}} / {{c1::a}}',
          1,
        ),
        'a, a, b, a',
      );
    });

    test('matches only the requested index and no matches join to empty', () {
      const text = '{{c1::first}} then {{c2::second}}';
      expect(typeAnswerContentForCloze(text, 1), 'first');
      expect(typeAnswerContentForCloze(text, 2), 'second');
      expect(typeAnswerContentForCloze(text, 3), '');
      expect(typeAnswerContentForCloze('', 1), '');
    });

    test('ignores empty, malformed, wrong-case and multiline markers', () {
      for (final text in [
        '{{c1::}}',
        '{{c1::unfinished',
        '{{C1::upper}}',
        for (final lineTerminator in ['\n', '\r', '\u0085', '\u2028', '\u2029'])
          '{{c1::before${lineTerminator}after}}',
      ]) {
        expect(typeAnswerContentForCloze(text, 1), '');
      }
    });

    test('regex captures lazily through the first closing delimiter', () {
      expect(
        typeAnswerContentForCloze('{{c1::one}} left }} {{c1::two}}', 1),
        'one, two',
      );
    });
  });
}
