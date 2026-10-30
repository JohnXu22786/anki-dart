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
 * Source-derived from FilteredDeckOptionsViewModelTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Filtered Deck Options name validation', () {
    test('blank and case-sensitive duplicate names set exact errors', () {
      const initial = FilteredDeckOptions(name: 'Filtered');

      final blank = onDeckNameChange(
        current: initial,
        name: '\u00a0\t',
        deckNames: const ['Existing'],
      );
      expect(blank.name, '\u00a0\t');
      expect(blank.nameInputError, FilteredNameInputError.empty);

      final duplicate = onDeckNameChange(
        current: initial,
        name: 'Existing',
        deckNames: const ['Existing'],
      );
      expect(duplicate.nameInputError, FilteredNameInputError.alreadyExists);

      final caseDifferent = onDeckNameChange(
        current: initial,
        name: 'existing',
        deckNames: const ['Existing'],
      );
      expect(caseDifferent.nameInputError, isNull);
    });

    test(
      'editing own title is allowed and unchanged input is a true no-op',
      () {
        const editing = FilteredDeckOptions(
          id: 24,
          name: 'Original',
          title: 'Original',
          nameInputError: FilteredNameInputError.alreadyExists,
        );
        final ownTitle = onDeckNameChange(
          current: editing,
          name: 'Original',
          deckNames: const ['Original'],
        );
        expect(identical(ownTitle, editing), isTrue);
        expect(ownTitle.nameInputError, FilteredNameInputError.alreadyExists);

        final changed = onDeckNameChange(
          current: editing,
          name: 'Renamed',
          deckNames: const ['Original'],
        );
        expect(changed.name, 'Renamed');
        expect(changed.nameInputError, isNull);
      },
    );
  });

  group('Filtered Deck Options limit validation', () {
    test('empty, invalid, and signed 32-bit limits follow Kotlin parsing', () {
      const initial = FilteredDeckOptions();
      SearchInputError? errorFor(String input) => onLimitChange(
        current: initial,
        index: FilterIndex.first,
        limit: input,
      ).filter1State.error;

      expect(errorFor(''), SearchInputError.empty);
      expect(errorFor('\u00a0'), SearchInputError.empty);
      expect(errorFor(' 1'), SearchInputError.notANumber);
      expect(errorFor('1 '), SearchInputError.notANumber);
      expect(errorFor('nope'), SearchInputError.notANumber);
      expect(errorFor('2147483648'), SearchInputError.notANumber);
      expect(errorFor('-2147483649'), SearchInputError.notANumber);
      expect(errorFor('2147483647'), isNull);
      expect(errorFor('-2147483648'), isNull);
      expect(errorFor('+1'), isNull);
      expect(errorFor('-1'), isNull);
      expect(errorFor('١'), isNull);
      expect(errorFor('0'), isNull);
    });

    test(
      'same limit string does not recalculate or clear an existing error',
      () {
        const state = FilteredDeckOptions(
          filter1State: SearchTermState(
            limit: '',
            error: SearchInputError.notANumber,
          ),
        );
        final result = onLimitChange(
          current: state,
          index: FilterIndex.first,
          limit: '',
        );
        expect(identical(result, state), isTrue);
        expect(result.filter1State.error, SearchInputError.notANumber);
      },
    );
  });

  group('Filtered Deck Options build eligibility and second filter', () {
    test(
      'eligibility gates build state, active filter errors, and name errors',
      () {
        expect(const FilteredDeckOptions().isBuildingAllowed, isTrue);
        expect(
          const FilteredDeckOptions(
            isBuildingBrowserSearch: true,
          ).isBuildingAllowed,
          isFalse,
        );
        expect(
          const FilteredDeckOptions(
            nameInputError: FilteredNameInputError.empty,
          ).isBuildingAllowed,
          isFalse,
        );
        expect(
          const FilteredDeckOptions(
            filter1State: SearchTermState(error: SearchInputError.empty),
          ).isBuildingAllowed,
          isFalse,
        );

        const filter2Error = SearchTermState(
          error: SearchInputError.notANumber,
        );
        expect(
          const FilteredDeckOptions(
            filter2State: filter2Error,
          ).isBuildingAllowed,
          isTrue,
        );
        expect(
          const FilteredDeckOptions(
            isSecondFilterEnabled: true,
            filter2State: filter2Error,
          ).isBuildingAllowed,
          isFalse,
        );
      },
    );

    test(
      'toggle preserves existing second-filter state and is a no-op if unchanged',
      () {
        const filter = SearchTermState(
          search: 'tag:keep',
          limit: 'bad',
          index: 3,
          error: SearchInputError.notANumber,
        );
        const enabled = FilteredDeckOptions(
          isSecondFilterEnabled: true,
          filter2State: filter,
        );
        final disabled = onSecondFilterStatusChange(
          current: enabled,
          isEnabled: false,
        );
        expect(disabled.isSecondFilterEnabled, isFalse);
        expect(disabled.filter2State, filter);
        expect(disabled.filter2State?.error, SearchInputError.notANumber);
        expect(
          identical(
            onSecondFilterStatusChange(current: disabled, isEnabled: false),
            disabled,
          ),
          isTrue,
        );
        expect(
          onSecondFilterStatusChange(
            current: disabled,
            isEnabled: true,
          ).filter2State,
          filter,
        );
      },
    );

    test('enabling a missing second filter creates a fresh default state', () {
      const disabled = FilteredDeckOptions(filter2State: null);
      final enabled = onSecondFilterStatusChange(
        current: disabled,
        isEnabled: true,
      );
      expect(enabled.filter2State, const SearchTermState());
      expect(identical(enabled.filter2State, disabled.filter2State), isFalse);
      expect(
        onSecondFilterStatusChange(current: disabled, isEnabled: true),
        enabled,
      );
    });

    test('modeled states have Kotlin data-class value equality', () {
      const first = FilteredDeckOptions(
        id: 7,
        name: 'Filtered',
        title: 'Title',
        filter1State: SearchTermState(search: 'tag:x', limit: '5', index: 2),
      );
      const equal = FilteredDeckOptions(
        id: 7,
        name: 'Filtered',
        title: 'Title',
        filter1State: SearchTermState(search: 'tag:x', limit: '5', index: 2),
      );
      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(
        const FilteredDeckOptions(cardOptions: ['due', 'random']),
        const FilteredDeckOptions(cardOptions: ['due', 'random']),
      );
      expect(
        const FilteredDeckOptions(cardOptions: ['due']),
        isNot(const FilteredDeckOptions(cardOptions: ['random'])),
      );
      expect(
        SearchTermState(search: 'tag:x', limit: '5', index: 2),
        SearchTermState(search: 'tag:x', limit: '5', index: 2),
      );
    });
  });
}
