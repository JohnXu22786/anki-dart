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
 * Source-derived Reviewer previous-card info routing cases; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer previous-card info directive', () {
    test('selects host-localized no-card feedback when the ID is null', () {
      const noCardMessage = 'Localized no previous card';
      final directive = reviewerPreviousCardInfoDirective(
        previousCardId: null,
        noCardMessage: noCardMessage,
      );

      expect(directive, isA<ReviewerPreviousCardInfoFeedback>());
      expect(
        (directive as ReviewerPreviousCardInfoFeedback).message,
        noCardMessage,
      );
    });

    test('carries any non-null card ID through unchanged, including zero', () {
      for (final cardId in [0, 1234567890123]) {
        final directive = reviewerPreviousCardInfoDirective(
          previousCardId: cardId,
          noCardMessage: 'unused localized message',
        );

        expect(directive, isA<ReviewerPreviousCardInfoNavigation>());
        expect(
          (directive as ReviewerPreviousCardInfoNavigation).cardId,
          cardId,
        );
      }
    });
  });
}
