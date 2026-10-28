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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md. These state-patch cases are source-derived.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser launch initial-state patch', () {
    test('system text and deep link assign only their exact search text', () {
      for (final option in [
        const BrowserLaunchSystemContextMenu(''),
        const BrowserLaunchDeepLink('deck:current'),
      ]) {
        final patch = projectBrowserLaunchState(option);

        expect(patch.searchTerms, isA<BrowserLaunchAssigned<String>>());
        expect(
          (patch.searchTerms as BrowserLaunchAssigned<String>).value,
          option is BrowserLaunchSystemContextMenu ? '' : 'deck:current',
        );
        expect(patch.allDecks, isA<BrowserLaunchUnchanged<bool>>());
        expect(patch.cardIdToBeScrolledTo, isA<BrowserLaunchUnchanged<int>>());
      }
    });

    test(
      'JavaScript search explicitly assigns search and all-decks false or true',
      () {
        for (final allDecks in [false, true]) {
          final patch = projectBrowserLaunchState(
            BrowserLaunchSearchQueryJs('', allDecks: allDecks),
          );

          expect(
            (patch.searchTerms as BrowserLaunchAssigned<String>).value,
            '',
          );
          expect(
            (patch.allDecks as BrowserLaunchAssigned<bool>).value,
            allDecks,
          );
          expect(
            patch.cardIdToBeScrolledTo,
            isA<BrowserLaunchUnchanged<int>>(),
          );
        }
      },
    );

    test(
      'scroll option assigns its card ID and leaves search and all-decks alone',
      () {
        final patch = projectBrowserLaunchState(
          const BrowserLaunchScrollToCard(-42),
        );

        expect(patch.searchTerms, isA<BrowserLaunchUnchanged<String>>());
        expect(patch.allDecks, isA<BrowserLaunchUnchanged<bool>>());
        expect(
          (patch.cardIdToBeScrolledTo as BrowserLaunchAssigned<int>).value,
          -42,
        );
      },
    );

    test('null option leaves every field unchanged', () {
      final patch = projectBrowserLaunchState(null);

      expect(patch.searchTerms, isA<BrowserLaunchUnchanged<String>>());
      expect(patch.allDecks, isA<BrowserLaunchUnchanged<bool>>());
      expect(patch.cardIdToBeScrolledTo, isA<BrowserLaunchUnchanged<int>>());
    });
  });
}
