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
 * Source-derived Reviewer set/toggle callback orchestration cases; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer set-flag operation', () {
    test(
      'looks up once, updates one card, then publishes the same flag',
      () async {
        final events = <String>[];
        var lookups = 0;
        List<int>? updatedCardIds;
        PreviewerFlag? updatedFlag;
        PreviewerFlag? publishedFlag;
        const flag = PreviewerFlag.purple;

        await executeReviewerSetFlagOperation(
          currentCardId: () {
            events.add('lookup');
            lookups++;
            return 982451653;
          },
          updateFlags: (cardIds, value) async {
            events.add('update');
            updatedCardIds = cardIds;
            updatedFlag = value;
          },
          publishFlag: (value) {
            events.add('publish');
            publishedFlag = value;
          },
          flag: flag,
        );

        expect(events, ['lookup', 'update', 'publish']);
        expect(lookups, 1);
        expect(updatedCardIds, [982451653]);
        expect(updatedCardIds, hasLength(1));
        expect(updatedFlag, same(flag));
        expect(publishedFlag, same(flag));
      },
    );

    test(
      'lookup failure propagates unchanged and stops the operation',
      () async {
        final events = <String>[];
        final failure = StateError('card lookup failed');

        await expectLater(
          executeReviewerSetFlagOperation(
            currentCardId: () {
              events.add('lookup');
              throw failure;
            },
            updateFlags: (_, _) async => events.add('update'),
            publishFlag: (_) => events.add('publish'),
            flag: PreviewerFlag.red,
          ),
          throwsA(same(failure)),
        );

        expect(events, ['lookup']);
      },
    );

    test('update failure propagates unchanged and skips publication', () async {
      final events = <String>[];
      final failure = StateError('undoable update failed');

      await expectLater(
        executeReviewerSetFlagOperation(
          currentCardId: () {
            events.add('lookup');
            return 73;
          },
          updateFlags: (_, _) async {
            events.add('update');
            throw failure;
          },
          publishFlag: (_) => events.add('publish'),
          flag: PreviewerFlag.green,
        ),
        throwsA(same(failure)),
      );

      expect(events, ['lookup', 'update']);
    });
  });

  group('Reviewer toggle-flag operation', () {
    test(
      'reads once and clears an equal flag through ordered set callbacks',
      () async {
        final events = <String>[];
        var flagReads = 0;
        var cardLookups = 0;
        List<int>? updatedCardIds;
        PreviewerFlag? updatedFlag;
        PreviewerFlag? publishedFlag;

        await executeReviewerToggleFlagOperation(
          currentFlag: () {
            events.add('readFlag');
            flagReads++;
            return PreviewerFlag.orange;
          },
          currentCardId: () {
            events.add('lookup');
            cardLookups++;
            return 982451653;
          },
          updateFlags: (cardIds, value) async {
            events.add('update');
            updatedCardIds = cardIds;
            updatedFlag = value;
          },
          publishFlag: (value) {
            events.add('publish');
            publishedFlag = value;
          },
          flag: PreviewerFlag.orange,
        );

        expect(events, ['readFlag', 'lookup', 'update', 'publish']);
        expect(flagReads, 1);
        expect(cardLookups, 1);
        expect(updatedCardIds, [982451653]);
        expect(updatedFlag, same(PreviewerFlag.none));
        expect(publishedFlag, same(updatedFlag));
      },
    );

    test(
      'preserves a different requested flag through update and publication',
      () async {
        final events = <String>[];
        const requested = PreviewerFlag.turquoise;
        PreviewerFlag? updatedFlag;
        PreviewerFlag? publishedFlag;

        await executeReviewerToggleFlagOperation(
          currentFlag: () {
            events.add('readFlag');
            return PreviewerFlag.pink;
          },
          currentCardId: () {
            events.add('lookup');
            return 73;
          },
          updateFlags: (cardIds, value) async {
            events.add('update');
            expect(cardIds, [73]);
            updatedFlag = value;
          },
          publishFlag: (value) {
            events.add('publish');
            publishedFlag = value;
          },
          flag: requested,
        );

        expect(events, ['readFlag', 'lookup', 'update', 'publish']);
        expect(updatedFlag, same(requested));
        expect(publishedFlag, same(requested));
      },
    );

    test(
      'flag read failure propagates unchanged and stops later callbacks',
      () async {
        final events = <String>[];
        final failure = StateError('flag read failed');

        await expectLater(
          executeReviewerToggleFlagOperation(
            currentFlag: () {
              events.add('readFlag');
              throw failure;
            },
            currentCardId: () {
              events.add('lookup');
              return 73;
            },
            updateFlags: (_, _) async => events.add('update'),
            publishFlag: (_) => events.add('publish'),
            flag: PreviewerFlag.red,
          ),
          throwsA(same(failure)),
        );

        expect(events, ['readFlag']);
      },
    );

    test(
      'card lookup failure propagates unchanged and stops later callbacks',
      () async {
        final events = <String>[];
        final failure = StateError('card lookup failed');

        await expectLater(
          executeReviewerToggleFlagOperation(
            currentFlag: () {
              events.add('readFlag');
              return PreviewerFlag.none;
            },
            currentCardId: () {
              events.add('lookup');
              throw failure;
            },
            updateFlags: (_, _) async => events.add('update'),
            publishFlag: (_) => events.add('publish'),
            flag: PreviewerFlag.red,
          ),
          throwsA(same(failure)),
        );

        expect(events, ['readFlag', 'lookup']);
      },
    );

    test('update failure propagates unchanged and skips publication', () async {
      final events = <String>[];
      final failure = StateError('undoable update failed');

      await expectLater(
        executeReviewerToggleFlagOperation(
          currentFlag: () {
            events.add('readFlag');
            return PreviewerFlag.blue;
          },
          currentCardId: () {
            events.add('lookup');
            return 73;
          },
          updateFlags: (_, _) async {
            events.add('update');
            throw failure;
          },
          publishFlag: (_) => events.add('publish'),
          flag: PreviewerFlag.green,
        ),
        throwsA(same(failure)),
      );

      expect(events, ['readFlag', 'lookup', 'update']);
    });
  });
}
