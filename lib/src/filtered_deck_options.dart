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
 * Behavioral reference: FilteredDeckOptionsState.kt and
 * FilteredDeckOptionsViewModel.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'gesture_parser.dart';

/// Portable host-supplied data used to initialize filtered-deck options.
///
/// The host owns the collection query and generated backend model conversion.
class FilteredDeckBackendData {
  const FilteredDeckBackendData({
    required this.id,
    required this.name,
    required this.allowEmpty,
    required this.reschedule,
    required this.previewAgainSecs,
    required this.previewHardSecs,
    required this.previewGoodSecs,
    required this.searchTerms,
  });

  final int id;
  final String name;
  final bool allowEmpty;
  final bool reschedule;
  final int previewAgainSecs;
  final int previewHardSecs;
  final int previewGoodSecs;
  final List<FilteredDeckBackendSearchTerm> searchTerms;
}

/// One host-projected search term; [orderNumber] is the generated enum number.
class FilteredDeckBackendSearchTerm {
  const FilteredDeckBackendSearchTerm({
    required this.search,
    required this.limit,
    required this.orderNumber,
  });

  final String search;
  final int limit;
  final int orderNumber;
}

/// Request fields for the host's generated `FilteredDeckForUpdate` adapter.
///
/// [orderIndex] deliberately stays an integer adapter input. The host must
/// resolve it with its generated enum `forNumber` function; this portable
/// package does not define behavior for unknown enum numbers or serialize a
/// backend protobuf.
class FilteredDeckBackendUpdateRequest {
  const FilteredDeckBackendUpdateRequest({
    required this.id,
    required this.name,
    required this.allowEmpty,
    required this.reschedule,
    required this.previewAgainSecs,
    required this.previewHardSecs,
    required this.previewGoodSecs,
    required this.searchTerms,
  });

  final int id;
  final String name;
  final bool allowEmpty;
  final bool reschedule;
  final int previewAgainSecs;
  final int previewHardSecs;
  final int previewGoodSecs;
  final List<FilteredDeckBackendUpdateSearchTerm> searchTerms;
}

class FilteredDeckBackendUpdateSearchTerm {
  const FilteredDeckBackendUpdateSearchTerm({
    required this.search,
    required this.limit,
    required this.orderIndex,
  });

  final String search;
  final int limit;
  final int orderIndex;
}

/// Projects AnkiDroid `FilteredDeckForUpdate.asInitialState()`.
FilteredDeckOptions filteredDeckOptionsFromBackendData({
  required FilteredDeckBackendData data,
  List<String> cardsOptions = const [],
  String? defaultSearch1,
  String? defaultSearch2,
}) {
  // Indexing the first term directly preserves the source failure on malformed
  // host data with no search terms.
  final firstFilter = data.searchTerms[0];
  final secondFilter = data.searchTerms.length > 1 ? data.searchTerms[1] : null;
  return FilteredDeckOptions(
    id: data.id == 0 ? null : data.id,
    name: data.name,
    title: data.name,
    shouldReschedule: data.reschedule,
    allowEmpty: data.allowEmpty,
    cardOptions: cardsOptions,
    filter1State: SearchTermState(
      search: defaultSearch1 ?? firstFilter.search,
      limit: firstFilter.limit.toString(),
      index: firstFilter.orderNumber,
    ),
    isSecondFilterEnabled: secondFilter != null && data.id != 0,
    filter2State: secondFilter == null
        ? null
        : SearchTermState(
            search: defaultSearch2 ?? secondFilter.search,
            limit: secondFilter.limit.toString(),
            index: secondFilter.orderNumber,
          ),
    delayAgain: data.previewAgainSecs.toString(),
    delayHard: data.previewHardSecs.toString(),
    delayGood: data.previewGoodSecs.toString(),
  );
}

/// Projects AnkiDroid `FilteredDeckOptions.asBackendData()` into adapter input.
FilteredDeckBackendUpdateRequest filteredDeckBackendUpdateRequest(
  FilteredDeckOptions state,
) {
  final secondFilter = state.filter2State;
  return FilteredDeckBackendUpdateRequest(
    id: state.id ?? 0,
    name: state.name,
    allowEmpty: state.allowEmpty,
    reschedule: state.shouldReschedule,
    previewAgainSecs: parseKotlinInt32(state.delayAgain) ?? 60,
    previewHardSecs: parseKotlinInt32(state.delayHard) ?? 600,
    previewGoodSecs: parseKotlinInt32(state.delayGood) ?? 0,
    searchTerms: [
      FilteredDeckBackendUpdateSearchTerm(
        search: state.filter1State.search,
        limit: parseKotlinInt32(state.filter1State.limit) ?? 0,
        orderIndex: state.filter1State.index,
      ),
      if (state.isSecondFilterEnabled && secondFilter != null)
        FilteredDeckBackendUpdateSearchTerm(
          search: secondFilter.search,
          limit: parseKotlinInt32(secondFilter.limit) ?? 0,
          orderIndex: secondFilter.index,
        ),
    ],
  );
}

