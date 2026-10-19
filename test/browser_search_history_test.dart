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
 * Behavioral reference: SearchHistory.kt and SearchHistoryTest.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
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
}
