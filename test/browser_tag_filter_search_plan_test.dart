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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived cases for CardBrowserViewModel.filterByTags() and
 * setFilterQuery(); see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserTagFilterSearch', () {
    test('wraps the host string and orders request effects', () {
      final filters = BrowserSearchFilters(
        decks: [const BrowserDeckNameId(name: 'Languages', id: 7)],
        flags: [2, 5],
        tags: ['existing tag'],
        noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: 3)],
        cardStateCodes: [0, 2],
      );
      final currentRequest = BrowserSearchRequest(
        query: 'previous query',
        filters: filters,
      );
      const resolvedSearchString = 'tag:foo OR tag:bar';

      final plan = planBrowserTagFilterSearch(
        resolvedSearchString: resolvedSearchString,
        currentRequest: currentRequest,
      );

      expect(plan.query, '(tag:foo OR tag:bar)');
      expect(plan.updatedRequest.query, plan.query);
      expect(identical(plan.updatedRequest.filters, filters), isTrue);
      expect(currentRequest.query, 'previous query');
      expect(identical(currentRequest.filters, filters), isTrue);
      expect(
        plan.directives.map((directive) => directive.runtimeType),
        [
          BrowserEmitTagFilterQueryDirective,
          BrowserUpdateTagFilterSearchRequestDirective,
          BrowserRequestTagFilterSearchDirective,
        ],
      );

      final emit =
          plan.directives[0] as BrowserEmitTagFilterQueryDirective;
      expect(emit.query, plan.query);
      final update = plan.directives[1]
          as BrowserUpdateTagFilterSearchRequestDirective;
      expect(identical(update.request, plan.updatedRequest), isTrue);
      final search =
          plan.directives[2] as BrowserRequestTagFilterSearchDirective;
      expect(identical(search.request, plan.updatedRequest), isTrue);
      expect(search.forceRefresh, isTrue);
      expect(search.fromUserSearch, isFalse);
    });

    test('uses the default refresh flags and preserves an empty host string', () {
      const currentRequest = BrowserSearchRequest(query: 'old query');

      final plan = planBrowserTagFilterSearch(
        resolvedSearchString: '',
        currentRequest: currentRequest,
      );

      expect(plan.query, '()');
      expect(plan.directives, hasLength(3));
      final search =
          plan.directives.last as BrowserRequestTagFilterSearchDirective;
      expect(search.forceRefresh, isTrue);
      expect(search.fromUserSearch, isFalse);
      expect(search.request, same(plan.updatedRequest));
    });
  });
}