/// State for a filtered-deck search term and its form validation result.
class SearchTermState {
  const SearchTermState({
    this.search = '',
    this.limit = '100',
    this.index = 0,
    this.error,
  });

  final String search;
  final String limit;
  final int index;
  final SearchInputError? error;

  @override
  bool operator ==(Object other) =>
      other is SearchTermState &&
      other.search == search &&
      other.limit == limit &&
      other.index == index &&
      other.error == error;

  @override
  int get hashCode => Object.hash(search, limit, index, error);
}

enum SearchInputError { empty, notANumber }

enum FilteredNameInputError { empty, alreadyExists }

enum FilterIndex { first, second }

/// Search input passed to the host's backend query builder for browser preview.
///
/// The host runs `safeBuildSearchString` and supplies the resulting success or
/// failure; this package does not parse or validate search syntax.
class FilteredDeckBrowserSearchRequest {
  const FilteredDeckBrowserSearchRequest(this.search);

  final String search;
}

/// The portable form of AnkiDroid's `InvalidSearchException` wrapper.
///
/// [cause] is the host's original backend exception, and [message] is its
/// localized message as supplied by the host.
class FilteredDeckInvalidSearchException implements Exception {
  const FilteredDeckInvalidSearchException({
    required this.cause,
    required this.message,
  });

  final Object cause;
  final String? message;
}

/// Projects `FilteredDeckOptionsViewModel.onSearchInBrowser()` input.
///
/// A missing second filter makes the source method return without starting
/// backend work.
FilteredDeckBrowserSearchRequest? filteredDeckBrowserSearchRequest({
  required FilteredDeckOptions current,
  required FilterIndex index,
}) {
  final filter = _filterState(current, index);
  return filter == null
      ? null
      : FilteredDeckBrowserSearchRequest(filter.search);
}

/// Projects a successful host `safeBuildSearchString()` result.
FilteredDeckOptions onSearchInBrowserSuccess({
  required FilteredDeckOptions current,
  required String browserQuery,
}) => current.copyWith(browserQuery: browserQuery);

/// Projects a failed host `safeBuildSearchString()` result.
FilteredDeckOptions onSearchInBrowserFailure({
  required FilteredDeckOptions current,
  required Object cause,
  required String? localizedMessage,
}) => current.copyWith(
  throwable: FilteredDeckInvalidSearchException(
    cause: cause,
    message: localizedMessage,
  ),
);

enum RescheduleDelay { again, hard, good }

/// Result of one source ViewModel state action.
///
/// A null [hasUnsavedChanges] means the Kotlin action does not update the dirty
/// status. Otherwise it is the value produced by `wasStateModified()`.
class FilteredDeckOptionsTransition {
  const FilteredDeckOptionsTransition({
    required this.state,
    this.hasUnsavedChanges,
  });

  final FilteredDeckOptions state;
  final bool? hasUnsavedChanges;
}

/// Portable state used by the Filtered Deck Options form.
///
/// Collection-backed setup, query execution, deck building, and Android state
/// delivery remain with the host application.
class FilteredDeckOptions {
  const FilteredDeckOptions({
    this.id,
    this.name = '',
    this.nameInputError,
    this.title = '',
    this.shouldReschedule = true,
    this.allowEmpty = true,
    this.cardOptions = const [],
    this.filter1State = const SearchTermState(),
    this.isSecondFilterEnabled = false,
    this.filter2State = const SearchTermState(),
    this.delayAgain = '0',
    this.delayHard = '0',
    this.delayGood = '0',
    this.isBuildingBrowserSearch = false,
    this.throwable,
    this.browserQuery,
  });

  final int? id;
  final String name;
  final FilteredNameInputError? nameInputError;
  final String title;
  final bool shouldReschedule;
  final bool allowEmpty;
  final List<String> cardOptions;
  final SearchTermState filter1State;
  final bool isSecondFilterEnabled;
  final SearchTermState? filter2State;
  final String delayAgain;
  final String delayHard;
  final String delayGood;
  final bool isBuildingBrowserSearch;
  final Object? throwable;
  final String? browserQuery;

