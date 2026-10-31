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
 * Source-derived from CardTemplateFragment.openBrowserAppearance in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('open card template browser appearance', () {
    test(
      'reads the current template once and skips later callbacks when null',
      () {
        final events = <String>[];
        var readCount = 0;

        final result =
            openCardTemplateBrowserAppearance<Object, Object, Object>(
              getCurrentTemplate: () {
                readCount++;
                events.add('current-template');
                return null;
              },
              readAppContext: () {
                events.add('context');
                return Object();
              },
              createIntent: (_, _) {
                events.add('intent');
                return Object();
              },
              launchActivityResult: (_) => events.add('launch'),
            );

        expect(result, isTrue);
        expect(readCount, 1);
        expect(events, ['current-template']);
      },
    );

    test('passes the exact context and template through ordered callbacks', () {
      final events = <String>[];
      final template = Object();
      final context = Object();
      final intent = Object();

      final result = openCardTemplateBrowserAppearance<Object, Object, Object>(
        getCurrentTemplate: () {
          events.add('current-template');
          return template;
        },
        readAppContext: () {
          events.add('context');
          return context;
        },
        createIntent: (actualContext, actualTemplate) {
          events.add('intent');
          expect(actualContext, same(context));
          expect(actualTemplate, same(template));
          return intent;
        },
        launchActivityResult: (actualIntent) {
          events.add('launch');
          expect(actualIntent, same(intent));
        },
      );

      expect(result, isTrue);
      expect(events, ['current-template', 'context', 'intent', 'launch']);
    });

    test('propagates a current-template callback failure unchanged', () {
      final failure = StateError('current template failed');
      final events = <String>[];

      expect(
        () => openCardTemplateBrowserAppearance<Object, Object, Object>(
          getCurrentTemplate: () {
            events.add('current-template');
            throw failure;
          },
          readAppContext: () {
            events.add('context');
            return Object();
          },
          createIntent: (_, _) => Object(),
          launchActivityResult: (_) => events.add('launch'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['current-template']);
    });

    test(
      'propagates a context callback failure and skips Intent and launch',
      () {
        final failure = StateError('context failed');
        final events = <String>[];

        expect(
          () => openCardTemplateBrowserAppearance<Object, Object, Object>(
            getCurrentTemplate: () => Object(),
            readAppContext: () {
              events.add('context');
              throw failure;
            },
            createIntent: (_, _) {
              events.add('intent');
              return Object();
            },
            launchActivityResult: (_) => events.add('launch'),
          ),
          throwsA(same(failure)),
        );
        expect(events, ['context']);
      },
    );

    test('propagates Intent construction failure and skips launch', () {
      final failure = StateError('Intent construction failed');
      final events = <String>[];

      expect(
        () => openCardTemplateBrowserAppearance<Object, Object, Object>(
          getCurrentTemplate: () => Object(),
          readAppContext: () => Object(),
          createIntent: (_, _) {
            events.add('intent');
            throw failure;
          },
          launchActivityResult: (_) => events.add('launch'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['intent']);
    });

    test('propagates the result-launch callback failure unchanged', () {
      final failure = StateError('launch failed');
      final events = <String>[];

      expect(
        () => openCardTemplateBrowserAppearance<Object, Object, Object>(
          getCurrentTemplate: () => Object(),
          readAppContext: () => Object(),
          createIntent: (_, _) => Object(),
          launchActivityResult: (_) {
            events.add('launch');
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(events, ['launch']);
    });
  });
}
