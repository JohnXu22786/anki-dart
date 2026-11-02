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
 * Source-derived callback application cases for `syncState` and
 * `resetSearchState` in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Browser search state effect application', () {
    test('reset applies each source effect once and in order', () {
      final filters = BrowserSearchFilters(
        decks: [const BrowserDeckNameId(name: 'Languages', id: 7)],
        flags: [1],
        tags: ['tag'],
        cardStateCodes: [2],
      );
      final search = BrowserSearchRequest(
        query: '  raw\n query \r ',
        filters: filters,
      );
      final calls = <String>[];
      BrowserSearchFilters? updatedFilters;
      final basicValues = <String>[];
      final advancedValues = <String>[];
      final removedKeys = <String>[];

      browserResetSearchState(
        search,
        callbacks: BrowserResetSearchStateCallbacks(
          setAdvancedSearchMode: (enabled) => calls.add('mode:$enabled'),
          setBasicSearchText: (text) {
            calls.add('basic');
            basicValues.add(text);
          },
          setAdvancedSearchText: (text) {
            calls.add('advanced');
            advancedValues.add(text);
          },
          updateSystemFilters: (value) {
            calls.add('filters');
            updatedFilters = value;
          },
          setSearchScreenOpen: (isOpen) => calls.add('screen:$isOpen'),
          removeSavedStateKey: (key) {
            calls.add('remove:$key');
            removedKeys.add(key);
          },
        ),
      );

      expect(calls, [
        'mode:false',
        'basic',
        'advanced',
        'filters',
        'screen:false',
        'remove:advancedSearch',
        'remove:basicSearchText',
        'remove:advancedSearchText',
      ]);
      expect(calls, hasLength(8));
      expect(basicValues, [search.query]);
      expect(advancedValues, [search.query]);
      expect(identical(updatedFilters, filters), isTrue);
      expect(removedKeys, [
        browserAdvancedSearchStateKey,
        browserBasicSearchTextStateKey,
        browserAdvancedSearchTextStateKey,
      ]);
      expect(removedKeys, isNot(contains('historyExpanded')));
    });

    test('reset stops at the first callback error', () {
      final error = StateError('filter update failed');
      final calls = <String>[];

      expect(
        () => browserResetSearchState(
          const BrowserSearchRequest(query: 'query'),
          callbacks: BrowserResetSearchStateCallbacks(
            setAdvancedSearchMode: (_) => calls.add('mode'),
            setBasicSearchText: (_) => calls.add('basic'),
            setAdvancedSearchText: (_) => calls.add('advanced'),
            updateSystemFilters: (_) {
              calls.add('filters');
              throw error;
            },
            setSearchScreenOpen: (_) => calls.add('screen'),
            removeSavedStateKey: (_) => calls.add('remove'),
          ),
        ),
        throwsA(same(error)),
      );
      expect(calls, ['mode', 'basic', 'advanced', 'filters']);
    });

    test('sync awaits the exact System update before submitting the request',
        () async {
      final filters = BrowserSearchFilters(tags: ['sync-tag']);
      final request = BrowserSearchRequest(query: 'sync', filters: filters);
      final filterUpdateFinished = Completer<void>();
      final calls = <String>[];
      BrowserSearchFilters? updatedFilters;
      BrowserSearchRequest? submittedSearch;

      final application = browserSyncSearchState(
        request,
        callbacks: BrowserSyncSearchStateCallbacks(
          updateSystemFilters: (value) {
            calls.add('filters');
            updatedFilters = value;
            return filterUpdateFinished.future;
          },
          submitSearch: (value) async {
            calls.add('submit');
            submittedSearch = value;
          },
        ),
      );

      expect(calls, ['filters']);
      expect(calls, hasLength(1));
      expect(identical(updatedFilters, filters), isTrue);
      filterUpdateFinished.complete();
      await application;

      expect(calls, ['filters', 'submit']);
      expect(calls, hasLength(2));
      expect(identical(submittedSearch, request), isTrue);
    });

    test('sync stops before submission when filter update fails', () async {
      final error = StateError('filter update failed');
      final calls = <String>[];

      await expectLater(
        browserSyncSearchState(
          const BrowserSearchRequest(query: 'query'),
          callbacks: BrowserSyncSearchStateCallbacks(
            updateSystemFilters: (_) {
              calls.add('filters');
              return Future<void>.error(error);
            },
            submitSearch: (_) async => calls.add('submit'),
          ),
        ),
        throwsA(same(error)),
      );
      expect(calls, ['filters']);
    });
  });
}
