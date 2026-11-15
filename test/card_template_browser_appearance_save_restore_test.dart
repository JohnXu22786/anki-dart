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
 * Source-derived from CardTemplateBrowserAppearanceEditor.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('browser appearance restore defaults and close', () {
    test('sets question then answer to default before saving', () {
      final calls = <String>[];

      restoreBrowserAppearanceDefaultAndClose(
        setQuestionFormat: (value) => calls.add('question:$value'),
        setAnswerFormat: (value) => calls.add('answer:$value'),
        saveAndExit: () => calls.add('save'),
      );

      expect(calls, ['question:', 'answer:', 'save']);
    });

    test('question setter failure stops answer setter and save', () {
      final exception = StateError('question setter failed');
      final calls = <String>[];

      expect(
        () => restoreBrowserAppearanceDefaultAndClose(
          setQuestionFormat: (_) {
            calls.add('question');
            throw exception;
          },
          setAnswerFormat: (_) => calls.add('answer'),
          saveAndExit: () => calls.add('save'),
        ),
        throwsA(same(exception)),
      );
      expect(calls, ['question']);
    });

    test('answer setter failure stops save', () {
      final exception = StateError('answer setter failed');
      final calls = <String>[];

      expect(
        () => restoreBrowserAppearanceDefaultAndClose(
          setQuestionFormat: (_) => calls.add('question'),
          setAnswerFormat: (_) {
            calls.add('answer');
            throw exception;
          },
          saveAndExit: () => calls.add('save'),
        ),
        throwsA(same(exception)),
      );
      expect(calls, ['question', 'answer']);
    });
  });

  group('browser appearance save and exit', () {
    test('reads question then answer, sends result, then finishes', () {
      final calls = <String>[];
      BrowserAppearanceResult? sentResult;

      saveBrowserAppearanceAndExit(
        readQuestionFormat: () {
          calls.add('read-question');
          return 'question format';
        },
        readAnswerFormat: () {
          calls.add('read-answer');
          return 'answer format';
        },
        setResult: (result) {
          calls.add('result');
          sentResult = result;
        },
        finish: () => calls.add('finish'),
      );

      expect(calls, ['read-question', 'read-answer', 'result', 'finish']);
      expect(sentResult!.question, 'question format');
      expect(sentResult!.answer, 'answer format');
    });

    test('question read failure stops answer read, result, and finish', () {
      final exception = StateError('question read failed');
      final calls = <String>[];

      expect(
        () => saveBrowserAppearanceAndExit(
          readQuestionFormat: () {
            calls.add('read-question');
            throw exception;
          },
          readAnswerFormat: () {
            calls.add('read-answer');
            return 'answer';
          },
          setResult: (_) => calls.add('result'),
          finish: () => calls.add('finish'),
        ),
        throwsA(same(exception)),
      );
      expect(calls, ['read-question']);
    });

    test('answer read failure stops result and finish', () {
      final exception = StateError('answer read failed');
      final calls = <String>[];

      expect(
        () => saveBrowserAppearanceAndExit(
          readQuestionFormat: () {
            calls.add('read-question');
            return 'question';
          },
          readAnswerFormat: () {
            calls.add('read-answer');
            throw exception;
          },
          setResult: (_) => calls.add('result'),
          finish: () => calls.add('finish'),
        ),
        throwsA(same(exception)),
      );
      expect(calls, ['read-question', 'read-answer']);
    });

    test('result callback failure stops finish', () {
      final exception = StateError('result callback failed');
      var finished = false;

      expect(
        () => saveBrowserAppearanceAndExit(
          readQuestionFormat: () => 'question',
          readAnswerFormat: () => 'answer',
          setResult: (_) => throw exception,
          finish: () => finished = true,
        ),
        throwsA(same(exception)),
      );
      expect(finished, isFalse);
    });
  });
}
