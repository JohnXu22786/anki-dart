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
 * Source-derived from BrowserDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

typedef _ObjectCallbacks =
    BrowserDestinationIntentCallbacks<Object, Object, Object>;

void main() {
  group('BrowserDestination variants', () {
    test('retains all variants and their exact values', () {
      expect(BrowserDestination.open, same(BrowserDestination.open));

      for (final deckId in [0, -1, 42, 1234567890123]) {
        final destination = BrowserDestination.toDeck(deckId);
        expect(destination, BrowserDestinationToDeck(deckId));
        expect(destination.deckId, deckId);
      }

      for (final (deckId, cardId) in [
        (0, 0),
        (-7, -91),
        (1234567890123, 1234567890123),
      ]) {
        final destination = BrowserDestination.scrollToCard(deckId, cardId);
        expect(destination, BrowserDestinationScrollToCard(deckId, cardId));
        expect(destination.deckId, deckId);
        expect(destination.cardId, cardId);
      }

      for (final (query, allDecks) in [
        ('', false),
        ('', true),
        ('tag:x', false),
      ]) {
        final destination = BrowserDestination.search(query, allDecks);
        expect(destination, BrowserDestinationSearch(query, allDecks));
        expect(destination.query, query);
        expect(destination.allDecks, allDecks);
      }
    });
  });

  group('BrowserDestination.toIntent', () {
    test(
      'creates a fresh CardBrowser Intent and writes only source extras in order',
      () {
        final context = Object();
        final target = Object();
        final cases =
            <
              ({
                BrowserDestination destination,
                List<(String, String, Object)> extras,
              })
            >[
              (destination: BrowserDestination.open, extras: []),
              (destination: BrowserDestination.open, extras: []),
              (
                destination: BrowserDestination.toDeck(-23),
                extras: [('long', 'deck-id', -23)],
              ),
              (
                destination: BrowserDestination.scrollToCard(0, -9876543210123),
                extras: [
                  ('long', 'deck-id', 0),
                  ('long', 'card-id', -9876543210123),
                ],
              ),
              (
                destination: BrowserDestination.search('', false),
                extras: [
                  ('string', 'search-query', ''),
                  ('boolean', 'all-decks', false),
                ],
              ),
              (
                destination: BrowserDestination.search('tag:marked', true),
                extras: [
                  ('string', 'search-query', 'tag:marked'),
                  ('boolean', 'all-decks', true),
                ],
              ),
            ];

        final openIntents = <Object>[];
        for (final testCase in cases) {
          final events = <Object?>[];
          final intent = Object();
          final callbacks = _ObjectCallbacks(
            createIntent: (actualContext, actualTarget) {
              events.add(('create', actualContext, actualTarget));
              return intent;
            },
            putLongExtra: (actualIntent, key, value) {
              events.add(('long', actualIntent, key, value));
            },
            putStringExtra: (actualIntent, key, value) {
              events.add(('string', actualIntent, key, value));
            },
            putBooleanExtra: (actualIntent, key, value) {
              events.add(('boolean', actualIntent, key, value));
            },
          );

          final result = testCase.destination.toIntent(
            context: context,
            cardBrowserTarget: target,
            deckIdExtraKey: 'deck-id',
            cardIdExtraKey: 'card-id',
            searchQueryExtraKey: 'search-query',
            allDecksExtraKey: 'all-decks',
            callbacks: callbacks,
          );

          expect(result, same(intent));
          expect(events.first, ('create', context, target));
          expect(
            events.skip(1).map((event) {
              final tuple = event! as (String, Object, String, Object);
              return (tuple.$1, tuple.$3, tuple.$4);
            }),
            testCase.extras,
          );
          expect(events.length, testCase.extras.length + 1);
          if (testCase.destination == BrowserDestination.open) {
            openIntents.add(result);
          }
        }
        expect(openIntents, hasLength(2));
        expect(openIntents[0], isNot(same(openIntents[1])));
      },
    );

    test('callback failures propagate and stop later source operations', () {
      final cases =
          <
            ({
              BrowserDestination destination,
              String failureAt,
              List<String> reached,
            })
          >[
            (
              destination: BrowserDestination.open,
              failureAt: 'create',
              reached: ['create'],
            ),
            (
              destination: BrowserDestination.toDeck(4),
              failureAt: 'deck',
              reached: ['create', 'deck'],
            ),
            (
              destination: BrowserDestination.scrollToCard(4, 5),
              failureAt: 'deck',
              reached: ['create', 'deck'],
            ),
            (
              destination: BrowserDestination.scrollToCard(4, 5),
              failureAt: 'card',
              reached: ['create', 'deck', 'card'],
            ),
            (
              destination: BrowserDestination.search('q', true),
              failureAt: 'query',
              reached: ['create', 'query'],
            ),
            (
              destination: BrowserDestination.search('q', true),
              failureAt: 'all-decks',
              reached: ['create', 'query', 'all-decks'],
            ),
          ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.failureAt} failed');
        final reached = <String>[];
        void invoke(String operation) {
          reached.add(operation);
          if (operation == testCase.failureAt) throw failure;
        }

        expect(
          () => testCase.destination.toIntent(
            context: Object(),
            cardBrowserTarget: Object(),
            deckIdExtraKey: 'deck-id',
            cardIdExtraKey: 'card-id',
            searchQueryExtraKey: 'search-query',
            allDecksExtraKey: 'all-decks',
            callbacks: _ObjectCallbacks(
              createIntent: (_, _) {
                invoke('create');
                return Object();
              },
              putLongExtra: (_, key, value) =>
                  invoke(key == 'deck-id' ? 'deck' : 'card'),
              putStringExtra: (_, _, _) => invoke('query'),
              putBooleanExtra: (_, _, _) => invoke('all-decks'),
            ),
          ),
          throwsA(same(failure)),
          reason: 'failure at ${testCase.failureAt} should propagate',
        );
        expect(reached, testCase.reached, reason: testCase.failureAt);
      }
    });
  });
}
