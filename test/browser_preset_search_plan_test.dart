/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived cases for CardBrowserViewModel.searchForMarkedNotes(),
 * searchForSuspendedCards(), and setFilterQuery(); see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserPresetSearch', () {
    test('selected rows suppress both preset searches without effects', () {
      const currentRequest = BrowserSearchRequest(query: 'keep');

      for (final preset in BrowserPresetSearch.values) {
        expect(
          planBrowserPresetSearch(
            preset: preset,
            hasSelectedRows: true,
            currentRequest: currentRequest,
          ),
          isNull,
        );
      }
    });

    test('marked search emits its query before copying and requesting search', () {
      final currentFilters = BrowserSearchFilters(
        decks: [const BrowserDeckNameId(name: 'Languages', id: 7)],
        flags: [1, 4],
        tags: ['keep tag'],
        noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: 3)],
        cardStateCodes: [0, 2],
      );
      final currentRequest = BrowserSearchRequest(
        query: 'old query',
        filters: currentFilters,
      );

      final plan = planBrowserPresetSearch(
        preset: BrowserPresetSearch.markedNotes,
        hasSelectedRows: false,
        currentRequest: currentRequest,
      )!;

      _expectPresetSearch(plan, currentRequest, 'tag:marked');
    });

    test(
      'suspended search emits its query before copying and requesting search',
      () {
        final currentFilters = BrowserSearchFilters(
          decks: [const BrowserDeckNameId(name: 'Languages', id: 7)],
          flags: [1, 4],
          tags: ['keep tag'],
          noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: 3)],
          cardStateCodes: [0, 2],
        );
        final currentRequest = BrowserSearchRequest(
          query: 'old query',
          filters: currentFilters,
        );

        final plan = planBrowserPresetSearch(
          preset: BrowserPresetSearch.suspendedCards,
          hasSelectedRows: false,
          currentRequest: currentRequest,
        )!;

        _expectPresetSearch(plan, currentRequest, 'is:suspended');
      },
    );
  });
}

void _expectPresetSearch(
  BrowserPresetSearchPlan plan,
  BrowserSearchRequest currentRequest,
  String query,
) {
  expect(plan.query, query);
  expect(plan.updatedRequest.query, query);
  expect(identical(plan.updatedRequest.filters, currentRequest.filters), isTrue);
  expect(currentRequest.query, 'old query');
  expect(
    plan.directives.map((directive) => directive.runtimeType),
    [
      BrowserEmitPresetFilterQueryDirective,
      BrowserUpdatePresetSearchRequestDirective,
      BrowserRequestPresetSearchDirective,
    ],
  );

  final emit =
      plan.directives[0] as BrowserEmitPresetFilterQueryDirective;
  expect(emit.query, query);
  final update =
      plan.directives[1] as BrowserUpdatePresetSearchRequestDirective;
  expect(identical(update.request, plan.updatedRequest), isTrue);
  final search =
      plan.directives[2] as BrowserRequestPresetSearchDirective;
  expect(identical(search.request, plan.updatedRequest), isTrue);
  expect(search.forceRefresh, isTrue);
  expect(search.fromUserSearch, isFalse);
}