  /// True when no build is running and all currently visible input is valid.
  bool get isBuildingAllowed =>
      !isBuildingBrowserSearch &&
      nameInputError == null &&
      filter1State.error == null &&
      !(isSecondFilterEnabled && filter2State?.error != null);

  FilteredDeckOptions copyWith({
    int? id,
    bool clearId = false,
    String? name,
    FilteredNameInputError? nameInputError,
    bool clearNameInputError = false,
    String? title,
    bool? shouldReschedule,
    bool? allowEmpty,
    List<String>? cardOptions,
    SearchTermState? filter1State,
    bool? isSecondFilterEnabled,
    SearchTermState? filter2State,
    bool clearFilter2State = false,
    String? delayAgain,
    String? delayHard,
    String? delayGood,
    bool? isBuildingBrowserSearch,
    Object? throwable,
    bool clearThrowable = false,
    String? browserQuery,
    bool clearBrowserQuery = false,
  }) => FilteredDeckOptions(
    id: clearId ? null : id ?? this.id,
    name: name ?? this.name,
    nameInputError: clearNameInputError
        ? null
        : nameInputError ?? this.nameInputError,
    title: title ?? this.title,
    shouldReschedule: shouldReschedule ?? this.shouldReschedule,
    allowEmpty: allowEmpty ?? this.allowEmpty,
    cardOptions: cardOptions ?? this.cardOptions,
    filter1State: filter1State ?? this.filter1State,
    isSecondFilterEnabled: isSecondFilterEnabled ?? this.isSecondFilterEnabled,
    filter2State: clearFilter2State ? null : filter2State ?? this.filter2State,
    delayAgain: delayAgain ?? this.delayAgain,
    delayHard: delayHard ?? this.delayHard,
    delayGood: delayGood ?? this.delayGood,
    isBuildingBrowserSearch:
        isBuildingBrowserSearch ?? this.isBuildingBrowserSearch,
    throwable: clearThrowable ? null : throwable ?? this.throwable,
    browserQuery: clearBrowserQuery ? null : browserQuery ?? this.browserQuery,
  );

  @override
  bool operator ==(Object other) =>
      other is FilteredDeckOptions &&
      other.id == id &&
      other.name == name &&
      other.nameInputError == nameInputError &&
      other.title == title &&
      other.shouldReschedule == shouldReschedule &&
      other.allowEmpty == allowEmpty &&
      _listEquals(other.cardOptions, cardOptions) &&
      other.filter1State == filter1State &&
      other.isSecondFilterEnabled == isSecondFilterEnabled &&
      other.filter2State == filter2State &&
      other.delayAgain == delayAgain &&
      other.delayHard == delayHard &&
      other.delayGood == delayGood &&
      other.isBuildingBrowserSearch == isBuildingBrowserSearch &&
      other.throwable == throwable &&
      other.browserQuery == browserQuery;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    nameInputError,
    title,
    shouldReschedule,
    allowEmpty,
    Object.hashAll(cardOptions),
    filter1State,
    isSecondFilterEnabled,
    filter2State,
    delayAgain,
    delayHard,
    delayGood,
    isBuildingBrowserSearch,
    throwable,
    browserQuery,
  );
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Projects `FilteredDeckOptionsViewModel.onDeckNameChange()`.
FilteredDeckOptions onDeckNameChange({
  required FilteredDeckOptions current,
  required String name,
  required List<String> deckNames,
}) {
  final error = switch (true) {
    _ when _isKotlinBlank(name) => FilteredNameInputError.empty,
    _ when current.id != null && name == current.title => null,
    _ when deckNames.contains(name) => FilteredNameInputError.alreadyExists,
    _ => null,
  };
  if (current.name == name) return current;
  return current.copyWith(
    name: name,
    nameInputError: error,
    clearNameInputError: error == null,
  );
}

/// Projects `FilteredDeckOptionsViewModel.onLimitChange()`.
FilteredDeckOptions onLimitChange({
  required FilteredDeckOptions current,
  required FilterIndex index,
  required String limit,
}) {
  final error = switch (true) {
    _ when _isKotlinBlank(limit) => SearchInputError.empty,
    _ when !_isKotlinInt(limit) => SearchInputError.notANumber,
    _ => null,
  };
  final filter = switch (index) {
    FilterIndex.first => current.filter1State,
    FilterIndex.second => current.filter2State,
  };
  if (limit == filter?.limit) return current;

  final updatedFilter = filter == null
      ? null
      : SearchTermState(
          search: filter.search,
          limit: limit,
          index: filter.index,
          error: error,
        );
  return switch (index) {
    FilterIndex.first => current.copyWith(filter1State: updatedFilter!),
    FilterIndex.second =>
      updatedFilter == null
          ? current.copyWith(clearFilter2State: true)
          : current.copyWith(filter2State: updatedFilter),
  };
}

