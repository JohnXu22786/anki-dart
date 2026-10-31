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
 * Source-derived from FilteredDeckOptionsViewModelTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Filtered Deck browser search request', () {
    test('first filter search is copied exactly, including empty text', () {
      for (final search in ['', '  deck:A flag:1  ']) {
        final request = filteredDeckBrowserSearchRequest(
          current: FilteredDeckOptions(
            filter1State: SearchTermState(search: search),
          ),
          index: FilterIndex.first,
        );

        expect(request?.search, search);
      }
    });

    test('second filter with no current state makes no request', () {
      final request = filteredDeckBrowserSearchRequest(
        current: const FilteredDeckOptions(filter2State: null),
        index: FilterIndex.second,
      );

      expect(request, isNull);
    });

    test('populated second filter search is copied exactly', () {
      final request = filteredDeckBrowserSearchRequest(
        current: const FilteredDeckOptions(
          filter2State: SearchTermState(search: '  prop:due  '),
        ),
        index: FilterIndex.second,
      );

      expect(request?.search, '  prop:due  ');
    });
  });

  group('Filtered Deck browser search result', () {
    test('success stores the exact query and preserves the existing error', () {
      final previousError = StateError('existing error');
      final current = FilteredDeckOptions(
        throwable: previousError,
        browserQuery: 'old query',
      );

      final result = onSearchInBrowserSuccess(
        current: current,
        browserQuery: '  deck:A flag:1  ',
      );

      expect(result.browserQuery, '  deck:A flag:1  ');
      expect(identical(result.throwable, previousError), isTrue);
    });

    test(
      'failure wraps cause and localized message without changing query',
      () {
        final cause = StateError('backend detail');
        final previousError = StateError('previous error');
        final current = FilteredDeckOptions(
          throwable: previousError,
          browserQuery: 'existing browser query',
        );

        final result = onSearchInBrowserFailure(
          current: current,
          cause: cause,
          localizedMessage: 'localized search error',
        );

        final error = result.throwable! as FilteredDeckInvalidSearchException;
        expect(identical(error.cause, cause), isTrue);
        expect(error.message, 'localized search error');
        expect(identical(result.throwable, previousError), isFalse);
        expect(result.browserQuery, 'existing browser query');
      },
    );

    test('failure preserves a null localized message as null', () {
      final cause = StateError('backend detail');

      final result = onSearchInBrowserFailure(
        current: const FilteredDeckOptions(),
        cause: cause,
        localizedMessage: null,
      );

      final error = result.throwable! as FilteredDeckInvalidSearchException;
      expect(identical(error.cause, cause), isTrue);
      expect(error.message, isNull);
      expect(result.browserQuery, isNull);
    });
  });
}
