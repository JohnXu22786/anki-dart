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
 * Source-derived cases for InstantEditorViewModel cloze helpers;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Instant Editor cloze state', () {
    test('clean cloze words follow source replacement for every match', () {
      const cases = <(String, String)>[
        ('{{c1::word}}', 'word'),
        ('{{c2::another}}', 'another'),
        ('{{c4::help}}!!', 'help!!'),
        ('no cloze', 'no cloze'),
        ('[{{c6::word}}]', '[word]'),
        ('{{c1::first}} {{c2::second}}', 'first second'),
      ];
      final state = InstantEditorClozeState();

      for (final (input, expected) in cases) {
        expect(state.getCleanClozeWords(input), expected);
      }
    });

    test('word cloze number uses the first match anywhere in the word', () {
      final state = InstantEditorClozeState();

      expect(state.getWordClozeNumber('prefix{{c2::two}}suffix'), 2);
      expect(state.getWordClozeNumber('{{c4::first}}/{{c5::second}}'), 4);
      expect(state.getWordClozeNumber('no cloze'), isNull);
    });

    test(
      'word cloze number follows source digit capture and Int32 parsing',
      () {
        final state = InstantEditorClozeState();

        expect(state.getWordClozeNumber('{{c0::zero}}'), 0);
        expect(state.getWordClozeNumber('{{c2147483647::max}}'), 2147483647);
        expect(state.getWordClozeNumber('{{c2147483648::overflow}}'), isNull);
        expect(
          state.getWordClozeNumber('{{c2147483648::overflow}} {{c1::later}}'),
          isNull,
        );
        expect(state.getWordClozeNumber('{{c+2::plus}}'), isNull);
        expect(state.getWordClozeNumber('{{c-2::minus}}'), isNull);
      },
    );

    test('testExtractWordsIncludingClozes', () {
      final state = InstantEditorClozeState();
      state.setClozeFieldText(
        'This is a {{c1::test}} sentence with {{c2::multiple}} clozes.',
      );

      expect(state.getWordsFromFieldText(), [
        'This',
        'is',
        'a',
        '{{c1::test}}',
        'sentence',
        'with',
        '{{c2::multiple}}',
        'clozes.',
      ]);
    });

    test('testExtractWordsIncludingPunctuations', () {
      final state = InstantEditorClozeState();
      state.setClozeFieldText(
        'This is a {{c1::test}}!! sentence with {{c2::multiple}} clozes?',
      );

      expect(state.getWordsFromFieldText(), [
        'This',
        'is',
        'a',
        '{{c1::test}}!!',
        'sentence',
        'with',
        '{{c2::multiple}}',
        'clozes?',
      ]);
    });

    test(
      'word extraction preserves empty input and punctuation transitions',
      () {
        final state = InstantEditorClozeState();

        state.setClozeFieldText(null);
        expect(state.getWordsFromFieldText(), isEmpty);
        state.setClozeFieldText('');
        expect(state.getWordsFromFieldText(), isEmpty);

        state.setClozeFieldText('{{c1::one}}{{c2::two}}');
        // The source's greedy optional trailing punctuation consumes the next
        // cloze opener when two matches touch.
        expect(state.getWordsFromFieldText(), ['{{c1::one}}{{', 'c2::two}}']);

        state.setClozeFieldText('{{c1::one}} ! ? word !!!');
        expect(state.getWordsFromFieldText(), ['{{c1::one}}!?', 'word', '!!!']);
      },
    );

    test('word extraction keeps JVM whitespace split and trim semantics', () {
      final state = InstantEditorClozeState();

      state.setClozeFieldText(' \u2003alpha\u2003beta\u2003 ');
      expect(state.getWordsFromFieldText(), ['alpha\u2003beta']);

      state.setClozeFieldText('alpha\u00a0');
      expect(state.getWordsFromFieldText(), ['alpha\u00a0']);
    });

    test(
      'field text replaces ordinals in source order and keeps duplicates',
      () {
        final state = InstantEditorClozeState();

        state.setClozeFieldText('{{c2::two}} {{c1::one}} {{c2::again}}');

        expect(
          state.actualClozeFieldText,
          '{{c2::two}} {{c1::one}} {{c2::again}}',
        );
        expect(state.clozeOrdinals, [2, 1, 2]);
        expect(state.clozeDeletionCount, 3);
        expect(state.currentClozeNumber, 3);
      },
    );

    test('nullable and out-of-range field ordinals follow Kotlin parsing', () {
      final state = InstantEditorClozeState();
      state.setClozeFieldText('{{c2147483648::large}} {{c3::three}}');
      expect(state.clozeOrdinals, [3]);
      expect(state.currentClozeNumber, 4);

      state.setClozeFieldText(null);
      expect(state.actualClozeFieldText, isNull);
      expect(state.clozeOrdinals, isEmpty);
      expect(state.currentClozeNumber, 1);

      state.setClozeFieldText('{{c2147483647::max}}');
      expect(state.currentClozeNumber, -2147483648);
    });

    test(
      'no-increment field updates choose max ordinal and mode toggles adjust',
      () {
        final state = InstantEditorClozeState();
        state.setClozeFieldText('{{c1::one}} {{c3::three}}');
        expect(state.currentClozeNumber, 4);

        state.toggleClozeMode();
        expect(state.currentClozeMode, ClozeNumberMode.noIncrement);
        expect(state.currentClozeNumber, 3);
        state.setClozeFieldText('{{c2::two}} {{c2::again}}');
        expect(state.currentClozeNumber, 2);
        state.toggleClozeMode();
        expect(state.currentClozeMode, ClozeNumberMode.increment);
        expect(state.currentClozeNumber, 3);
      },
    );

    test('empty mode toggles do not adjust the counter', () {
      final state = InstantEditorClozeState();

      state.toggleClozeMode();
      expect(state.currentClozeNumber, 1);
      state.toggleClozeMode();
      expect(state.currentClozeNumber, 1);
    });

    test('build wraps source word and preserves start and end punctuation', () {
      final state = InstantEditorClozeState();

      expect(state.buildClozeText('!?hello-world!'), '!?{{c1::hello-world}}!');
      expect(state.currentClozeNumber, 2);
      expect(state.clozeOrdinals, [1]);
    });

    test('build preserves source null interpolation for unmatched input', () {
      final state = InstantEditorClozeState();

      expect(state.buildClozeText('!!!'), 'null{{c1::null}}null');
      expect(state.currentClozeNumber, 2);
      expect(state.clozeOrdinals, [1]);
    });

    test('removal updates counter and duplicate list in source order', () {
      final state = InstantEditorClozeState();
      state.setClozeFieldText('{{c1::first}} {{c2::second}} {{c3::third}}');

      expect(state.buildClozeText('{{c2::second}}'), 'second');
      expect(state.clozeOrdinals, [1, 3]);
      expect(state.currentClozeNumber, 4);
      expect(state.buildClozeText('{{c3::third}}'), 'third');
      expect(state.currentClozeNumber, 2);
    });

    test(
      'no-increment builds reuse counter and reset only after last removal',
      () {
        final state = InstantEditorClozeState();
        state.toggleClozeMode();

        expect(state.buildClozeText('first'), '{{c1::first}}');
        expect(state.buildClozeText('second'), '{{c1::second}}');
        expect(state.currentClozeNumber, 1);
        expect(state.clozeOrdinals, [1, 1]);
        state.buildClozeText('{{c1::first}}');
        expect(state.clozeOrdinals, [1]);
        expect(state.currentClozeNumber, 1);
        state.buildClozeText('{{c1::second}}');
        expect(state.clozeOrdinals, isEmpty);
        expect(state.currentClozeNumber, 1);
      },
    );

    test('cloze conversion throws on source Int.toInt overflow', () {
      final state = InstantEditorClozeState();
      expect(
        () => state.buildClozeText('{{c2147483648::too large}}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