/// Projects `FilteredDeckOptionsViewModel.onSecondFilterStatusChange()`.
FilteredDeckOptions onSecondFilterStatusChange({
  required FilteredDeckOptions current,
  required bool isEnabled,
}) {
  if (current.isSecondFilterEnabled == isEnabled) return current;
  return current.copyWith(
    isSecondFilterEnabled: isEnabled,
    filter2State: current.filter2State ?? const SearchTermState(),
  );
}

/// Adds the source dirty-status update to [onDeckNameChange] without changing
/// its existing state-only projection.
FilteredDeckOptionsTransition onDeckNameChangeTransition({
  required FilteredDeckOptions current,
  required FilteredDeckOptions initial,
  required String name,
  required List<String> deckNames,
}) {
  final state = onDeckNameChange(
    current: current,
    name: name,
    deckNames: deckNames,
  );
  return identical(state, current)
      ? FilteredDeckOptionsTransition(state: current)
      : _withDirtyStatus(state, initial);
}

/// Adds the source dirty-status update to [onLimitChange] without changing its
/// existing state-only projection.
FilteredDeckOptionsTransition onLimitChangeTransition({
  required FilteredDeckOptions current,
  required FilteredDeckOptions initial,
  required FilterIndex index,
  required String limit,
}) {
  final state = onLimitChange(current: current, index: index, limit: limit);
  return identical(state, current)
      ? FilteredDeckOptionsTransition(state: current)
      : _withDirtyStatus(state, initial);
}

/// Adds the source dirty-status update to [onSecondFilterStatusChange] without
/// changing its existing state-only projection.
FilteredDeckOptionsTransition onSecondFilterStatusChangeTransition({
  required FilteredDeckOptions current,
  required FilteredDeckOptions initial,
  required bool isEnabled,
}) {
  final state = onSecondFilterStatusChange(
    current: current,
    isEnabled: isEnabled,
  );
  return identical(state, current)
      ? FilteredDeckOptionsTransition(state: current)
      : _withDirtyStatus(state, initial);
}

/// Projects `FilteredDeckOptionsViewModel.onSearchChange()` and its dirty update.
FilteredDeckOptionsTransition onSearchChange({
  required FilteredDeckOptions current,
  required FilteredDeckOptions initial,
  required FilterIndex index,
  required String searchQuery,
}) {
  final filter = _filterState(current, index);
  if (filter?.search == searchQuery) {
    return FilteredDeckOptionsTransition(state: current);
  }
  final updated = filter == null
      ? null
      : SearchTermState(
          search: searchQuery,
          limit: filter.limit,
          index: filter.index,
          error: filter.error,
        );
  final state = switch (index) {
    FilterIndex.first => current.copyWith(filter1State: updated!),
    FilterIndex.second =>
      updated == null
          ? current.copyWith(clearFilter2State: true)
          : current.copyWith(filter2State: updated),
  };
  return _withDirtyStatus(state, initial);
}

/// Projects `FilteredDeckOptionsViewModel.onCardsOptionsChange()`.
FilteredDeckOptionsTransition onCardsOptionsChange({
  required FilteredDeckOptions current,
  required FilteredDeckOptions initial,
  required FilterIndex filterIndex,
  required int cardOptionIndex,
}) {
  final filter = _filterState(current, filterIndex);
  if (filter?.index == cardOptionIndex) {
    return FilteredDeckOptionsTransition(state: current);
  }
  final updated = filter == null
      ? null
      : SearchTermState(
          search: filter.search,
          limit: filter.limit,
          index: cardOptionIndex,
          error: filter.error,
        );
  final state = switch (filterIndex) {
    FilterIndex.first => current.copyWith(filter1State: updated!),
    FilterIndex.second =>
      updated == null
          ? current.copyWith(clearFilter2State: true)
          : current.copyWith(filter2State: updated),
  };
  return _withDirtyStatus(state, initial);
}

