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
 * SPDX-FileCopyrightText: Copyright (c) 2026 lukstbit <52494258+lukstbit@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from FilteredDeckOptionsViewModelTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Filtered Deck build outcome', () {
    test('begins with building state and captures the backend request', () {
      const current = FilteredDeckOptions(
        id: 42,
        name: 'Custom deck',
        allowEmpty: false,
        shouldReschedule: false,
        filter1State: SearchTermState(
          search: 'deck:current',
          limit: '7',
          index: 3,
        ),
      );

      final start = beginFilteredDeckBuild(current);

      expect(start.state.isBuildingBrowserSearch, isTrue);
      expect(start.request.id, 42);
      expect(start.request.name, 'Custom deck');
      expect(start.request.allowEmpty, isFalse);
      expect(start.request.reschedule, isFalse);
      expect(start.request.searchTerms.single.search, 'deck:current');
      expect(start.request.searchTerms.single.limit, 7);
      expect(start.request.searchTerms.single.orderIndex, 3);
      expect(start.state.name, current.name);
      expect(start.state.isBuildingAllowed, isFalse);
    });

    test('success emits DeckBuilt and leaves the result type to the host', () {
      final success = completeFilteredDeckBuildSuccessfully();

      expect(identical(success.effect, DeckBuilt.instance), isTrue);
      expect(success.state, isNull);
      expect(success.usesDefaultOperationResult, isFalse);
    });

    test(
      'failure stores the raw Exception and returns default operation result',
      () {
        final exception = FormatException('no cards');
        final latest = const FilteredDeckOptions(
          name: 'edited while pending',
          isBuildingBrowserSearch: true,
          browserQuery: 'latest query',
          filter1State: SearchTermState(search: 'changed query'),
        );

        final failure = completeFilteredDeckBuildWithFailure(
          current: latest,
          exception: exception,
        );

        final state = failure.state!;
        expect(identical(state.throwable, exception), isTrue);
        expect(state.isBuildingBrowserSearch, isFalse);
        expect(failure.usesDefaultOperationResult, isTrue);
        expect(state.name, 'edited while pending');
        expect(state.browserQuery, 'latest query');
        expect(state.filter1State.search, 'changed query');
      },
    );
  });
}
