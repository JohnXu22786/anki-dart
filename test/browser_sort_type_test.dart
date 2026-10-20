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
 * Behavioral reference: SortType.kt and SortTypeTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser sort type', () {
    test('defaults to noteFld in cards and notes modes', () {
      final cards = resolveBrowserSortType(
        noSorting: false,
        config: const {},
        configKeys: const BrowserSortConfigKeys(
          columnKey: 'cards.column',
          reverseKey: 'cards.reverse',
        ),
        availableColumnKeys: const {'noteFld'},
      );
      final notes = resolveBrowserSortType(
        noSorting: false,
        config: const {},
        configKeys: const BrowserSortConfigKeys(
          columnKey: 'notes.column',
          reverseKey: 'notes.reverse',
        ),
        availableColumnKeys: const {'noteFld'},
      );

      expect(
        cards,
        const BrowserSortCollectionOrdering(key: 'noteFld', reverse: false),
      );
      expect(
        notes,
        const BrowserSortCollectionOrdering(key: 'noteFld', reverse: false),
      );
    });

    test('wrong-typed config values use the source defaults', () {
      expect(
        resolveBrowserSortType(
          noSorting: false,
          config: const {'cards.column': 42, 'cards.reverse': 'yes'},
          configKeys: const BrowserSortConfigKeys(
            columnKey: 'cards.column',
            reverseKey: 'cards.reverse',
          ),
          availableColumnKeys: const {'noteFld'},
        ),
        const BrowserSortCollectionOrdering(key: 'noteFld', reverse: false),
      );
    });

    test('reads the supplied mode-specific key and direction', () {
      const config = {
        'cards.column': 'deck',
        'cards.reverse': true,
        'notes.column': 'noteTags',
        'notes.reverse': false,
      };

      expect(
        resolveBrowserSortType(
          noSorting: false,
          config: config,
          configKeys: const BrowserSortConfigKeys(
            columnKey: 'cards.column',
            reverseKey: 'cards.reverse',
          ),
          availableColumnKeys: const {'deck', 'noteTags'},
        ),
        const BrowserSortCollectionOrdering(key: 'deck', reverse: true),
      );
      expect(
        resolveBrowserSortType(
          noSorting: false,
          config: config,
          configKeys: const BrowserSortConfigKeys(
            columnKey: 'notes.column',
            reverseKey: 'notes.reverse',
          ),
          availableColumnKeys: const {'deck', 'noteTags'},
        ),
        const BrowserSortCollectionOrdering(key: 'noteTags', reverse: false),
      );
    });

    test('the global no-sorting flag short-circuits config and maps sort order',
        () {
      expect(
        resolveBrowserSortType(
          noSorting: true,
          config: const {'cards.column': 'unknown', 'cards.reverse': true},
          configKeys: const BrowserSortConfigKeys(
            columnKey: 'cards.column',
            reverseKey: 'cards.reverse',
          ),
          availableColumnKeys: const {},
        ),
        isA<BrowserSortNoOrdering>(),
      );
      expect(browserSortOrder(noSorting: true), BrowserSortOrder.noOrdering);
      expect(
        browserSortOrder(noSorting: false),
        BrowserSortOrder.useCollectionOrdering,
      );
    });

    test('an unknown saved column falls back to no ordering', () {
      expect(
        resolveBrowserSortType(
          noSorting: false,
          config: const {'cards.column': 'corrupt', 'cards.reverse': true},
          configKeys: const BrowserSortConfigKeys(
            columnKey: 'cards.column',
            reverseKey: 'cards.reverse',
          ),
          availableColumnKeys: const {'noteFld'},
        ),
        isA<BrowserSortNoOrdering>(),
      );
      // SortType.buildSortOrder() still follows only the shared preference.
      expect(
        browserSortOrder(noSorting: false),
        BrowserSortOrder.useCollectionOrdering,
      );
    });

    test('saving collection ordering writes mode keys before clearing no-sort',
        () {
      final plan = buildBrowserSortSavePlan(
        sortType: const BrowserSortCollectionOrdering(
          key: 'noteTags',
          reverse: true,
        ),
        configKeys: const BrowserSortConfigKeys(
          columnKey: 'notes.column',
          reverseKey: 'notes.reverse',
        ),
      );

      expect(plan.cardBrowserNoSorting, isFalse);
      expect(
        plan.collectionConfigWrites,
        const [
          BrowserSortConfigWrite(key: 'notes.column', value: 'noteTags'),
          BrowserSortConfigWrite(
            key: 'notes.reverse',
            value: true,
          ),
        ],
      );

      final cardsPlan = buildBrowserSortSavePlan(
        sortType: const BrowserSortCollectionOrdering(
          key: 'deck',
          reverse: false,
        ),
        configKeys: const BrowserSortConfigKeys(
          columnKey: 'cards.column',
          reverseKey: 'cards.reverse',
        ),
      );
      expect(cardsPlan.cardBrowserNoSorting, isFalse);
      expect(
        cardsPlan.collectionConfigWrites,
        const [
          BrowserSortConfigWrite(key: 'cards.column', value: 'deck'),
          BrowserSortConfigWrite(key: 'cards.reverse', value: false),
        ],
      );
    });

    test('saving no ordering only sets the shared no-sort flag', () {
      const plan = BrowserSortSavePlan.noOrdering();
      expect(plan.cardBrowserNoSorting, isTrue);
      expect(plan.collectionConfigWrites, isEmpty);

      // The source's no-sort preference is shared across modes, despite the
      // ignored upstream test describing the intended future behavior.
      expect(
        resolveBrowserSortType(
          noSorting: plan.cardBrowserNoSorting,
          config: const {
            'cards.column': 'deck',
            'cards.reverse': false,
          },
          configKeys: const BrowserSortConfigKeys(
            columnKey: 'cards.column',
            reverseKey: 'cards.reverse',
          ),
          availableColumnKeys: const {'deck'},
        ),
        isA<BrowserSortNoOrdering>(),
      );
    });
  });
}
