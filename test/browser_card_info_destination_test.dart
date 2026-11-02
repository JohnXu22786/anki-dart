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
 * Source-derived Card Browser card-info destination cases; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser card-info destination', () {
    test('empty selection produces no destination', () {
      expect(browserCardInfoDestination(selectedCardIds: const []), isNull);
    });

    test('an invalid first card ID does not fall through to a later row', () {
      expect(
        browserCardInfoDestination(selectedCardIds: [null, 42]),
        isNull,
      );
    });

    test('the first card ID passes through with the browser entry point', () {
      for (final cardId in [0, -1, 1234567890123]) {
        final destination = browserCardInfoDestination(
          selectedCardIds: [cardId, 42],
        );

        expect(destination, isNotNull);
        expect(destination!.cardId, cardId);
        expect(
          destination.entryPoint,
          BrowserCardInfoEntryPoint.CURRENT_CARD_BROWSE,
        );
      }
    });
  });
}
