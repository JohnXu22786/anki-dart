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
 * Source-derived Reviewer suspend-card effect cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer suspend-card plan', () {
    test('suspends only the supplied card before feedback and reload', () {
      const cardId = 821;
      final effects = planReviewerSuspendCard(
        cardId: cardId,
        suspendedMessage: 'Card suspended',
      );

      expect(effects, hasLength(3));
      expect(effects.map((effect) => effect.runtimeType), [
        SuspendReviewerCardEffect,
        ShowReviewerSuspendFeedbackEffect,
        ReloadReviewerCurrentCardEffect,
      ]);
      expect((effects[0] as SuspendReviewerCardEffect).cardId, cardId);
    });

    test('passes host-localized feedback text through unchanged', () {
      const message = '  Card suspended — 暂停  ';

      final effects = planReviewerSuspendCard(
        cardId: 1,
        suspendedMessage: message,
      );

      expect(
        (effects[1] as ShowReviewerSuspendFeedbackEffect).message,
        message,
      );
    });

    test('suspend effect carries no scheduler count result', () {
      final effect =
          planReviewerSuspendCard(
                cardId: 73,
                suspendedMessage: 'Suspended',
              ).first
              as SuspendReviewerCardEffect;

      // The source discards suspendCards()'s count; the host effect only needs
      // the card ID and its success/failure boundary.
      expect(effect.cardId, 73);
    });
  });
}
