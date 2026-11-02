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
  group('filterReviewerTypeAnswerQuestion', () {
    test('uses the exact Reviewer prompt and trimIndent whitespace', () {
      expect(
        filterReviewerTypeAnswerQuestion(
          '[[type:Front]]',
          font: 'Open Sans',
          fontSize: 23,
        ),
        '<center>\n'
        '<input type="text" id="typeans" '
        'onkeydown="ankidroid.onTypeAnswerKeyDown(event);" \n'
        '   style="font-family: \'Open Sans\'; font-size: 23px;">\n'
        '</center>',
      );
    });

    test('replaces each nonempty marker and preserves nonmatching text', () {
      expect(
        filterReviewerTypeAnswerQuestion(
          'before [[type:Front]] / [[type:Back]] after '
          '[[TYPE:No]] [[type:broken\nmarker]]',
          font: 'Serif',
          fontSize: 18,
        ),
        'before <center>\n'
        '<input type="text" id="typeans" '
        'onkeydown="ankidroid.onTypeAnswerKeyDown(event);" \n'
        '   style="font-family: \'Serif\'; font-size: 18px;">\n'
        '</center> / <center>\n'
        '<input type="text" id="typeans" '
        'onkeydown="ankidroid.onTypeAnswerKeyDown(event);" \n'
        '   style="font-family: \'Serif\'; font-size: 18px;">\n'
        '</center> after [[TYPE:No]] [[type:broken\nmarker]]',
      );
    });

    test('leaves empty and every Java line-broken marker unmatched', () {
      for (final text in [
        '[[type:]]',
        for (final lineTerminator in ['\n', '\r', '\u0085', '\u2028', '\u2029'])
          '[[type:Front${lineTerminator}Back]]',
      ]) {
        expect(
          filterReviewerTypeAnswerQuestion(text, font: 'Serif', fontSize: 18),
          text,
        );
      }
    });

    test(
      'font interpolation retains Java Matcher group and escape behavior',
      () {
        expect(
          filterReviewerTypeAnswerQuestion(
            '[[type:Front]]',
            font: r'Open$10\Mono',
            fontSize: 12,
          ),
          contains("font-family: 'OpenFront0Mono'; font-size: 12px;"),
        );
      },
    );

    test('invalid font groups fail only when a marker is replaced', () {
      expect(
        () => filterReviewerTypeAnswerQuestion(
          '[[type:Front]]',
          font: r'Open$2',
          fontSize: 12,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        filterReviewerTypeAnswerQuestion(
          'no marker',
          font: r'Open$2',
          fontSize: 12,
        ),
        'no marker',
      );
    });
  });

  group('filterTypeAnswerQuestion', () {
    test(
      'uses the span prompt for every placeholder without trimming text',
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
        expect(
          filterTypeAnswerQuestion('', useInputTag: false, autoFocus: true),
          '',
        );
      },
    );

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
      },
    );

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
          for (final lineTerminator in [
            '\n',
            '\r',
            '\u0085',
            '\u2028',
            '\u2029',
          ])
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
      },
    );
  });

  group('filterTemplatePreviewerTypeAnswerQuestion', () {
    const input =
        "<center><input id='typeans' type=text value='example' readonly='readonly'></center>";

    test(
      'uses the read-only example on the first match, then warns on the rest',
      () {
        expect(
          filterTemplatePreviewerTypeAnswerQuestion(
            'before [[type:Front]] middle [[type:Back]] after',
            warningHtml: '<center><b>Missing type field</b></center>',
          ),
          'before $input middle <center><b>Missing type field</b></center> after',
        );
      },
    );

    test('expands warning replacement groups and backslash escapes', () {
      expect(
        filterTemplatePreviewerTypeAnswerQuestion(
          '[[type:Front]] + [[type:Back]]',
          warningHtml: r'<b>$1</b>\\',
        ),
        '$input + <b>Back</b>\\',
      );
    });

    test('does not validate replacement strings when there is no match', () {
      expect(
        filterTemplatePreviewerTypeAnswerQuestion(
          'no marker',
          warningHtml: r'$3',
        ),
        'no marker',
      );
    });

    test('rejects invalid warning groups only when a later marker matches', () {
      expect(
        filterTemplatePreviewerTypeAnswerQuestion(
          '[[type:Front]]',
          warningHtml: r'$2',
        ),
        input,
      );
      expect(
        () => filterTemplatePreviewerTypeAnswerQuestion(
          '[[type:Front]] [[type:Back]]',
          warningHtml: r'$2',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('keeps absent, malformed, and line-broken markers unchanged', () {
      for (final text in [
        '',
        '[[type:]]',
        '[[type:Front',
        '[[TYPE:Front]]',
        for (final lineTerminator in ['\n', '\r', '\u0085', '\u2028', '\u2029'])
          '[[type:Front${lineTerminator}Back]]',
      ]) {
        expect(
          filterTemplatePreviewerTypeAnswerQuestion(
            text,
            warningHtml: 'warning',
          ),
          text,
        );
      }
    });
  });
}
