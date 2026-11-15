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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd <daniel.svard@gmail.com>
 * SPDX-FileCopyrightText: 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * SPDX-FileCopyrightText: 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BackendCardProjection', () {
    test('maps required card fields without changing their values', () {
      final projection = BackendCardProjection.fromCard(
        id: 123,
        nid: 456,
        did: 789,
        ord: 2,
        typeCode: 1,
        queueCode: -2,
        due: 2147483647,
        ivl: -90,
        factor: 2500,
        reps: 13,
        lapses: 4,
        left: 2003,
        oDue: -12,
        oDid: 987,
        flags: 7,
        customData: '{"key":"value"}',
      );

      expect(projection.id, 123);
      expect(projection.noteId, 456);
      expect(projection.deckId, 789);
      expect(projection.templateIdx, 2);
      expect(projection.ctype, 1);
      expect(projection.queue, -2);
      expect(projection.due, 2147483647);
      expect(projection.interval, -90);
      expect(projection.easeFactor, 2500);
      expect(projection.reps, 13);
      expect(projection.lapses, 4);
      expect(projection.remainingSteps, 2003);
      expect(projection.originalDue, -12);
      expect(projection.originalDeckId, 987);
      expect(projection.flags, 7);
      expect(projection.customData, '{"key":"value"}');
      expect(projection.originalPosition, isNull);
      expect(projection.memoryState, isNull);
      expect(projection.desiredRetention, isNull);
      expect(projection.decay, isNull);
      expect(projection.lastReviewTimeSecs, isNull);
    });

    test('preserves present optional values including opaque memory state', () {
      final memoryState = <String, Object>{'stability': 23.5, 'difficulty': 4};
      final projection = BackendCardProjection.fromCard(
        id: 1,
        nid: 2,
        did: 3,
        ord: 4,
        typeCode: 5,
        queueCode: 6,
        due: 7,
        ivl: 8,
        factor: 9,
        reps: 10,
        lapses: 11,
        left: 12,
        oDue: 13,
        oDid: 14,
        flags: 15,
        customData: 'opaque custom data',
        originalPosition: 16,
        memoryState: memoryState,
        desiredRetention: 0.87,
        decay: 0.1542,
        lastReviewTimeSecs: 1712345678,
      );

      expect(projection.originalPosition, 16);
      expect(projection.memoryState, same(memoryState));
      expect(projection.desiredRetention, 0.87);
      expect(projection.decay, 0.1542);
      expect(projection.lastReviewTimeSecs, 1712345678);
    });
  });
}
