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
 * SPDX-FileCopyrightText: Copyright (c) 2025 lukstbit <52494258+lukstbit@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from FilteredDeckOptionsViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Filtered Deck backend input projection', () {
    test('projects IDs, names, defaults, options, and present filters', () {
      const data = FilteredDeckBackendData(
        id: 12,
        name: 'Filtered',
        allowEmpty: false,
        reschedule: false,
        previewAgainSecs: 45,
        previewHardSecs: 123,
        previewGoodSecs: 234,
        searchTerms: [
          FilteredDeckBackendSearchTerm(
            search: 'first',
            limit: 10,
            orderNumber: 2,
          ),
          FilteredDeckBackendSearchTerm(
            search: 'second',
            limit: 20,
            orderNumber: 3,
          ),
          FilteredDeckBackendSearchTerm(
            search: 'ignored third term',
            limit: 30,
            orderNumber: 4,
          ),
        ],
      );

      final state = filteredDeckOptionsFromBackendData(
        data: data,
        cardsOptions: const ['due', 'random'],
        defaultSearch1: '',
        defaultSearch2: 'override second',
      );

      expect(state.id, 12);
      expect(state.name, 'Filtered');
      expect(state.title, 'Filtered');
      expect(state.allowEmpty, isFalse);
      expect(state.shouldReschedule, isFalse);
      expect(state.cardOptions, ['due', 'random']);
      expect(state.delayAgain, '45');
      expect(state.delayHard, '123');
      expect(state.delayGood, '234');
      expect(
        state.filter1State,
        const SearchTermState(search: '', limit: '10', index: 2),
      );
      expect(state.isSecondFilterEnabled, isTrue);
      expect(
        state.filter2State,
        const SearchTermState(search: 'override second', limit: '20', index: 3),
      );
    });

    test(
      'uses backend searches for null overrides and preserves zero-ID rules',
      () {
        const data = FilteredDeckBackendData(
          id: 0,
          name: 'New filtered deck',
          allowEmpty: true,
          reschedule: true,
          previewAgainSecs: 60,
          previewHardSecs: 600,
          previewGoodSecs: 0,
          searchTerms: [
            FilteredDeckBackendSearchTerm(
              search: 'backend first',
              limit: 100,
              orderNumber: 0,
            ),
            FilteredDeckBackendSearchTerm(
              search: 'backend second',
              limit: 50,
              orderNumber: 1,
            ),
          ],
        );

        final state = filteredDeckOptionsFromBackendData(data: data);

        expect(state.id, isNull);
        expect(state.filter1State.search, 'backend first');
        expect(state.filter2State?.search, 'backend second');
        expect(state.isSecondFilterEnabled, isFalse);
        expect(
          filteredDeckOptionsFromBackendData(
            data: const FilteredDeckBackendData(
              id: 5,
              name: 'Only one',
              allowEmpty: true,
              reschedule: true,
              previewAgainSecs: 0,
              previewHardSecs: 0,
              previewGoodSecs: 0,
              searchTerms: [
                FilteredDeckBackendSearchTerm(
                  search: 'only',
                  limit: 1,
                  orderNumber: 9,
                ),
              ],
            ),
          ).filter2State,
          isNull,
        );
        expect(
          () => filteredDeckOptionsFromBackendData(
            data: const FilteredDeckBackendData(
              id: 1,
              name: 'Malformed',
              allowEmpty: true,
              reschedule: true,
              previewAgainSecs: 0,
              previewHardSecs: 0,
              previewGoodSecs: 0,
              searchTerms: [],
            ),
          ),
          throwsRangeError,
        );
      },
    );
  });

  group('Filtered Deck backend update request projection', () {
    test(
      'projects request fields, integer fallbacks, and second-filter gating',
      () {
        const state = FilteredDeckOptions(
          id: 31,
          name: 'Renamed',
          allowEmpty: false,
          shouldReschedule: false,
          delayAgain: 'bad',
          delayHard: '2147483648',
          delayGood: '-2147483648',
          filter1State: SearchTermState(
            search: 'exact first query',
            limit: '-2147483649',
            index: 97,
          ),
          filter2State: SearchTermState(
            search: 'exact second query',
            limit: '+17',
            index: -12,
          ),
          isSecondFilterEnabled: true,
        );

        final request = filteredDeckBackendUpdateRequest(state);

        expect(request.id, 31);
        expect(request.name, 'Renamed');
        expect(request.allowEmpty, isFalse);
        expect(request.reschedule, isFalse);
        expect(request.previewAgainSecs, 60);
        expect(request.previewHardSecs, 600);
        expect(request.previewGoodSecs, -2147483648);
        expect(request.searchTerms, hasLength(2));
        expect(request.searchTerms[0].search, 'exact first query');
        expect(request.searchTerms[0].limit, 0);
        expect(request.searchTerms[0].orderIndex, 97);
        expect(request.searchTerms[1].search, 'exact second query');
        expect(request.searchTerms[1].limit, 17);
        expect(request.searchTerms[1].orderIndex, -12);

        expect(
          filteredDeckBackendUpdateRequest(
            const FilteredDeckOptions(
              filter2State: SearchTermState(search: 'disabled'),
            ),
          ).searchTerms,
          hasLength(1),
        );
        expect(
          filteredDeckBackendUpdateRequest(
            const FilteredDeckOptions(
              isSecondFilterEnabled: true,
              filter2State: null,
            ),
          ).searchTerms,
          hasLength(1),
        );
      },
    );

    test(
      'uses Kotlin signed Unicode decimal parsing and keeps order adapter input',
      () {
        final request = filteredDeckBackendUpdateRequest(
          const FilteredDeckOptions(
            delayAgain: '١',
            delayHard: '+٢',
            delayGood: ' 3',
            filter1State: SearchTermState(
              search: 'unchanged',
              limit: '١٢',
              index: 2147483648,
            ),
          ),
        );

        expect(request.previewAgainSecs, 1);
        expect(request.previewHardSecs, 2);
        expect(request.previewGoodSecs, 0);
        expect(request.searchTerms.single.limit, 12);
        // The host resolves this through generated enum forNumber(index).
        expect(request.searchTerms.single.orderIndex, 2147483648);
        expect(
          filteredDeckBackendUpdateRequest(const FilteredDeckOptions()).id,
          0,
        );
      },
    );
  });
}
