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
 * Source-derived Reviewer toggle-flag effect cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer toggle-flag plan', () {
    test('matching current and requested flags clear to NONE', () {
      final plan = planReviewerToggleFlag(
        cardId: 982451653,
        currentFlag: PreviewerFlag.red,
        requestedFlag: PreviewerFlag.red,
      );

      expect(plan.updateEffect.flag, PreviewerFlag.none);
    });

    test('different current and requested flags select the request', () {
      final plan = planReviewerToggleFlag(
        cardId: 982451653,
        currentFlag: PreviewerFlag.orange,
        requestedFlag: PreviewerFlag.purple,
      );

      expect(plan.updateEffect.flag, PreviewerFlag.purple);
    });

    test('writes only the supplied current card ID', () {
      const cardId = 982451653;
      final plan = planReviewerToggleFlag(
        cardId: cardId,
        currentFlag: PreviewerFlag.none,
        requestedFlag: PreviewerFlag.turquoise,
      );

      expect(plan.updateEffect.cardIds, [cardId]);
      expect(plan.updateEffect.cardIds, hasLength(1));
    });

    test('publishes the selected flag only after a successful write', () {
      final plan = planReviewerToggleFlag(
        cardId: 73,
        currentFlag: PreviewerFlag.red,
        requestedFlag: PreviewerFlag.green,
      );

      expect(
        plan.publicationAfterUpdate(succeeded: true)!.flag,
        same(plan.updateEffect.flag),
      );
      expect(plan.publicationAfterUpdate(succeeded: false), isNull);
    });
  });
}
