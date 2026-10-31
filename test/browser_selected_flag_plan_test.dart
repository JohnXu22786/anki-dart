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
 * Source-derived cases for CardBrowserViewModel.updateSelectedCardsFlag();
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserSelectedCardsFlagUpdate', () {
    test('preserves flag and the exact ordered selected ID list', () {
      final ids = <int>[8, 3, 8];
      final flag = Object();

      final plan = planBrowserSelectedCardsFlagUpdate(
        selectedCardIds: ids,
        flag: flag,
      );

      expect(plan.selectedCardIds, same(ids));
      expect(plan.returnedCardIds, same(ids));
      expect(plan.flag, same(flag));
      final mutation = plan.effects.first as BrowserSetSelectedCardsFlagEffect;
      expect(mutation.cardIds, same(ids));
      expect(mutation.flag, same(flag));
    });

    test('orders successful flag mutation before state-changed publication',
        () {
      final plan = planBrowserSelectedCardsFlagUpdate(
        selectedCardIds: <int>[1],
        flag: 'blue',
      );

      expect(plan.effects, hasLength(2));
      expect(
        plan.effects.map((effect) => effect.runtimeType),
        [
          BrowserSetSelectedCardsFlagEffect<int, String>,
          BrowserPublishCardStateChangedEffect<int, String>,
        ],
      );
    });

    test('empty selected IDs still produce both source effects', () {
      const ids = <int>[];

      final plan = planBrowserSelectedCardsFlagUpdate(
        selectedCardIds: ids,
        flag: 'none',
      );

      expect(plan.selectedCardIds, same(ids));
      expect(plan.returnedCardIds, same(ids));
      expect(plan.effects, hasLength(2));
      expect(plan.effects.first, isA<BrowserSetSelectedCardsFlagEffect>());
      expect(
        plan.effects.last,
        isA<BrowserPublishCardStateChangedEffect>(),
      );
    });
  });
}
