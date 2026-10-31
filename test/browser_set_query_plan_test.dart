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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived cases for CardBrowserViewModel.setQuery(); see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserSetQuery', () {
    test('uses the source refresh and user-search defaults', () {
      const currentRequest = BrowserSearchRequest(query: 'current');

      final plan = planBrowserSetQuery(
        currentRequest: currentRequest,
        query: 'next',
        serializedSearchStringsEqual: false,
      )!;

      expect(plan.updatedRequest.query, 'next');
      final search = plan.directives.last as BrowserRequestQuerySearchDirective;
      expect(search.forceRefresh, isTrue);
      expect(search.fromUserSearch, isFalse);
    });

    test(
      'skips assignment and search for equal strings without forced refresh',
      () {
        final currentRequest = BrowserSearchRequest(
          query: 'old query',
          filters: BrowserSearchFilters(tags: ['current']),
        );

        final plan = planBrowserSetQuery(
          currentRequest: currentRequest,
          query: 'new query',
          forceRefresh: false,
          serializedSearchStringsEqual: true,
          fromUserSearch: true,
        );

        expect(plan, isNull);
      },
    );

    test(
      'forced refresh copies the query and requests search when strings match',
      () {
        final currentRequest = BrowserSearchRequest(
          query: 'current',
          filters: BrowserSearchFilters(tags: ['tag']),
        );

        final plan = planBrowserSetQuery(
          currentRequest: currentRequest,
          query: '  exact query\n',
          forceRefresh: true,
          serializedSearchStringsEqual: true,
          fromUserSearch: true,
        )!;

        _expectQueryPlan(
          plan,
          currentRequest: currentRequest,
          query: '  exact query\n',
          forceRefresh: true,
          fromUserSearch: true,
        );
      },
    );

    test(
      'unequal strings copy the query then request search without forced refresh',
      () {
        final currentRequest = BrowserSearchRequest(
          query: 'old query',
          filters: BrowserSearchFilters(
            decks: [const BrowserDeckNameId(name: 'Languages', id: 7)],
            flags: [1],
            tags: ['keep'],
            noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: 3)],
            cardStateCodes: [0],
          ),
        );

        final plan = planBrowserSetQuery(
          currentRequest: currentRequest,
          query: 'new query',
          forceRefresh: false,
          serializedSearchStringsEqual: false,
          fromUserSearch: true,
        )!;

        _expectQueryPlan(
          plan,
          currentRequest: currentRequest,
          query: 'new query',
          forceRefresh: false,
          fromUserSearch: true,
        );
      },
    );
  });
}

void _expectQueryPlan(
  BrowserSetQueryPlan plan, {
  required BrowserSearchRequest currentRequest,
  required String query,
  required bool forceRefresh,
  required bool fromUserSearch,
}) {
  expect(plan.updatedRequest.query, query);
  expect(plan.updatedRequest.filters, same(currentRequest.filters));
  expect(currentRequest.query, isNot(query));
  expect(plan.directives.map((directive) => directive.runtimeType), [
    BrowserUpdateQuerySearchRequestDirective,
    BrowserRequestQuerySearchDirective,
  ]);

  final update =
      plan.directives.first as BrowserUpdateQuerySearchRequestDirective;
  expect(update.request, same(plan.updatedRequest));
  final search = plan.directives.last as BrowserRequestQuerySearchDirective;
  expect(search.request, same(plan.updatedRequest));
  expect(search.forceRefresh, forceRefresh);
  expect(search.fromUserSearch, fromUserSearch);
}
