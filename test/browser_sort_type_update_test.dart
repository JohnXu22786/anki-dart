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
 * Source-derived from CardBrowserViewModel.setSortType(); see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser sort-type update effects', () {
    test('collection ordering preserves save and publication order', () {
      const sortType = BrowserSortCollectionOrdering(
        key: 'noteFld',
        reverse: true,
      );
      final plan = planBrowserSortTypeUpdate(
        sortType: sortType,
        configKeys: const BrowserSortConfigKeys(
          columnKey: 'cards.column',
          reverseKey: 'cards.reverse',
        ),
      );

      expect(plan.effects, hasLength(4));
      expect(plan.effects.map((effect) => effect.runtimeType), [
        BrowserSortTypeSaveEffect,
        BrowserSortReverseDirectionEffect,
        BrowserSortNotificationEffect,
        BrowserSortSearchEffect,
      ]);

      final save = plan.effects[0] as BrowserSortTypeSaveEffect;
      expect(save.plan.cardBrowserNoSorting, isFalse);
      expect(save.plan.collectionConfigWrites, const [
        BrowserSortConfigWrite(key: 'cards.column', value: 'noteFld'),
        BrowserSortConfigWrite(key: 'cards.reverse', value: true),
      ]);
      expect(
        (plan.effects[1] as BrowserSortReverseDirectionEffect).direction,
        isTrue,
      );
      expect(
        (plan.effects[2] as BrowserSortNotificationEffect).sortType,
        same(sortType),
      );
    });

    test('no ordering clears direction before notification and search', () {
      final plan = planBrowserSortTypeUpdate(
        sortType: const BrowserSortNoOrdering(),
        configKeys: const BrowserSortConfigKeys(
          columnKey: 'notes.column',
          reverseKey: 'notes.reverse',
        ),
      );

      expect(plan.effects.map((effect) => effect.runtimeType), [
        BrowserSortTypeSaveEffect,
        BrowserSortReverseDirectionEffect,
        BrowserSortNotificationEffect,
        BrowserSortSearchEffect,
      ]);
      final save = plan.effects.first as BrowserSortTypeSaveEffect;
      expect(save.plan.cardBrowserNoSorting, isTrue);
      expect(save.plan.collectionConfigWrites, isEmpty);
      expect(
        (plan.effects[1] as BrowserSortReverseDirectionEffect).direction,
        isNull,
      );
      expect(
        (plan.effects[2] as BrowserSortNotificationEffect).sortType,
        isA<BrowserSortNoOrdering>(),
      );
    });
  });
}
