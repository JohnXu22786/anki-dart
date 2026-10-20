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
 * Behavioral references: SearchHistory.kt, SearchHistoryTest.kt,
 * FlagSerializerTest.kt, and CardStateSerializerTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser search history', () {
    test('skips a Kotlin-blank query with no active filters', () {
      final history = BrowserSearchHistoryModel();

      expect(
        history.addRecent(const BrowserSearchHistoryEntry(query: ' \u00a0\t')),
        isEmpty,
      );
      expect(history.entries, isEmpty);
    });

    test('keeps a blank query when filters are set', () {
      final history = BrowserSearchHistoryModel();
      const entry = BrowserSearchHistoryEntry(query: '  ', tags: ['tag']);

      expect(history.addRecent(entry), [entry]);
      expect(entry.isSearchEmpty, isFalse);
    });

    test('moves a structurally equal duplicate to the front', () {
      final history = BrowserSearchHistoryModel();
      const first = BrowserSearchHistoryEntry(
        query: 'query',
        deckIds: [8],
        flags: [1, 4],
        tags: ['tag'],
        noteTypeIds: [7],
        cardStateCodes: [0, 2],
      );
      const second = BrowserSearchHistoryEntry(query: 'other');

      history.addRecent(first);
      history.addRecent(second);
      final moved = history.addRecent(
        const BrowserSearchHistoryEntry(
          query: 'query',
          deckIds: [8],
          flags: [1, 4],
          tags: ['tag'],
          noteTypeIds: [7],
          cardStateCodes: [0, 2],
        ),
      );

      expect(moved, [first, second]);
    });

    test('entries with the same query but different filters remain distinct',
        () {
      final history = BrowserSearchHistoryModel();
      const first = BrowserSearchHistoryEntry(query: 'query', deckIds: [1]);
      const second = BrowserSearchHistoryEntry(query: 'query', deckIds: [2]);

      history.addRecent(first);
      history.addRecent(second);

      expect(history.entries, [second, first]);
      expect(first, isNot(second));
    });

    test('keeps newest entries first and caps the default history at 30', () {
      final history = BrowserSearchHistoryModel();
      for (var index = 1; index <= 31; index++) {
        history.addRecent(BrowserSearchHistoryEntry(query: '$index'));
      }

      expect(history.entries, hasLength(30));
      expect(history.entries.first.query, '31');
      expect(history.entries.last.query, '2');
    });

    test('remove reports whether a structurally matching entry existed', () {
      final history = BrowserSearchHistoryModel();
      const stored = BrowserSearchHistoryEntry(query: 'query', tags: ['tag']);
      const matchingCopy = BrowserSearchHistoryEntry(
        query: 'query',
        tags: ['tag'],
      );
      history.addRecent(stored);

      expect(history.removeEntry(matchingCopy), isTrue);
      expect(history.entries, isEmpty);
      expect(history.removeEntry(matchingCopy), isFalse);
    });

    test('clear removes all entries', () {
      final history = BrowserSearchHistoryModel();
      history.addRecent(const BrowserSearchHistoryEntry(query: 'query'));

      history.clear();

      expect(history.entries, isEmpty);
    });
  });

  group('Card Browser search history JSON codec', () {
    test('encodes a v1 entry with only the required query field', () {
      expect(
        BrowserSearchHistoryJsonCodec.encode([
          const BrowserSearchHistoryEntry(query: '1'),
        ]),
        '[{"q":"1"}]',
      );
      expect(BrowserSearchHistoryJsonCodec.encode([]), '[]');
    });

    test('encodes and decodes the canonical v2 field order and codes', () {
      const entry = BrowserSearchHistoryEntry(
        query: 'queryString',
        deckIds: [1, 2],
        flags: [1, 4],
        tags: ['Hello::World', 'tag'],
        noteTypeIds: [3, 4],
        cardStateCodes: [0, 1, 2, 3, 4],
      );
      const json =
          '[{"q":"queryString","did":[1,2],"f":[1,4],"t":["Hello::World","tag"],"ntid":[3,4],"s":[0,1,2,3,4]}]';

      expect(BrowserSearchHistoryJsonCodec.encode([entry]), json);
      expect(BrowserSearchHistoryJsonCodec.decode(json), [entry]);
    });

    test('defaults missing optional arrays to empty', () {
      expect(
        BrowserSearchHistoryJsonCodec.decode('[{"q":"1"}]'),
        [const BrowserSearchHistoryEntry(query: '1')],
      );
    });

    test('preserves signed 64-bit ID boundaries and rejects out-of-range IDs',
        () {
      final entry = BrowserSearchHistoryEntry(
        query: 'ids',
        deckIds: [
          int.parse('9223372036854775807'),
          int.parse('-9223372036854775808'),
        ],
        noteTypeIds: [
          int.parse('-9223372036854775808'),
          int.parse('9223372036854775807'),
        ],
      );

      expect(
        BrowserSearchHistoryJsonCodec.decode(
          BrowserSearchHistoryJsonCodec.encode([entry]),
        ),
        [entry],
      );
      expect(
        BrowserSearchHistoryJsonCodec.decode(
          '[{"q":"bad","did":[9223372036854775808]}]',
        ),
        isEmpty,
      );
      expect(
        BrowserSearchHistoryJsonCodec.decode(
          '[{"q":"bad","ntid":[-9223372036854775809]}]',
        ),
        isEmpty,
      );
    });

    test('falls back to an empty history for malformed or incompatible JSON',
        () {
      for (final json in [
        'A',
        '{"q":"1"}',
        '[{"query":"1"}]',
        '[{"q":"valid"},{"q":42}]',
        '[{"q":"valid","unexpected":true}]',
      ]) {
        expect(BrowserSearchHistoryJsonCodec.decode(json), isEmpty,
            reason: json);
      }
    });

    test('falls back to an empty history for invalid persisted enum codes', () {
      expect(
        BrowserSearchHistoryJsonCodec.decode(
          '[{"q":"valid"},{"q":"invalid","f":[8]}]',
        ),
        isEmpty,
      );
      expect(
        BrowserSearchHistoryJsonCodec.decode('[{"q":"invalid","s":[5]}]'),
        isEmpty,
      );
      expect(
        BrowserSearchHistoryJsonCodec.decode(
            '[{"q":"invalid","f":[2147483648]}]'),
        isEmpty,
      );
    });
  });
}
