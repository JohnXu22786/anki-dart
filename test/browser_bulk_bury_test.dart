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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserBulkBuryToggle', () {
    test('no selected rows produce no plan and skip card state lookup', () {
      var inspectedCard = false;

      expect(
        planBrowserBulkBuryToggle(
          hasSelectedRows: false,
          selectedCardIds: const [1],
          queueForCard: (_) {
            inspectedCard = true;
            throw StateError('no selected rows should skip card lookup');
          },
        ),
        isNull,
      );
      expect(inspectedCard, isFalse);
    });

    test('all buried cards plan unbury and return source result values', () {
      final inspectedIds = <int>[];
      const queues = {
        7: BrowserBuryQueueState.manuallyBuried,
        2: BrowserBuryQueueState.siblingBuried,
        9: BrowserBuryQueueState.manuallyBuried,
      };

      final plan = planBrowserBulkBuryToggle(
        hasSelectedRows: true,
        selectedCardIds: const [7, 2, 9],
        queueForCard: (id) {
          inspectedIds.add(id);
          return queues[id]!;
        },
      );

      expect(plan, const BrowserBulkBuryPlan(wasBuried: false, count: 3));
      expect(inspectedIds, [7, 2, 9]);
    });

    test('any unburied card plans bury, matching source all-card decision', () {
      final inspectedIds = <int>[];
      const queues = {
        7: BrowserBuryQueueState.manuallyBuried,
        2: BrowserBuryQueueState.other,
        9: BrowserBuryQueueState.siblingBuried,
      };

      final plan = planBrowserBulkBuryToggle(
        hasSelectedRows: true,
        selectedCardIds: const [7, 2, 9],
        queueForCard: (id) {
          inspectedIds.add(id);
          return queues[id]!;
        },
      );

      expect(plan, const BrowserBulkBuryPlan(wasBuried: true, count: 3));
      expect(inspectedIds, [7, 2]);

      expect(
        planBrowserBulkBuryToggle(
          hasSelectedRows: true,
          selectedCardIds: const [4, 5],
          queueForCard: (_) => BrowserBuryQueueState.other,
        ),
        const BrowserBulkBuryPlan(wasBuried: true, count: 2),
      );
    });

    test('selected rows resolving to no cards preserve all(empty)', () {
      final inspectedIds = <int>[];

      final plan = planBrowserBulkBuryToggle(
        hasSelectedRows: true,
        selectedCardIds: const <int>[],
        queueForCard: (id) {
          inspectedIds.add(id);
          return BrowserBuryQueueState.other;
        },
      );

      expect(plan, const BrowserBulkBuryPlan(wasBuried: false, count: 0));
      expect(inspectedIds, isEmpty);
    });

    test('source result value has structural equality and hash', () {
      const plan = BrowserBulkBuryPlan(wasBuried: true, count: 2);

      expect(
        plan,
        const BrowserBulkBuryPlan(wasBuried: true, count: 2),
      );
      expect(
        plan.hashCode,
        const BrowserBulkBuryPlan(wasBuried: true, count: 2).hashCode,
      );
      expect(plan, isNot(const BrowserBulkBuryPlan(wasBuried: true, count: 3)));
      expect(
          plan, isNot(const BrowserBulkBuryPlan(wasBuried: false, count: 2)));
    });
  });
}
