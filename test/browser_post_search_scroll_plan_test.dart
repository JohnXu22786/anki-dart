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
 * see ANKIDROID_UPSTREAM.md. These plan cases are source-derived.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser post-search scroll plan', () {
    test('absent pending target produces no effects', () {
      final plan = planBrowserPostSearchScroll(targetCardId: null);
      final completed = completeBrowserPostSearchScrollPlan(
        plan: plan,
        resolvedRowId: 42,
      );

      expect(plan.effects, isEmpty);
      expect(completed.effects, isEmpty);
    });

    test('missing card clears target before lookup and requests no scroll', () {
      final lookupPlan = planBrowserPostSearchScroll(targetCardId: 17);
      final plan = completeBrowserPostSearchScrollPlan(
        plan: lookupPlan,
        resolvedRowId: null,
      );

      expect(lookupPlan.effects, [
        isA<ClearBrowserScrollTarget>(),
        isA<LookupBrowserScrollTarget>().having(
          (effect) => effect.cardId,
          'cardId',
          17,
        ),
      ]);
      expect(plan.effects, lookupPlan.effects);
    });

    test('successful plan orders clear, lookup, and scroll request', () {
      final plan = completeBrowserPostSearchScrollPlan(
        plan: planBrowserPostSearchScroll(targetCardId: 17),
        resolvedRowId: 804,
      );

      expect(plan.effects, [
        isA<ClearBrowserScrollTarget>(),
        isA<LookupBrowserScrollTarget>().having(
          (effect) => effect.cardId,
          'cardId',
          17,
        ),
        isA<RequestBrowserRowScroll>(),
      ]);
    });

    test('passes the host row ID unchanged with zero top offset', () {
      for (final rowId in [17, 804]) {
        final plan = completeBrowserPostSearchScrollPlan(
          plan: planBrowserPostSearchScroll(targetCardId: 17),
          resolvedRowId: rowId,
        );
        final request = plan.effects
            .whereType<RequestBrowserRowScroll>()
            .single;

        expect(request.selection.rowId, BrowserRowId(rowId));
        expect(request.selection.topOffset, 0);
      }
    });
  });
}