/// Projects `FilteredDeckOptionsViewModel.onRescheduleChange()`.
FilteredDeckOptionsTransition onRescheduleChange({
  required FilteredDeckOptions current,
  required bool isEnabled,
}) {
  if (current.shouldReschedule == isEnabled) {
    return FilteredDeckOptionsTransition(state: current);
  }
  return FilteredDeckOptionsTransition(
    state: current.copyWith(shouldReschedule: isEnabled),
  );
}

/// Projects `FilteredDeckOptionsViewModel.onRescheduleDelayChange()`.
FilteredDeckOptionsTransition onRescheduleDelayChange({
  required FilteredDeckOptions current,
  required RescheduleDelay target,
  required String amount,
}) {
  final currentAmount = switch (target) {
    RescheduleDelay.again => current.delayAgain,
    RescheduleDelay.hard => current.delayHard,
    RescheduleDelay.good => current.delayGood,
  };
  if (amount == currentAmount) {
    return FilteredDeckOptionsTransition(state: current);
  }
  final state = switch (target) {
    RescheduleDelay.again => current.copyWith(delayAgain: amount),
    RescheduleDelay.hard => current.copyWith(delayHard: amount),
    RescheduleDelay.good => current.copyWith(delayGood: amount),
  };
  return FilteredDeckOptionsTransition(state: state);
}

/// Projects `FilteredDeckOptionsViewModel.onAllowEmptyChange()`.
FilteredDeckOptionsTransition onAllowEmptyChange({
  required FilteredDeckOptions current,
  required bool isEnabled,
}) {
  if (current.allowEmpty == isEnabled) {
    return FilteredDeckOptionsTransition(state: current);
  }
  return FilteredDeckOptionsTransition(
    state: current.copyWith(allowEmpty: isEnabled),
  );
}

/// Projects `FilteredDeckOptionsViewModel.clearSearchInBrowser()`.
FilteredDeckOptionsTransition clearSearchInBrowser(
  FilteredDeckOptions current,
) => FilteredDeckOptionsTransition(
  state: current.copyWith(clearBrowserQuery: true),
);

/// Projects `FilteredDeckOptionsViewModel.clearError()`.
FilteredDeckOptionsTransition clearError(FilteredDeckOptions current) =>
    FilteredDeckOptionsTransition(
      state: current.copyWith(clearThrowable: true),
    );

/// Projects the source's `wasStateModified()` comparison.
bool filteredDeckOptionsWasStateModified({
  required FilteredDeckOptions? initial,
  required FilteredDeckOptions? current,
}) {
  if (initial == null || current == null) return false;
  return initial.name != current.name ||
      _filterWasChanged(initial.filter1State, current.filter1State) ||
      initial.isSecondFilterEnabled != current.isSecondFilterEnabled ||
      _filter2WasChanged(initial, current);
}

FilteredDeckOptionsTransition _withDirtyStatus(
  FilteredDeckOptions state,
  FilteredDeckOptions initial,
) => FilteredDeckOptionsTransition(
  state: state,
  hasUnsavedChanges: filteredDeckOptionsWasStateModified(
    initial: initial,
    current: state,
  ),
);

SearchTermState? _filterState(FilteredDeckOptions state, FilterIndex index) =>
    switch (index) {
      FilterIndex.first => state.filter1State,
      FilterIndex.second => state.filter2State,
    };

bool _filterWasChanged(SearchTermState initial, SearchTermState current) =>
    initial.search != current.search ||
    initial.limit != current.limit ||
    initial.index != current.index;

bool _filter2WasChanged(
  FilteredDeckOptions initial,
  FilteredDeckOptions current,
) {
  if (!initial.isSecondFilterEnabled || !current.isSecondFilterEnabled) {
    return false;
  }
  return initial.filter2State?.search != current.filter2State?.search ||
      initial.filter2State?.limit != current.filter2State?.limit ||
      initial.filter2State?.index != current.filter2State?.index;
}

bool _isKotlinBlank(String value) => value.runes.every(_isKotlinWhitespace);

bool _isKotlinWhitespace(int codePoint) =>
    (codePoint >= 0x0009 && codePoint <= 0x000d) ||
    (codePoint >= 0x001c && codePoint <= 0x001f) ||
    const {
      0x0020,
      0x00a0,
      0x1680,
      0x2000,
      0x2001,
      0x2002,
      0x2003,
      0x2004,
      0x2005,
      0x2006,
      0x2007,
      0x2008,
      0x2009,
      0x200a,
      0x2028,
      0x2029,
      0x202f,
      0x205f,
      0x3000,
    }.contains(codePoint);

bool _isKotlinInt(String value) => parseKotlinInt32(value) != null;
