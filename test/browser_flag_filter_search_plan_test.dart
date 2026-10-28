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
 * Source-derived cases for CardBrowserViewModel.setFlagFilter(); see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('planBrowserFlagFilterSearch', () {
    test('transforms the exact supplied search terms and orders effects', () {
      final filters = BrowserSearchFilters(
        decks: [const BrowserDeckNameId(name: 'Languages', id: 7)],
        flags: [2, 5],
        tags: ['keep tag'],
        noteTypes: [BrowserNoteTypeNameId(name: 'Basic', id: 3)],
        cardStateCodes: [0, 2],
      );
      final currentRequest = BrowserSearchRequest(
        query: 'request query differs',
        filters: filters,
      );

      final plan = planBrowserFlagFilterSearch(
        searchTerms: 'is:new flag:3',
        flagCode: 7,
        currentRequest: currentRequest,
      );

      expect(plan.query, 'is:new flag:7');
      expect(plan.updatedRequest.query, 'is:new flag:7');
      expect(plan.updatedRequest.filters, same(filters));
      expect(plan.directives.map((directive) => directive.runtimeType), [
        BrowserEmitFlagFilterQueryDirective,
        BrowserUpdateFlagFilterSearchRequestDirective,
        BrowserRequestFlagFilterSearchDirective,
      ]);

      final emit = plan.directives[0] as BrowserEmitFlagFilterQueryDirective;
      expect(emit.query, plan.query);
      final update =
          plan.directives[1] as BrowserUpdateFlagFilterSearchRequestDirective;
      expect(update.request, same(plan.updatedRequest));
      final search =
          plan.directives[2] as BrowserRequestFlagFilterSearchDirective;
      expect(search.request, same(plan.updatedRequest));
      expect(search.forceRefresh, isTrue);
      expect(search.fromUserSearch, isFalse);
      expect(currentRequest.query, 'request query differs');
      expect(currentRequest.filters, same(filters));
    });

    test('uses source defaults when no current flag term exists', () {
      const currentRequest = BrowserSearchRequest(query: '');

      final plan = planBrowserFlagFilterSearch(
        searchTerms: 'deck:Current',
        flagCode: 0,
        currentRequest: currentRequest,
      );

      expect(plan.query, 'flag:0 deck:Current');
      expect(plan.directives, hasLength(3));
      expect(
        (plan.directives.last as BrowserRequestFlagFilterSearchDirective)
            .forceRefresh,
        isTrue,
      );
      expect(
        (plan.directives.last as BrowserRequestFlagFilterSearchDirective)
            .fromUserSearch,
        isFalse,
      );
    });
  });
}
