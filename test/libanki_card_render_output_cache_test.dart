/*
 * Copyright (c) 2009 Daniel Svärd <daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd <daniel.svard@gmail.com>
 * SPDX-FileCopyrightText: 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * SPDX-FileCopyrightText: 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnkiCardRenderOutputCache', () {
    test('returns the cached output unchanged without rendering', () {
      final output = _Output();
      var renderCalls = 0;
      final cache = LibAnkiCardRenderOutputCache<_Output, String>(
        renderOutput: output,
      );

      final result = cache.renderOutput(
        render: (_) {
          renderCalls++;
          return _Output();
        },
      );

      expect(identical(result, output), isTrue);
      expect(identical(cache.cachedOutput, output), isTrue);
      expect(renderCalls, 0);
    });

    test('renders once when empty and caches the exact result', () {
      final output = _Output();
      final browsers = <bool>[];
      final cache = LibAnkiCardRenderOutputCache<_Output, String>();

      final result = cache.renderOutput(
        browser: true,
        render: (browser) {
          browsers.add(browser);
          return output;
        },
      );

      expect(identical(result, output), isTrue);
      expect(identical(cache.cachedOutput, output), isTrue);
      expect(browsers, [true]);
    });

    test(
      'reload passes browser and commits the new output only on success',
      () {
        final oldOutput = _Output();
        final newOutput = _Output();
        final calls = <bool>[];
        final cache = LibAnkiCardRenderOutputCache<_Output, String>(
          renderOutput: oldOutput,
        );

        final result = cache.renderOutput(
          reload: true,
          browser: true,
          render: (browser) {
            calls.add(browser);
            return newOutput;
          },
        );

        expect(calls, [true]);
        expect(identical(result, newOutput), isTrue);
        expect(identical(cache.cachedOutput, newOutput), isTrue);
      },
    );

    test(
      'failed render preserves the prior cache and propagates the same error',
      () {
        final oldOutput = _Output();
        final failure = StateError('renderer failed');
        var calls = 0;
        final cache = LibAnkiCardRenderOutputCache<_Output, String>(
          renderOutput: oldOutput,
        );

        expect(
          () => cache.renderOutput(
            reload: true,
            render: (_) {
              calls++;
              throw failure;
            },
          ),
          throwsA(same(failure)),
        );
        expect(calls, 1);
        expect(identical(cache.cachedOutput, oldOutput), isTrue);
      },
    );

    test('question forwards flags then returns the exact derived string', () {
      final output = _Output();
      final result = StringBuffer('question');
      final oldOutput = _Output();
      final calls = <String>[];
      var browser = false;
      final cache = LibAnkiCardRenderOutputCache<_Output, String>(
        renderOutput: oldOutput,
      );

      final question = cache.question(
        reload: true,
        browser: true,
        render: (isBrowser) {
          calls.add('render');
          browser = isBrowser;
          return output;
        },
        questionAndStyle: (rendered) {
          calls.add('question');
          expect(identical(rendered, output), isTrue);
          return result.toString();
        },
      );

      expect(calls, ['render', 'question']);
      expect(browser, isTrue);
      expect(identical(question, result.toString()), isTrue);
    });

    test(
      'answer uses default rendering flags and returns the exact string',
      () {
        final output = _Output();
        final result = StringBuffer('answer');
        final calls = <String>[];
        final cache = LibAnkiCardRenderOutputCache<_Output, String>(
          renderOutput: output,
        );

        final answer = cache.answer(
          render: (_) => fail('cached answer should not reload'),
          answerAndStyle: (rendered) {
            calls.add('answer');
            expect(identical(rendered, output), isTrue);
            return result.toString();
          },
        );

        expect(calls, ['answer']);
        expect(identical(answer, result.toString()), isTrue);
      },
    );

    test('AV tag getters use defaults and preserve each list identity', () {
      final questionTags = <String>['question-tag'];
      final answerTags = <String>['answer-tag'];
      final calls = <String>[];
      final output = _Output(
        questionTags: questionTags,
        answerTags: answerTags,
      );
      final cache = LibAnkiCardRenderOutputCache<_Output, String>(
        renderOutput: output,
      );

      final actualQuestionTags = cache.questionAvTags(
        render: (_) => fail('cached question tags should not reload'),
        questionAvTags: (rendered) {
          calls.add('question tags');
          expect(identical(rendered, output), isTrue);
          return rendered.questionTags;
        },
      );
      final actualAnswerTags = cache.answerAvTags(
        render: (_) => fail('cached answer tags should not reload'),
        answerAvTags: (rendered) {
          calls.add('answer tags');
          expect(identical(rendered, output), isTrue);
          return rendered.answerTags;
        },
      );

      expect(calls, ['question tags', 'answer tags']);
      expect(identical(actualQuestionTags, questionTags), isTrue);
      expect(identical(actualAnswerTags, answerTags), isTrue);
    });

    test('answer AV-tag access renders empty cache in non-browser mode', () {
      final output = _Output();
      final browsers = <bool>[];
      final cache = LibAnkiCardRenderOutputCache<_Output, String>();

      final actualTags = cache.answerAvTags(
        render: (browser) {
          browsers.add(browser);
          return output;
        },
        answerAvTags: (rendered) => rendered.answerTags,
      );

      expect(browsers, [false]);
      expect(identical(actualTags, output.answerTags), isTrue);
    });

    test('a render error prevents derived getters from running', () {
      final failure = StateError('missing template');
      var derivedCalls = 0;
      final cache = LibAnkiCardRenderOutputCache<_Output, String>();

      expect(
        () => cache.question(
          render: (_) => throw failure,
          questionAndStyle: (_) {
            derivedCalls++;
            return 'unreachable';
          },
        ),
        throwsA(same(failure)),
      );
      expect(derivedCalls, 0);
    });
  });
}

final class _Output {
  _Output({this.questionTags = const [], this.answerTags = const []});

  final List<String> questionTags;
  final List<String> answerTags;
}
