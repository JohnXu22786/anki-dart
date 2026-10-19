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
 * Behavioral reference: `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/
 * CardBrowserSearchViewModel.kt`; adjacent tests are
 * `AnkiDroid/src/test/java/com/ichi2/anki/browser/search/SearchFiltersTest.kt`
 * and `SearchRequestTest.kt`. Upstream has no direct updateSearchFlow test.
 * See ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser filter update projection', () {
    test('starts as an empty System update and does not initiate a search', () {
      final update = BrowserFilterUpdate.initial;

      expect(update, isA<BrowserFilterUpdateSystem>());
      expect(update.state, const BrowserSearchFilters());
      expect(
        browserSearchRequestFromFilterUpdate(
          text: 'query',
          update: update,
          isScreenOpen: false,
        ),
        isNull,
      );
    });

    test('closed-screen System updates do not initiate a search', () {
      const update = BrowserFilterUpdateSystem(
        BrowserSearchFilters(tags: ['synced']),
      );

      expect(
        browserSearchRequestFromFilterUpdate(
          text: 'query',
          update: update,
          isScreenOpen: false,
        ),
        isNull,
      );
    });

    test('an open screen suppresses both User and System updates', () {
      const updates = <BrowserFilterUpdate>[
        BrowserFilterUpdateUser(BrowserSearchFilters(tags: ['user'])),
        BrowserFilterUpdateSystem(BrowserSearchFilters(tags: ['system'])),
      ];

      for (final update in updates) {
        expect(
          browserSearchRequestFromFilterUpdate(
            text: 'query',
            update: update,
            isScreenOpen: true,
          ),
          isNull,
        );
      }
    });

    test('closed-screen User updates trim text and retain the supplied filters',
        () {
      const filters = BrowserSearchFilters(
        decks: [BrowserDeckNameId(name: 'Language', id: 7)],
        flags: [1, 4],
        tags: ['one', 'two'],
        noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: 3)],
        cardStateCodes: [0, 2, 4],
      );
      const update = BrowserFilterUpdateUser(filters);

      final request = browserSearchRequestFromFilterUpdate(
        text: '\u00a0\t query\u00a0 ',
        update: update,
        isScreenOpen: false,
      );

      expect(request, isNotNull);
      expect(request!.query, 'query');
      expect(request.filters, same(filters));
    });

    test('whitespace-only text remains blank and preserves every filter', () {
      const filters = BrowserSearchFilters(
        decks: [BrowserDeckNameId(name: 'Default', id: 1)],
        flags: [2],
        tags: ['tag'],
        noteTypes: [BrowserNoteTypeNameId(name: 'Cloze', id: 8)],
        cardStateCodes: [1, 3],
      );

      final request = browserSearchRequestFromFilterUpdate(
        text: '\u00a0\u2003\t',
        update: const BrowserFilterUpdateUser(filters),
        isScreenOpen: false,
      );

      expect(request, isNotNull);
      expect(request!.query, '');
      expect(request.filters, same(filters));
    });

    test('User and System retain source data-class value equality', () {
      final noteType = BrowserNoteTypeNameId(name: 'Basic', id: 3);
      final user = BrowserFilterUpdateUser(
        BrowserSearchFilters(
          decks: [BrowserDeckNameId(name: 'Default', id: 1)],
          flags: [1],
          tags: ['tag'],
          noteTypes: [noteType],
          cardStateCodes: [0],
        ),
      );
      final equalUser = BrowserFilterUpdateUser(
        BrowserSearchFilters(
          decks: [BrowserDeckNameId(name: 'Default', id: 1)],
          flags: [1],
          tags: ['tag'],
          noteTypes: [noteType],
          cardStateCodes: [0],
        ),
      );
      final system = BrowserFilterUpdateSystem(user.state);
      final equalSystem = BrowserFilterUpdateSystem(equalUser.state);

      expect(user, equalUser);
      expect(user.hashCode, equalUser.hashCode);
      expect(system, equalSystem);
      expect(system.hashCode, equalSystem.hashCode);
      expect(user, isNot(system));
      // Both Kotlin data classes hash only their shared `state` property.
      expect(user.hashCode, system.hashCode);
    });
  });
}
