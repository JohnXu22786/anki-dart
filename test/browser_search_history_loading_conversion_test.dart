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
 * Behavioral reference: CardBrowserSearchViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser search-history Loading conversion', () {
    test('maps source order and entry identity with one conversion each', () {
      final entries = [
        BrowserSearchHistoryEntry(query: 'first'),
        BrowserSearchHistoryEntry(query: 'second'),
        BrowserSearchHistoryEntry(query: 'third'),
      ];
      final conversionOrder = <BrowserSearchHistoryEntry>[];
      final loading = BrowserSearchHistoryLoading(entries);

      final loaded = convertBrowserSearchHistoryLoading(loading, (entry) {
        conversionOrder.add(entry);
        return switch (entry.query) {
          'first' => null,
          'second' => '',
          'third' => 'converted third',
          _ => fail('Unexpected entry ${entry.query}'),
        };
      });

      expect(loaded, isA<BrowserSearchHistoryLoaded>());
      expect(conversionOrder, hasLength(entries.length));
      for (var index = 0; index < entries.length; index++) {
        expect(conversionOrder[index], same(entries[index]));
        expect(loaded.entryToSearchString[index].entry, same(entries[index]));
      }
      expect(loaded.entryToSearchString.map((pair) => pair.searchString), [
        null,
        '',
        'converted third',
      ]);
    });

    test('empty input returns an empty Loaded value without conversion', () {
      var conversionCount = 0;

      final loaded = convertBrowserSearchHistoryLoading(
        BrowserSearchHistoryLoading([]),
        (_) {
          conversionCount++;
          return 'unexpected';
        },
      );

      expect(loaded.entryToSearchString, isEmpty);
      expect(conversionCount, 0);
    });

    test('conversion failure propagates and stops later entries', () {
      final entries = [
        BrowserSearchHistoryEntry(query: 'first'),
        BrowserSearchHistoryEntry(query: 'fails'),
        BrowserSearchHistoryEntry(query: 'later'),
      ];
      final conversionOrder = <BrowserSearchHistoryEntry>[];
      final failure = StateError('conversion failed');

      expect(
        () => convertBrowserSearchHistoryLoading(
          BrowserSearchHistoryLoading(entries),
          (entry) {
            conversionOrder.add(entry);
            if (identical(entry, entries[1])) throw failure;
            return entry.query;
          },
        ),
        throwsA(same(failure)),
      );

      expect(conversionOrder, hasLength(2));
      expect(conversionOrder[0], same(entries[0]));
      expect(conversionOrder[1], same(entries[1]));
    });
  });
}
