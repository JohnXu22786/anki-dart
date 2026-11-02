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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('template pager stable IDs', () {
    test('starts from the source signed-Long zero base', () {
      expect(initialTemplatePagerBaseId, BigInt.zero);
    });

    test('builds ordinary IDs with signed Int64 wrap', () {
      expect(
        templatePagerGetItemId(baseId: BigInt.from(10), position: 3),
        BigInt.from(13),
      );
      expect(
        templatePagerGetItemId(
          baseId: BigInt.parse('9223372036854775807'),
          position: 1,
        ),
        BigInt.parse('-9223372036854775808'),
      );
      expect(
        templatePagerGetItemId(
          baseId: BigInt.parse('-9223372036854775808'),
          position: -1,
        ),
        BigInt.parse('9223372036854775807'),
      );
    });

    test('contains only IDs in the current item range', () {
      var countReads = 0;
      bool contains(BigInt id) => templatePagerContainsItem(
        id: id,
        readBaseId: () => BigInt.from(20),
        itemCount: () {
          countReads++;
          return 3;
        },
      );

      expect(contains(BigInt.from(20)), isTrue);
      expect(contains(BigInt.from(22)), isTrue);
      expect(contains(BigInt.from(23)), isFalse);
      expect(contains(BigInt.from(19)), isFalse);
      expect(contains(BigInt.from(900)), isFalse);
      expect(countReads, 5);
    });

    test(
      'contains uses signed Int64 wrap for delta underflow and overflow',
      () {
        var countReads = 0;
        bool contains(BigInt id, BigInt baseId) => templatePagerContainsItem(
          id: id,
          readBaseId: () => baseId,
          itemCount: () {
            countReads++;
            return 1;
          },
        );

        expect(
          contains(BigInt.parse('-9223372036854775808'), BigInt.one),
          isFalse,
        );
        expect(
          contains(BigInt.parse('9223372036854775807'), -BigInt.one),
          isFalse,
        );
        expect(countReads, 2);
      },
    );

    test('ordinal shift wraps Int32 increment before Int64 addition', () {
      final events = <String>[];
      BigInt? written;

      templatePagerOrdinalShift(
        readBaseId: () {
          events.add('base');
          return BigInt.zero;
        },
        itemCount: () {
          events.add('count');
          return 2147483647;
        },
        writeBaseId: (value) {
          events.add('write');
          written = value;
        },
      );

      expect(events, ['base', 'count', 'write']);
      expect(written, BigInt.from(-2147483648));
    });

    test('ordinal shift wraps signed Int64 base addition', () {
      BigInt? written;

      templatePagerOrdinalShift(
        readBaseId: () => BigInt.parse('9223372036854775807'),
        itemCount: () => 0,
        writeBaseId: (value) => written = value,
      );

      expect(written, BigInt.parse('-9223372036854775808'));
    });

    test(
      'callbacks run in source order once and failures stop later actions',
      () {
        final events = <String>[];
        final baseError = StateError('base');
        expect(
          () => templatePagerContainsItem(
            id: BigInt.zero,
            readBaseId: () {
              events.add('base');
              throw baseError;
            },
            itemCount: () {
              events.add('count');
              return 1;
            },
          ),
          throwsA(same(baseError)),
        );
        expect(events, ['base']);

        events.clear();
        final countError = StateError('count');
        expect(
          () => templatePagerOrdinalShift(
            readBaseId: () {
              events.add('base');
              return BigInt.zero;
            },
            itemCount: () {
              events.add('count');
              throw countError;
            },
            writeBaseId: (_) => events.add('write'),
          ),
          throwsA(same(countError)),
        );
        expect(events, ['base', 'count']);

        events.clear();
        final writeError = StateError('write');
        expect(
          () => templatePagerOrdinalShift(
            readBaseId: () {
              events.add('base');
              return BigInt.zero;
            },
            itemCount: () {
              events.add('count');
              return 1;
            },
            writeBaseId: (_) {
              events.add('write');
              throw writeError;
            },
          ),
          throwsA(same(writeError)),
        );
        expect(events, ['base', 'count', 'write']);
      },
    );
  });
}
