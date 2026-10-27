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
 * Source-derived checks for `TypeAnswer.filterQuestion`; the pinned Android
 * test suite has no direct assertions for this method.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('filterTypeAnswerQuestion', () {
    test('uses the span prompt for every placeholder without trimming text',
        () {
      const prompt = '<span id="typeans" class="typePrompt">........</span>';
      expect(
        filterTypeAnswerQuestion(
          '  \n[[type:Front]]\t[[type:Back]]\n  ',
          useInputTag: false,
          autoFocus: true,
        ),
        '  \n$prompt\t$prompt\n  ',
      );
      expect(filterTypeAnswerQuestion('', useInputTag: false, autoFocus: true),
          '');
    });

    test(
        'builds the exact input prompt and includes style only for valid font size',
        () {
      expect(
        filterTypeAnswerQuestion(
          '[[type:Front]]',
          useInputTag: true,
          autoFocus: true,
          font: 'Open Sans',
          size: 20,
        ),
        '<center>\n'
        '<input type="text" name="typed" id="typeans" data-focus="true" '
        'onfocus="taFocus();" oninput=\'taChange(this);\' '
        'onKeyPress="return taKey(this, event)" autocomplete="off" '
        'style="font-family: \'Open Sans\'; font-size: 20px;" >\n'
        '</center>\n',
      );

      final withoutStyle = filterTypeAnswerQuestion(
        '[[type:Front]]',
        useInputTag: true,
        autoFocus: false,
        font: 'Open Sans',
        size: 0,
      );
      expect(withoutStyle, contains('data-focus="false"'));
      expect(withoutStyle, contains('autocomplete="off" >'));
      expect(withoutStyle, isNot(contains('style="font-family')));
    });

    test('a non-null warning replaces only the first placeholder', () {
      expect(
        filterTypeAnswerQuestion(
          'before [[type:Front]] middle [[type:Back]] after',
          useInputTag: true,
          autoFocus: true,
          warning: 'Missing field',
        ),
        'before Missing field middle [[type:Back]] after',
      );
      expect(
        filterTypeAnswerQuestion(
          'a[[type:Front]]b',
          useInputTag: false,
          autoFocus: false,
          warning: '',
        ),
        'ab',
      );
    });

    test('uses Java Matcher dollar groups and backslash escapes', () {
      expect(
        filterTypeAnswerQuestion(
          '[[type:Front]]',
          useInputTag: false,
          autoFocus: false,
          warning: r'bad:$1|\$',
        ),
        r'bad:Front|$',
      );
      expect(
        filterTypeAnswerQuestion(
          '[[type:Front]]',
          useInputTag: false,
          autoFocus: false,
          warning: r'$0|$10|$01',
        ),
        '[[type:Front]]|Front0|Front',
      );
      expect(
        filterTypeAnswerQuestion(
          '[[type:Front]]',
          useInputTag: true,
          autoFocus: false,
          font: r'Open$1',
          size: 12,
        ),
        contains("font-family: 'OpenFront'; font-size: 12px;"),
      );
      expect(
        () => filterTypeAnswerQuestion(
          '[[type:Front]]',
          useInputTag: false,
          autoFocus: false,
          warning: r'$2',
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        filterTypeAnswerQuestion(
          'no placeholder',
          useInputTag: false,
          autoFocus: false,
          warning: r'$2',
        ),
        'no placeholder',
      );
    });

    test(
        'leaves empty, malformed, case-mismatched, and multiline markers intact',
        () {
      for (final text in [
        '',
        'before [[type:]] after',
        'before [[type:Front after',
        '[[TYPE:Front]]',
        for (final lineTerminator in ['\n', '\r', '\u0085', '\u2028', '\u2029'])
          'before [[type:Front${lineTerminator}after]]',
      ]) {
        expect(
          filterTypeAnswerQuestion(
            text,
            useInputTag: false,
            autoFocus: false,
          ),
          text,
        );
      }
      expect(
        filterTypeAnswerQuestion(
          '[[type: ]]',
          useInputTag: false,
          autoFocus: false,
        ),
        '<span id="typeans" class="typePrompt">........</span>',
      );
    });
  });
}
