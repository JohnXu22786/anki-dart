/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateToMarkdown', () {
    test('composes ordinary values with source section order and spacing', () {
      expect(
        cardTemplateToMarkdown(
          front: 'front value',
          back: 'back value',
          style: 'body { color: red; }',
          frontTemplateHeading: 'Front template',
          backTemplateHeading: 'Back template',
          templateStylingHeading: 'Template styling',
        ),
        '**Front template**\n\n'
        '```html\nfront value\n```\n\n'
        '**Back template**\n\n'
        '```html\nback value\n```\n\n'
        '**Template styling**\n\n'
        '```css\nbody { color: red; }\n```',
      );
    });

    test(
      'preserves empty and multiline inputs while adding source line feeds',
      () {
        expect(
          cardTemplateToMarkdown(
            front: '',
            back: 'line one\nline two',
            style: '',
            frontTemplateHeading: 'F',
            backTemplateHeading: 'B',
            templateStylingHeading: 'S',
          ),
          '**F**\n\n'
          '```html\n\n```\n\n'
          '**B**\n\n'
          '```html\nline one\nline two\n```\n\n'
          '**S**\n\n'
          '```css\n\n```',
        );
      },
    );

    test(
      'preserves markup, backticks, CRLF, and heading characters verbatim',
      () {
        expect(
          cardTemplateToMarkdown(
            front: '<b>front</b>\r\n`raw`',
            back: '{{Field}}\n<hr>\n```',
            style: '/* keep */\r\n.card { color: red; }',
            frontTemplateHeading: '前\n**heading**',
            backTemplateHeading: 'Back `as written`',
            templateStylingHeading: 'Style\r\nsection',
          ),
          '**前\n**heading****\n\n'
          '```html\n<b>front</b>\r\n`raw`\n```\n\n'
          '**Back `as written`**\n\n'
          '```html\n{{Field}}\n<hr>\n```\n```\n\n'
          '**Style\r\nsection**\n\n'
          '```css\n/* keep */\r\n.card { color: red; }\n```',
        );
      },
    );

    test('adds no final LF after the closing CSS fence', () {
      final markdown = cardTemplateToMarkdown(
        front: 'front',
        back: 'back',
        style: 'style\n',
        frontTemplateHeading: 'Front',
        backTemplateHeading: 'Back',
        templateStylingHeading: 'Styling',
      );

      expect(markdown, endsWith('```css\nstyle\n\n```'));
      expect(markdown, isNot(endsWith('\n')));
    });
  });
}
