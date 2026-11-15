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
 * Source-derived cases for `LaTeX.kt` in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ExtractedLatexOutput', () {
    test('maps proto-like fields in order without changing content', () {
      final output = ExtractedLatexOutput.fromProtoLike(
        text: '<div>raw &amp; exact</div>',
        latexList: [
          (filename: 'first.svg', latexBody: r'$x_1$'),
          (filename: 'second.svg', latexBody: r'\frac{a}{b}'),
        ],
      );

      expect(output.html, '<div>raw &amp; exact</div>');
      expect(output.latex, [
        const ExtractedLatex(fileName: 'first.svg', latexBody: r'$x_1$'),
        const ExtractedLatex(fileName: 'second.svg', latexBody: r'\frac{a}{b}'),
      ]);
    });
  });

  group('renderLatexRetuningErrors', () {
    final model = LatexModelSettings(svg: true, header: 'head', footer: 'tail');

    test(
      'extracts first with exact parameters, reads config once, and skips media',
      () {
        final calls = <String>[];
        final result = renderLatexRetuningErrors(
          r'<anki-mathjax>x</anki-mathjax>',
          model,
          expandClozes: true,
          extractLatex: ({required text, required svg, required expandClozes}) {
            calls.add('extract:$text:$svg:$expandClozes');
            return ExtractedLatexOutput(
              html: '<p>extracted</p>',
              latex: const [
                ExtractedLatex(fileName: 'present.svg', latexBody: 'x'),
              ],
            );
          },
          renderLatexEnabled: () {
            calls.add('config');
            return false;
          },
          haveMedia: (name) {
            calls.add('media:$name');
            return true;
          },
          latexGenerationDisabledMessage: () =>
              fail('existing media needs no message'),
        );

        expect(result.html, '<p>extracted</p>');
        expect(result.errors, isEmpty);
        expect(calls, [
          'extract:<anki-mathjax>x</anki-mathjax>:true:true',
          'config',
          'media:present.svg',
        ]);
      },
    );

    test('reports only the first missing item when rendering is disabled', () {
      final calls = <String>[];
      final result = renderLatexRetuningErrors(
        'input',
        model,
        extractLatex: ({required text, required svg, required expandClozes}) =>
            ExtractedLatexOutput(
              html: 'extracted',
              latex: const [
                ExtractedLatex(fileName: 'cached', latexBody: 'a'),
                ExtractedLatex(fileName: 'missing-one', latexBody: 'b'),
                ExtractedLatex(fileName: 'missing-two', latexBody: 'c'),
              ],
            ),
        renderLatexEnabled: () {
          calls.add('config');
          return false;
        },
        haveMedia: (name) {
          calls.add('media:$name');
          return name == 'cached';
        },
        latexGenerationDisabledMessage: () {
          calls.add('message');
          return 'LaTeX generation disabled';
        },
      );

      expect(result.html, 'extracted');
      expect(result.errors, ['LaTeX generation disabled']);
      expect(calls, ['config', 'media:cached', 'media:missing-one', 'message']);
    });

    test('enabled rendering checks all missing media and adds no errors', () {
      final media = <String>[];
      final result = renderLatexRetuningErrors(
        'input',
        model,
        extractLatex: ({required text, required svg, required expandClozes}) =>
            ExtractedLatexOutput(
              html: 'enabled-html',
              latex: const [
                ExtractedLatex(fileName: 'one', latexBody: '1'),
                ExtractedLatex(fileName: 'two', latexBody: '2'),
              ],
            ),
        renderLatexEnabled: () => true,
        haveMedia: (name) {
          media.add(name);
          return false;
        },
        latexGenerationDisabledMessage: () =>
            fail('enabled mode is not disabled'),
      );

      expect(media, ['one', 'two']);
      expect(result.html, 'enabled-html');
      expect(result.errors, isEmpty);
    });

    test(
      'backend, config, media, and localization failures propagate at source order',
      () {
        final backendError = StateError('backend');
        expect(
          () => renderLatexRetuningErrors(
            'input',
            model,
            extractLatex:
                ({required text, required svg, required expandClozes}) =>
                    throw backendError,
            renderLatexEnabled: () => fail('config follows extraction'),
            haveMedia: (_) => fail('media follows extraction'),
            latexGenerationDisabledMessage: () =>
                fail('message follows extraction'),
          ),
          throwsA(same(backendError)),
        );

        final configError = StateError('config');
        expect(
          () => renderLatexRetuningErrors(
            'input',
            model,
            extractLatex:
                ({required text, required svg, required expandClozes}) =>
                    ExtractedLatexOutput(html: 'html', latex: const []),
            renderLatexEnabled: () => throw configError,
            haveMedia: (_) => fail('media follows config'),
            latexGenerationDisabledMessage: () =>
                fail('message follows config'),
          ),
          throwsA(same(configError)),
        );

        final mediaError = StateError('media');
        expect(
          () => renderLatexRetuningErrors(
            'input',
            model,
            extractLatex:
                ({required text, required svg, required expandClozes}) =>
                    ExtractedLatexOutput(
                      html: 'html',
                      latex: const [
                        ExtractedLatex(fileName: 'missing', latexBody: 'x'),
                      ],
                    ),
            renderLatexEnabled: () => false,
            haveMedia: (_) => throw mediaError,
            latexGenerationDisabledMessage: () => fail('message follows media'),
          ),
          throwsA(same(mediaError)),
        );

        final messageError = StateError('message');
        expect(
          () => renderLatexRetuningErrors(
            'input',
            model,
            extractLatex:
                ({required text, required svg, required expandClozes}) =>
                    ExtractedLatexOutput(
                      html: 'html',
                      latex: const [
                        ExtractedLatex(fileName: 'missing', latexBody: 'x'),
                      ],
                    ),
            renderLatexEnabled: () => false,
            haveMedia: (_) => false,
            latexGenerationDisabledMessage: () => throw messageError,
          ),
          throwsA(same(messageError)),
        );
      },
    );
  });

  test('renderLatex appends errors without adding a delimiter', () {
    expect(
      renderLatex(
        'html',
        const LatexModelSettings(svg: false, header: '', footer: ''),
        extractLatex: ({required text, required svg, required expandClozes}) =>
            ExtractedLatexOutput(
              html: 'extracted<br>',
              latex: const [
                ExtractedLatex(fileName: 'missing', latexBody: 'x'),
              ],
            ),
        renderLatexEnabled: () => false,
        haveMedia: (_) => false,
        latexGenerationDisabledMessage: () => 'LaTeX generation disabled',
      ),
      'extracted<br>LaTeX generation disabled',
    );
  });

  group('onCardDidRender', () {
    test('requests note type and renders question before answer', () {
      final calls = <String>[];
      final output = LatexCardRenderOutput(
        questionText: 'question',
        answerText: 'answer',
      );
      final result = onCardDidRender(
        output: output,
        noteType: () {
          calls.add('noteType');
          return const LatexModelSettings(svg: false, header: '', footer: '');
        },
        extractLatex: ({required text, required svg, required expandClozes}) {
          calls.add('extract:$text');
          return ExtractedLatexOutput(html: 'rendered-$text', latex: const []);
        },
        renderLatexEnabled: () {
          calls.add('config');
          return true;
        },
        haveMedia: (_) => false,
        latexGenerationDisabledMessage: () => 'not used',
      );

      expect(result.questionText, 'rendered-question');
      expect(result.answerText, 'rendered-answer');
      expect(result, same(output));
      expect(calls, [
        'noteType',
        'extract:question',
        'config',
        'noteType',
        'extract:answer',
        'config',
      ]);
    });

    test('stops after a question callback failure', () {
      final error = StateError('question failed');
      final calls = <String>[];
      final output = LatexCardRenderOutput(
        questionText: 'question',
        answerText: 'answer',
      );
      expect(
        () => onCardDidRender(
          output: output,
          noteType: () {
            calls.add('noteType');
            return const LatexModelSettings(svg: false, header: '', footer: '');
          },
          extractLatex:
              ({required text, required svg, required expandClozes}) =>
                  throw error,
          renderLatexEnabled: () => fail('config follows extraction'),
          haveMedia: (_) => fail('media follows extraction'),
          latexGenerationDisabledMessage: () =>
              fail('message follows extraction'),
        ),
        throwsA(same(error)),
      );
      expect(calls, ['noteType']);
      expect(output.questionText, 'question');
      expect(output.answerText, 'answer');
    });

    test('keeps the question update when answer rendering fails', () {
      final answerError = StateError('answer failed');
      final output = LatexCardRenderOutput(
        questionText: 'question',
        answerText: 'answer',
      );
      final calls = <String>[];

      expect(
        () => onCardDidRender(
          output: output,
          noteType: () {
            calls.add('noteType');
            return const LatexModelSettings(svg: false, header: '', footer: '');
          },
          extractLatex: ({required text, required svg, required expandClozes}) {
            calls.add('extract:$text');
            if (text == 'answer') throw answerError;
            return ExtractedLatexOutput(
              html: 'rendered-$text',
              latex: const [],
            );
          },
          renderLatexEnabled: () {
            calls.add('config');
            return true;
          },
          haveMedia: (_) => false,
          latexGenerationDisabledMessage: () => 'not used',
        ),
        throwsA(same(answerError)),
      );

      expect(output.questionText, 'rendered-question');
      expect(output.answerText, 'answer');
      expect(calls, [
        'noteType',
        'extract:question',
        'config',
        'noteType',
        'extract:answer',
      ]);
    });
  });
}
