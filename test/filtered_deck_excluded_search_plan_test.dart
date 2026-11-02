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
 * Source-derived from FilteredDeckOptionsViewModel.kt in AnkiDroid 2.25.3;
 * `filteredSearchNode()` is marked `@NeedsTest` and has no direct pinned unit
 * test. See ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Filtered Deck excluded-card search plan', () {
    test('one manual filter collapses its OR group and stays exact', () {
      final plan = filteredDeckExcludedCardsSearchPlan(
        const FilteredDeckOptions(
          filter1State: SearchTermState(search: '  prop:due  '),
        ),
      );

      expect(plan.manualFilter, isA<FilteredDeckSearchQueryTermPlan>());
      expect(
        (plan.manualFilter as FilteredDeckSearchQueryTermPlan).search,
        '  prop:due  ',
      );
    });

    test('enabled second manual filter follows the first in an OR group', () {
      final plan = filteredDeckExcludedCardsSearchPlan(
        const FilteredDeckOptions(
          filter1State: SearchTermState(search: 'first '),
          isSecondFilterEnabled: true,
          filter2State: SearchTermState(search: ' second'),
        ),
      );

      final manual = plan.manualFilter as FilteredDeckSearchGroupPlan;
      expect(manual.joiner, FilteredDeckSearchJoiner.or);
      expect(
        manual.children.cast<FilteredDeckSearchQueryTermPlan>().map(
          (term) => term.search,
        ),
        ['first ', ' second'],
      );
    });

    test('disabled or absent second filter is excluded', () {
      for (final current in [
        const FilteredDeckOptions(
          filter1State: SearchTermState(search: 'one'),
          isSecondFilterEnabled: false,
          filter2State: SearchTermState(search: 'ignored'),
        ),
        const FilteredDeckOptions(
          filter1State: SearchTermState(search: 'one'),
          isSecondFilterEnabled: true,
          filter2State: null,
        ),
      ]) {
        final plan = filteredDeckExcludedCardsSearchPlan(current);
        expect(plan.manualFilter, isA<FilteredDeckSearchQueryTermPlan>());
        expect(
          (plan.manualFilter as FilteredDeckSearchQueryTermPlan).search,
          'one',
        );
      }
    });

    test('implicit OR nodes preserve suspended, buried, filtered order', () {
      final plan = filteredDeckExcludedCardsSearchPlan(
        const FilteredDeckOptions(),
      );

      final implicit = plan.implicitFilter as FilteredDeckSearchGroupPlan;
      expect(implicit.joiner, FilteredDeckSearchJoiner.or);
      expect(implicit.children[0], isA<FilteredDeckSearchCardStateTermPlan>());
      expect(
        (implicit.children[0] as FilteredDeckSearchCardStateTermPlan).state,
        FilteredDeckSearchCardState.suspended,
      );
      expect(implicit.children[1], isA<FilteredDeckSearchCardStateTermPlan>());
      expect(
        (implicit.children[1] as FilteredDeckSearchCardStateTermPlan).state,
        FilteredDeckSearchCardState.buried,
      );
      expect(
        implicit.children[2],
        const TypeMatcher<FilteredDeckSearchDeckTermPlan>(),
      );
      expect(
        (implicit.children[2] as FilteredDeckSearchDeckTermPlan).name,
        'filtered',
      );
    });

    test(
      'new deck uses only filtered; editing excludes its exact raw name',
      () {
        final newDeck = filteredDeckExcludedCardsSearchPlan(
          const FilteredDeckOptions(name: 'Raw name', id: null),
        );
        final newFiltered =
            (newDeck.implicitFilter as FilteredDeckSearchGroupPlan).children[2];
        expect(newFiltered, isA<FilteredDeckSearchDeckTermPlan>());
        expect(
          (newFiltered as FilteredDeckSearchDeckTermPlan).name,
          'filtered',
        );

        final editing = filteredDeckExcludedCardsSearchPlan(
          const FilteredDeckOptions(id: 7, name: '  Filter::Name  '),
        );
        final editNode =
            (editing.implicitFilter as FilteredDeckSearchGroupPlan).children[2]
                as FilteredDeckSearchGroupPlan;
        expect(editNode.joiner, FilteredDeckSearchJoiner.and);
        expect(editNode.children[0], isA<FilteredDeckSearchDeckTermPlan>());
        final negated = editNode.children[1] as FilteredDeckSearchNotTermPlan;
        expect(negated.child, isA<FilteredDeckSearchDeckTermPlan>());
        expect(
          (negated.child as FilteredDeckSearchDeckTermPlan).name,
          '  Filter::Name  ',
        );
      },
    );

    test('complete request ANDs manual and implicit filters', () {
      final plan = filteredDeckExcludedCardsSearchPlan(
        const FilteredDeckOptions(),
      );

      final root = plan.search as FilteredDeckSearchGroupPlan;
      expect(root.joiner, FilteredDeckSearchJoiner.and);
      expect(root.children, [plan.manualFilter, plan.implicitFilter]);
    });
  });

  group('Filtered Deck excluded-card search outcome', () {
    test('success stores the exact query and preserves throwable', () {
      final error = StateError('existing');
      final result = onShowExcludedCardsSuccess(
        current: FilteredDeckOptions(
          throwable: error,
          browserQuery: 'old query',
        ),
        browserQuery: '  exact query  ',
      );

      expect(result.browserQuery, '  exact query  ');
      expect(identical(result.throwable, error), isTrue);
    });

    test('failure stores the raw Exception and preserves browserQuery', () {
      final error = FormatException('backend failure');
      final result = onShowExcludedCardsFailure(
        current: FilteredDeckOptions(
          throwable: StateError('older error'),
          browserQuery: 'existing query',
        ),
        exception: error,
      );

      expect(result.throwable, isA<FormatException>());
      expect(identical(result.throwable, error), isTrue);
      expect(result.browserQuery, 'existing query');
    });
  });
}
