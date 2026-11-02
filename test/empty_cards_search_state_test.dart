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
 * Source-derived cases for EmptyCardsViewModel.searchForEmptyCards();
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Empty Cards search state', () {
    test(
      'starts in the shared searching state and publishes the exact report',
      () async {
        final plan = EmptyCardsSearchPlan<Object>();
        final report = Object();
        final states = <EmptyCardsUiState>[];
        final events = <String>[];

        expect(plan.initialState, same(SearchingForEmptyCards.instance));

        await plan.searchForEmptyCards(
          getEmptyCards: () async {
            events.add('query-start');
            await Future<void>.delayed(Duration.zero);
            events.add('query-end');
            return report;
          },
          isCancellation: (_) => false,
          emit: (state) {
            events.add('emit');
            states.add(state);
          },
        );

        expect(events, ['query-start', 'query-end', 'emit']);
        expect(states, hasLength(1));
        final published = states.single;
        expect(published, isA<EmptyCardsSearchResult<Object>>());
        expect(
          (published as EmptyCardsSearchResult<Object>).emptyCardsReport,
          same(report),
        );
      },
    );

    test(
      'does not classify a result publication error as a query failure',
      () async {
        final plan = EmptyCardsSearchPlan<Object>();
        final report = Object();
        final publicationError = StateError('publish failed');
        final states = <EmptyCardsUiState>[];

        await expectLater(
          plan.searchForEmptyCards(
            getEmptyCards: () => report,
            isCancellation: (_) => false,
            emit: (state) {
              states.add(state);
              throw publicationError;
            },
          ),
          throwsA(same(publicationError)),
        );
        expect(states, hasLength(1));
        expect(states.single, isA<EmptyCardsSearchResult<Object>>());
      },
    );

    test(
      'rethrows cancellation unchanged without publishing a failure state',
      () async {
        final plan = EmptyCardsSearchPlan<Object>();
        final cancellation = _Cancellation();
        final states = <EmptyCardsUiState>[];

        await expectLater(
          plan.searchForEmptyCards(
            getEmptyCards: () => throw cancellation,
            isCancellation: (error) => identical(error, cancellation),
            emit: states.add,
          ),
          throwsA(same(cancellation)),
        );
        expect(states, isEmpty);
      },
    );

    test('captures a non-Exception thrown object by identity', () async {
      final plan = EmptyCardsSearchPlan<Object>();
      final thrownObject = Object();
      final states = <EmptyCardsUiState>[];

      await plan.searchForEmptyCards(
        getEmptyCards: () => throw thrownObject,
        isCancellation: (_) => false,
        emit: states.add,
      );

      expect(states, hasLength(1));
      final published = states.single;
      expect(published, isA<EmptyCardsSearchFailure>());
      expect(
        (published as EmptyCardsSearchFailure).throwable,
        same(thrownObject),
      );
    });

    test('publishes an ordinary query exception by identity', () async {
      final plan = EmptyCardsSearchPlan<Object>();
      final error = FormatException('query failed');
      final states = <EmptyCardsUiState>[];

      await plan.searchForEmptyCards(
        getEmptyCards: () => throw error,
        isCancellation: (_) => false,
        emit: states.add,
      );

      expect(states, hasLength(1));
      final published = states.single;
      expect(published, isA<EmptyCardsSearchFailure>());
      expect((published as EmptyCardsSearchFailure).throwable, same(error));
    });
  });
}

final class _Cancellation implements Exception {}
