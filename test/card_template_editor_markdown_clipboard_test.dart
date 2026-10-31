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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('copyCardTemplateMarkdownToClipboard', () {
    test('returns before reading context when current template is null', () {
      final reached = <String>[];
      copyCardTemplateMarkdownToClipboard(
        callbacks:
            CardTemplateMarkdownClipboardCallbacks<Object, Object, Object>(
              currentTemplate: () {
                reached.add('template');
                return null;
              },
              context: () {
                reached.add('context');
                return Object();
              },
              toMarkdown: (template, context) {
                reached.add('markdown');
                return 'markdown';
              },
              truncate: (markdown) {
                reached.add('truncate');
                return Object();
              },
              copyToClipboard: (context, text) => reached.add('copy'),
            ),
      );

      expect(reached, ['template']);
    });

    test('returns before rendering when context is null', () {
      final reached = <String>[];
      copyCardTemplateMarkdownToClipboard(
        callbacks:
            CardTemplateMarkdownClipboardCallbacks<Object, Object, Object>(
              currentTemplate: () {
                reached.add('template');
                return Object();
              },
              context: () {
                reached.add('context');
                return null;
              },
              toMarkdown: (template, context) {
                reached.add('markdown');
                return 'markdown';
              },
              truncate: (markdown) {
                reached.add('truncate');
                return Object();
              },
              copyToClipboard: (context, text) => reached.add('copy'),
            ),
      );

      expect(reached, ['template', 'context']);
    });

    test('renders, truncates, and copies exact values in source order', () {
      final template = Object();
      final context = Object();
      final markdown = 'template markdown';
      final truncated = Object();
      final reached = <Object?>[];
      copyCardTemplateMarkdownToClipboard(
        callbacks:
            CardTemplateMarkdownClipboardCallbacks<Object, Object, Object>(
              currentTemplate: () {
                reached.add('template');
                return template;
              },
              context: () {
                reached.add('context');
                return context;
              },
              toMarkdown: (actualTemplate, actualContext) {
                reached.add(('markdown', actualTemplate, actualContext));
                return markdown;
              },
              truncate: (actualMarkdown) {
                reached.add(('truncate', actualMarkdown));
                return truncated;
              },
              copyToClipboard: (actualContext, actualText) {
                reached.add(('copy', actualContext, actualText));
              },
            ),
      );

      expect(reached, [
        'template',
        'context',
        ('markdown', template, context),
        ('truncate', markdown),
        ('copy', context, truncated),
      ]);
    });

    test('propagates callback failures and stops later stages', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'template', reached: ['template']),
        (stage: 'context', reached: ['template', 'context']),
        (stage: 'markdown', reached: ['template', 'context', 'markdown']),
        (
          stage: 'truncate',
          reached: ['template', 'context', 'markdown', 'truncate'],
        ),
        (
          stage: 'copy',
          reached: ['template', 'context', 'markdown', 'truncate', 'copy'],
        ),
      ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.stage} failed');
        final reached = <String>[];
        void invoke(String stage) {
          reached.add(stage);
          if (stage == testCase.stage) throw failure;
        }

        expect(
          () => copyCardTemplateMarkdownToClipboard(
            callbacks:
                CardTemplateMarkdownClipboardCallbacks<Object, Object, Object>(
                  currentTemplate: () {
                    invoke('template');
                    return Object();
                  },
                  context: () {
                    invoke('context');
                    return Object();
                  },
                  toMarkdown: (template, context) {
                    invoke('markdown');
                    return 'markdown';
                  },
                  truncate: (markdown) {
                    invoke('truncate');
                    return Object();
                  },
                  copyToClipboard: (context, text) => invoke('copy'),
                ),
          ),
          throwsA(same(failure)),
          reason: 'failure at ${testCase.stage} should propagate',
        );
        expect(reached, testCase.reached, reason: testCase.stage);
      }
    });
  });
}
