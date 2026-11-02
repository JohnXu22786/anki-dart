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
  group('apply browser appearance result', () {
    test('null parse warns and skips success path', () {
      final events = <String>[];

      applyBrowserAppearanceResult(
        parse: () {
          events.add('parse');
          return null;
        },
        warn: (message) => events.add('warn:$message'),
        info: (message) => events.add('info:$message'),
        readCurrentTemplate: () {
          events.add('read-template');
          return true;
        },
        setBqfmt: (_) => events.add('bqfmt'),
        setBafmt: (_) => events.add('bafmt'),
        updateDiscardChangeState: () => events.add('update'),
      );

      expect(events, [
        'parse',
        'warn:Error processing Card Template Browser Appearance result',
      ]);
    });

    test('logs before reading the current template once', () {
      final events = <String>[];

      applyBrowserAppearanceResult(
        parse: () => BrowserAppearanceResult(question: 'q', answer: 'a'),
        warn: (_) => events.add('warn'),
        info: (message) => events.add('info:$message'),
        readCurrentTemplate: () {
          events.add('read-template');
          return false;
        },
        setBqfmt: (_) => events.add('bqfmt'),
        setBafmt: (_) => events.add('bafmt'),
        updateDiscardChangeState: () => events.add('update'),
      );

      expect(events, [
        'info:Applying Card Template Browser Appearance result',
        'read-template',
      ]);
    });

    test('null template skips setters and discard-state update', () {
      final events = <String>[];

      applyBrowserAppearanceResult(
        parse: () => BrowserAppearanceResult(question: 'q', answer: 'a'),
        warn: (_) => events.add('warn'),
        info: (_) => events.add('info'),
        readCurrentTemplate: () => false,
        setBqfmt: (_) => events.add('bqfmt'),
        setBafmt: (_) => events.add('bafmt'),
        updateDiscardChangeState: () => events.add('update'),
      );

      expect(events, ['info']);
    });

    test('sets BQ then BA and updates discard state', () {
      final events = <String>[];
      var parseCount = 0;
      var templateReadCount = 0;

      applyBrowserAppearanceResult(
        parse: () {
          parseCount++;
          return BrowserAppearanceResult(
            question: 'question',
            answer: 'answer',
          );
        },
        warn: (_) => events.add('warn'),
        info: (message) => events.add('info:$message'),
        readCurrentTemplate: () {
          templateReadCount++;
          return true;
        },
        setBqfmt: (value) => events.add('bqfmt:$value'),
        setBafmt: (value) => events.add('bafmt:$value'),
        updateDiscardChangeState: () => events.add('update'),
      );

      expect(parseCount, 1);
      expect(templateReadCount, 1);
      expect(events, [
        'info:Applying Card Template Browser Appearance result',
        'bqfmt:question',
        'bafmt:answer',
        'update',
      ]);
    });

    test('question setter failure stops answer setter and update', () {
      final failure = StateError('question setter failed');
      final events = <String>[];

      expect(
        () => applyBrowserAppearanceResult(
          parse: () => BrowserAppearanceResult(question: 'q', answer: 'a'),
          warn: (_) => events.add('warn'),
          info: (_) => events.add('info'),
          readCurrentTemplate: () => true,
          setBqfmt: (_) {
            events.add('bqfmt');
            throw failure;
          },
          setBafmt: (_) => events.add('bafmt'),
          updateDiscardChangeState: () => events.add('update'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['info', 'bqfmt']);
    });

    test('answer setter failure stops discard-state update', () {
      final failure = StateError('answer setter failed');
      final events = <String>[];

      expect(
        () => applyBrowserAppearanceResult(
          parse: () => BrowserAppearanceResult(question: 'q', answer: 'a'),
          warn: (_) => events.add('warn'),
          info: (_) => events.add('info'),
          readCurrentTemplate: () => true,
          setBqfmt: (_) => events.add('bqfmt'),
          setBafmt: (_) {
            events.add('bafmt');
            throw failure;
          },
          updateDiscardChangeState: () => events.add('update'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['info', 'bqfmt', 'bafmt']);
    });

    test('callback failures propagate unchanged', () {
      final parseFailure = StateError('parse failed');
      expect(
        () => applyBrowserAppearanceResult(
          parse: () => throw parseFailure,
          warn: (_) {},
          info: (_) {},
          readCurrentTemplate: () => true,
          setBqfmt: (_) {},
          setBafmt: (_) {},
          updateDiscardChangeState: () {},
        ),
        throwsA(same(parseFailure)),
      );

      final warningFailure = StateError('warning failed');
      expect(
        () => applyBrowserAppearanceResult(
          parse: () => null,
          warn: (_) => throw warningFailure,
          info: (_) {},
          readCurrentTemplate: () => true,
          setBqfmt: (_) {},
          setBafmt: (_) {},
          updateDiscardChangeState: () {},
        ),
        throwsA(same(warningFailure)),
      );

      final infoFailure = StateError('info failed');
      expect(
        () => applyBrowserAppearanceResult(
          parse: () => BrowserAppearanceResult(question: 'q', answer: 'a'),
          warn: (_) {},
          info: (_) => throw infoFailure,
          readCurrentTemplate: () => true,
          setBqfmt: (_) {},
          setBafmt: (_) {},
          updateDiscardChangeState: () {},
        ),
        throwsA(same(infoFailure)),
      );

      final failure = StateError('read failed');
      expect(
        () => applyBrowserAppearanceResult(
          parse: () => BrowserAppearanceResult(question: 'q', answer: 'a'),
          warn: (_) {},
          info: (_) {},
          readCurrentTemplate: () => throw failure,
          setBqfmt: (_) {},
          setBafmt: (_) {},
          updateDiscardChangeState: () {},
        ),
        throwsA(same(failure)),
      );

      final updateFailure = StateError('update failed');
      expect(
        () => applyBrowserAppearanceResult(
          parse: () => BrowserAppearanceResult(question: 'q', answer: 'a'),
          warn: (_) {},
          info: (_) {},
          readCurrentTemplate: () => true,
          setBqfmt: (_) {},
          setBafmt: (_) {},
          updateDiscardChangeState: () => throw updateFailure,
        ),
        throwsA(same(updateFailure)),
      );
    });
  });
}
