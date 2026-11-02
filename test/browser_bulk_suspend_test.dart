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
  group('planBrowserBulkSuspendToggle', () {
    test('no selected rows return no operation and skip queue lookup', () {
      var inspectedCard = false;

      expect(
        planBrowserBulkSuspendToggle(
          hasSelectedRows: false,
          selectedCardIds: const [1],
          queueForCard: (_) {
            inspectedCard = true;
            throw StateError('no selected rows should skip queue lookup');
          },
        ),
        isNull,
      );
      expect(inspectedCard, isFalse);
    });

    test('all selected cards suspended select unsuspend in source order', () {
      final inspectedIds = <int>[];
      const queueStates = {
        7: BrowserSuspendQueueState.suspended,
        2: BrowserSuspendQueueState.suspended,
      };

      final operation = planBrowserBulkSuspendToggle(
        hasSelectedRows: true,
        selectedCardIds: const [7, 2],
        queueForCard: (id) {
          inspectedIds.add(id);
          return queueStates[id]!;
        },
      );

      expect(operation, BrowserBulkSuspendOperation.unsuspend);
      expect(inspectedIds, [7, 2]);
    });

    test('a mixed selection selects suspend and short-circuits at first other',
        () {
      final inspectedIds = <int>[];
      const queueStates = {
        7: BrowserSuspendQueueState.suspended,
        2: BrowserSuspendQueueState.other,
        9: BrowserSuspendQueueState.suspended,
      };

      final operation = planBrowserBulkSuspendToggle(
        hasSelectedRows: true,
        selectedCardIds: const [7, 2, 9],
        queueForCard: (id) {
          inspectedIds.add(id);
          return queueStates[id]!;
        },
      );

      expect(operation, BrowserBulkSuspendOperation.suspend);
      expect(inspectedIds, [7, 2]);
    });

    test('none suspended selects suspend', () {
      expect(
        planBrowserBulkSuspendToggle(
          hasSelectedRows: true,
          selectedCardIds: const [4, 5],
          queueForCard: (_) => BrowserSuspendQueueState.other,
        ),
        BrowserBulkSuspendOperation.suspend,
      );
    });

    test('selected rows with no resolved card IDs follow all empty', () {
      var inspectedCard = false;

      expect(
        planBrowserBulkSuspendToggle(
          hasSelectedRows: true,
          selectedCardIds: const <int>[],
          queueForCard: (_) {
            inspectedCard = true;
            throw StateError('empty card IDs should not read card queues');
          },
        ),
        BrowserBulkSuspendOperation.unsuspend,
      );
      expect(inspectedCard, isFalse);
    });
  });
}
