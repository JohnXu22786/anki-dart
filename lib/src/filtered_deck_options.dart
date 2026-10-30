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
 * Behavioral reference: FilteredDeckOptionsState.kt and
 * FilteredDeckOptionsViewModel.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'gesture_parser.dart';

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
