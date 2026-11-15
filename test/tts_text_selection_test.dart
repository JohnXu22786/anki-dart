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
 * Source-derived cases for TtsParser's portable selection behavior.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('selectTtsText', () {
    test(
      'uses body text and replaces every marker when no TTS node matches',
      () {
        final result = selectTtsText(
          root: TtsDomNode(tagName: 'body', text: 'One [...] and [...]'),
          bodyText: 'One [...] and [...]',
          clozeReplacement: 'blank',
        );

        expect(result, [const TtsTextLocale('One blank and blank', '')]);
      },
    );

    test('recognizes tag and service case insensitively and passes voice', () {
      final result = selectTtsText(
        root: TtsDomNode(
          tagName: 'BODY',
          children: [
            TtsDomNode(
              tagName: 'TtS',
              service: 'AnDrOiD',
              voice: 'en-US-x-test',
              text: 'Say [...]',
              children: [
                TtsDomNode(
                  tagName: 'tts',
                  service: 'android',
                  voice: 'ignored',
                  text: 'child',
                ),
              ],
            ),
          ],
        ),
        bodyText: 'fallback',
        clozeReplacement: 'blank',
      );

      expect(result, [const TtsTextLocale('Say blank', 'en-US-x-test')]);
    });

    test('retains source order for multiple and nested matches', () {
      final result = selectTtsText(
        root: TtsDomNode(
          tagName: 'body',
          children: [
            TtsDomNode(
              tagName: 'section',
              children: [
                TtsDomNode(tagName: 'tts', service: 'android', text: 'first'),
                TtsDomNode(
                  tagName: 'div',
                  children: [
                    TtsDomNode(
                      tagName: 'tts',
                      service: 'android',
                      text: 'second',
                    ),
                  ],
                ),
              ],
            ),
            TtsDomNode(tagName: 'tts', service: 'android', text: 'third'),
          ],
        ),
        bodyText: 'fallback',
        clozeReplacement: 'blank',
      );

      expect(result, [
        const TtsTextLocale('first', ''),
        const TtsTextLocale('second', ''),
        const TtsTextLocale('third', ''),
      ]);
    });

    test('empty explicit TTS text suppresses body fallback', () {
      final result = selectTtsText(
        root: TtsDomNode(
          tagName: 'body',
          children: [TtsDomNode(tagName: 'tts', service: 'android', text: '')],
        ),
        bodyText: 'fallback',
        clozeReplacement: 'blank',
      );

      expect(result, [const TtsTextLocale('', '')]);
    });
  });
}
