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

  group('Filtered Deck Options ViewModel state transitions', () {
    test(
      'existing name, limit, and toggle projections expose dirty updates',
      () {
        const initial = FilteredDeckOptions(
          name: 'Filtered',
          filter1State: SearchTermState(limit: '5'),
        );
        final name = onDeckNameChangeTransition(
          current: initial,
          initial: initial,
          name: 'Renamed',
          deckNames: const [],
        );
        expect(name.state.name, 'Renamed');
        expect(name.hasUnsavedChanges, isTrue);
        expect(
          onDeckNameChangeTransition(
            current: initial,
            initial: initial,
            name: 'Filtered',
            deckNames: const [],
          ).hasUnsavedChanges,
          isNull,
        );

        final limit = onLimitChangeTransition(
          current: initial,
          initial: initial,
          index: FilterIndex.first,
          limit: '8',
        );
        expect(limit.state.filter1State.limit, '8');
        expect(limit.hasUnsavedChanges, isTrue);
        expect(
          onLimitChangeTransition(
            current: initial,
            initial: initial,
            index: FilterIndex.first,
            limit: '5',
          ).hasUnsavedChanges,
          isNull,
        );

        final toggled = onSecondFilterStatusChangeTransition(
          current: initial,
          initial: initial,
          isEnabled: true,
        );
        expect(toggled.state.isSecondFilterEnabled, isTrue);
        expect(toggled.hasUnsavedChanges, isTrue);
        expect(
          onSecondFilterStatusChangeTransition(
            current: initial,
            initial: initial,
            isEnabled: false,
          ).hasUnsavedChanges,
          isNull,
        );
      },
    );

    test('search changes recompute dirty status and same input is a no-op', () {
      const initial = FilteredDeckOptions();
      final changed = onSearchChange(
        current: initial,
        initial: initial,
        index: FilterIndex.first,
        searchQuery: 'tag:one',
      );
      expect(changed.state.filter1State.search, 'tag:one');
      expect(changed.hasUnsavedChanges, isTrue);

      final reverted = onSearchChange(
        current: changed.state,
        initial: initial,
        index: FilterIndex.first,
        searchQuery: '',
      );
      expect(reverted.hasUnsavedChanges, isFalse);
      final noOp = onSearchChange(
        current: reverted.state,
        initial: initial,
        index: FilterIndex.first,
        searchQuery: '',
      );
      expect(identical(noOp.state, reverted.state), isTrue);
      expect(noOp.hasUnsavedChanges, isNull);
    });

    test('card order changes recompute dirty status for both filters', () {
      const initial = FilteredDeckOptions(
        isSecondFilterEnabled: true,
        filter1State: SearchTermState(index: 1),
        filter2State: SearchTermState(index: 2),
      );
      final first = onCardsOptionsChange(
        current: initial,
        initial: initial,
        filterIndex: FilterIndex.first,
        cardOptionIndex: 3,
      );
      expect(first.state.filter1State.index, 3);
      expect(first.hasUnsavedChanges, isTrue);

      final second = onCardsOptionsChange(
        current: initial,
        initial: initial,
        filterIndex: FilterIndex.second,
        cardOptionIndex: 4,
      );
      expect(second.state.filter2State?.index, 4);
      expect(second.hasUnsavedChanges, isTrue);
      expect(
        onCardsOptionsChange(
          current: initial,
          initial: initial,
          filterIndex: FilterIndex.first,
          cardOptionIndex: 1,
        ).hasUnsavedChanges,
        isNull,
      );
    });

    test(
      'second filter null remains null while changed search recomputes dirty',
      () {
        const initial = FilteredDeckOptions(filter2State: null);
        final result = onSearchChange(
          current: initial,
          initial: initial,
          index: FilterIndex.second,
          searchQuery: 'tag:two',
        );
        expect(result.state.filter2State, isNull);
        expect(result.hasUnsavedChanges, isFalse);
        expect(
          filteredDeckOptionsWasStateModified(
            initial: initial,
            current: result.state,
          ),
          isFalse,
        );
      },
    );

    test(
      'dirty comparison ignores disabled filter two and unobserved fields',
      () {
        const initial = FilteredDeckOptions(
          filter2State: SearchTermState(search: 'old'),
        );
        const disabledChanged = FilteredDeckOptions(
          filter2State: SearchTermState(search: 'new'),
          allowEmpty: false,
          shouldReschedule: false,
          delayAgain: '9',
          delayHard: '8',
          delayGood: '7',
        );
        expect(
          filteredDeckOptionsWasStateModified(
            initial: initial,
            current: disabledChanged,
          ),
          isFalse,
        );

        final enabledChanged = disabledChanged.copyWith(
          isSecondFilterEnabled: true,
        );
        expect(
          filteredDeckOptionsWasStateModified(
            initial: initial.copyWith(isSecondFilterEnabled: true),
            current: enabledChanged,
          ),
          isTrue,
        );
        expect(
          filteredDeckOptionsWasStateModified(
            initial: null,
            current: enabledChanged,
          ),
          isFalse,
        );
        expect(
          filteredDeckOptionsWasStateModified(initial: initial, current: null),
          isFalse,
        );
      },
    );

    test(
      'reschedule, delays, and allow-empty leave dirty status untouched',
      () {
        const initial = FilteredDeckOptions();
        final reschedule = onRescheduleChange(
          current: initial,
          isEnabled: false,
        );
        expect(reschedule.state.shouldReschedule, isFalse);
        expect(reschedule.hasUnsavedChanges, isNull);
        expect(
          onRescheduleChange(
            current: initial,
            isEnabled: true,
          ).hasUnsavedChanges,
          isNull,
        );

        for (final delay in RescheduleDelay.values) {
          final changed = onRescheduleDelayChange(
            current: initial,
            target: delay,
            amount: '12',
          );
          expect(changed.hasUnsavedChanges, isNull);
          final same = onRescheduleDelayChange(
            current: initial,
            target: delay,
            amount: '0',
          );
          expect(identical(same.state, initial), isTrue);
          expect(same.hasUnsavedChanges, isNull);
        }

        final allowEmpty = onAllowEmptyChange(
          current: initial,
          isEnabled: false,
        );
        expect(allowEmpty.state.allowEmpty, isFalse);
        expect(allowEmpty.hasUnsavedChanges, isNull);
        expect(
          identical(
            onAllowEmptyChange(current: initial, isEnabled: true).state,
            initial,
          ),
          isTrue,
        );
      },
    );

    test(
      'clear actions clear only their value and never update dirty status',
      () {
        final current = FilteredDeckOptions(
          browserQuery: 'tag:one',
          throwable: StateError('bad search'),
        );
        final query = clearSearchInBrowser(current);
        expect(query.state.browserQuery, isNull);
        expect(query.state.throwable, isNotNull);
        expect(query.hasUnsavedChanges, isNull);

        final error = clearError(query.state);
        expect(error.state.throwable, isNull);
        expect(error.state.browserQuery, isNull);
        expect(error.hasUnsavedChanges, isNull);
      },
    );

    test(
      'restored baseline detects pending changes and accepts reverted state',
      () {
        const initial = FilteredDeckOptions(
          name: 'Saved',
          filter1State: SearchTermState(search: 'tag:saved'),
        );
        final restored = initial.copyWith(
          name: 'Pending',
          filter1State: const SearchTermState(search: 'tag:pending'),
        );
        expect(
          filteredDeckOptionsWasStateModified(
            initial: initial,
            current: restored,
          ),
          isTrue,
        );
        expect(
          filteredDeckOptionsWasStateModified(
            initial: initial,
            current: initial,
          ),
          isFalse,
        );
      },
    );
  });
}
