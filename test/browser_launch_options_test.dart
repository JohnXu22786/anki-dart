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
 * Behavioral reference: CardBrowserLaunchOptions.kt and
 * CardBrowserLaunchOptionsTest.kt in AnkiDroid 2.25.3; precedence and
 * present-empty cases are source-derived. See ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser launch-option projection', () {
    test('deep-link search maps to a deep-link option', () {
      expect(
        browserLaunchOptionFromInput(deepLinkSearch: 'dog'),
        const BrowserLaunchDeepLink('dog'),
      );
    });

    test('deep-link option takes precedence, including an empty query', () {
      expect(
        browserLaunchOptionFromInput(
          deepLinkSearch: '',
          searchQueryJs: 'js query',
          allDecks: true,
          cardId: 123,
          actionIsProcessText: true,
          processTextSearch: 'selection',
        ),
        const BrowserLaunchDeepLink(''),
      );
    });

    test('JavaScript search maps query and all-decks value', () {
      expect(
        browserLaunchOptionFromInput(searchQueryJs: 'dog', allDecks: true),
        const BrowserLaunchSearchQueryJs('dog', allDecks: true),
      );
    });

    test('empty JavaScript query remains present and all-decks defaults false',
        () {
      expect(
        browserLaunchOptionFromInput(searchQueryJs: ''),
        const BrowserLaunchSearchQueryJs('', allDecks: false),
      );
    });

    test('JavaScript search takes precedence over card and process text', () {
      expect(
        browserLaunchOptionFromInput(
          searchQueryJs: 'js query',
          cardId: 123,
          actionIsProcessText: true,
          processTextSearch: 'selection',
        ),
        const BrowserLaunchSearchQueryJs('js query', allDecks: false),
      );
    });

    test('card ID maps to a scroll option and precedes process text', () {
      expect(
        browserLaunchOptionFromInput(
          cardId: 123,
          actionIsProcessText: true,
          processTextSearch: 'selection',
        ),
        const BrowserLaunchScrollToCard(123),
      );
    });

    test('non-empty process text maps only for the process-text action', () {
      expect(
        browserLaunchOptionFromInput(
          actionIsProcessText: true,
          processTextSearch: 'selection',
        ),
        const BrowserLaunchSystemContextMenu('selection'),
      );
      expect(
        browserLaunchOptionFromInput(
          actionIsProcessText: true,
          processTextSearch: ' ',
        ),
        const BrowserLaunchSystemContextMenu(' '),
      );
      expect(
        browserLaunchOptionFromInput(processTextSearch: 'selection'),
        isNull,
      );
    });

    test('empty process text and empty intent produce no option', () {
      expect(
        browserLaunchOptionFromInput(
          actionIsProcessText: true,
          processTextSearch: '',
        ),
        isNull,
      );
      expect(browserLaunchOptionFromInput(), isNull);
    });
  });
}
