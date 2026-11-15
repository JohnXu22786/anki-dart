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
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from DeckOptionsDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('DeckOptionsDestination model', () {
    test(
      'preserves fields, options list identity and order, and empty default',
      () {
        final options = <DeckOptionsEntry>[
          const DeckOptionsEntry(deckId: 8, name: 'Eight', isFiltered: true),
          const DeckOptionsEntry(deckId: 4, name: null, isFiltered: false),
        ];
        final destination = DeckOptionsDestination(
          deckId: -12,
          isFiltered: true,
          options: options,
        );

        expect(destination.deckId, -12);
        expect(destination.isFiltered, isTrue);
        expect(destination.options, same(options));
        expect(destination.options, orderedEquals(options));
        expect(options.first.name, 'Eight');
        expect(options.last.name, isNull);
        expect(options.last.deckId, 4);
        expect(options.last.isFiltered, isFalse);

        final empty = DeckOptionsDestination(deckId: 2, isFiltered: false);
        expect(empty.options, isEmpty);
      },
    );
  });

  group('DeckOptionsDestination.fromDeckId', () {
    test('checks filtered state once with the exact ID', () async {
      const deckId = -991;
      final calls = <int>[];
      final destination = await DeckOptionsDestination.fromDeckId(
        deckId: deckId,
        callbacks: DeckOptionsDestinationCollectionCallbacks(
          getCurrentDeckId: () async => fail('current deck must not be read'),
          isFiltered: (actualDeckId) async {
            calls.add(actualDeckId);
            return true;
          },
        ),
      );

      expect(calls, [deckId]);
      expect(destination.deckId, deckId);
      expect(destination.isFiltered, isTrue);
      expect(destination.options, isEmpty);
    });

    test('propagates filtered-state failure unchanged', () async {
      final failure = StateError('collection unavailable');
      final calls = <int>[];

      await expectLater(
        DeckOptionsDestination.fromDeckId(
          deckId: 7,
          callbacks: DeckOptionsDestinationCollectionCallbacks(
            getCurrentDeckId: () async => fail('current deck must not be read'),
            isFiltered: (deckId) async {
              calls.add(deckId);
              throw failure;
            },
          ),
        ),
        throwsA(same(failure)),
      );
      expect(calls, [7]);
    });
  });

  group('DeckOptionsDestination.fromCurrentDeck', () {
    test(
      'reads current ID before checking filtered state exactly once',
      () async {
        const deckId = 812;
        final events = <Object?>[];
        final destination = await DeckOptionsDestination.fromCurrentDeck(
          callbacks: DeckOptionsDestinationCollectionCallbacks(
            getCurrentDeckId: () async {
              events.add('current');
              return deckId;
            },
            isFiltered: (actualDeckId) async {
              events.add(('filtered', actualDeckId));
              return false;
            },
          ),
        );

        expect(events, ['current', ('filtered', deckId)]);
        expect(destination.deckId, deckId);
        expect(destination.isFiltered, isFalse);
        expect(destination.options, isEmpty);
      },
    );

    test(
      'stops after current-ID failure and propagates it unchanged',
      () async {
        final failure = StateError('current deck failed');
        final events = <String>[];

        await expectLater(
          DeckOptionsDestination.fromCurrentDeck(
            callbacks: DeckOptionsDestinationCollectionCallbacks(
              getCurrentDeckId: () async {
                events.add('current');
                throw failure;
              },
              isFiltered: (deckId) async {
                events.add('filtered');
                return true;
              },
            ),
          ),
          throwsA(same(failure)),
        );
        expect(events, ['current']);
      },
    );

    test(
      'stops after filtered-state failure and propagates it unchanged',
      () async {
        const deckId = 73;
        final failure = StateError('filtered lookup failed');
        final events = <Object?>[];

        await expectLater(
          DeckOptionsDestination.fromCurrentDeck(
            callbacks: DeckOptionsDestinationCollectionCallbacks(
              getCurrentDeckId: () async {
                events.add('current');
                return deckId;
              },
              isFiltered: (actualDeckId) async {
                events.add(('filtered', actualDeckId));
                throw failure;
              },
            ),
          ),
          throwsA(same(failure)),
        );
        expect(events, ['current', ('filtered', deckId)]);
      },
    );
  });

  group('DeckOptionsDestination.toIntent', () {
    for (final isFiltered in [true, false]) {
      test(
        'delegates only the ${isFiltered ? 'filtered' : 'ordinary'} builder',
        () {
          final context = Object();
          final intent = Object();
          final calls = <Object?>[];
          final result =
              DeckOptionsDestination(
                deckId: -18,
                isFiltered: isFiltered,
              ).toIntent(
                context: context,
                callbacks:
                    DeckOptionsDestinationIntentCallbacks<Object, Object>(
                      getFilteredDeckOptionsIntent: (actualContext, deckId) {
                        calls.add(('filtered', actualContext, deckId));
                        return intent;
                      },
                      getDeckOptionsIntent: (actualContext, deckId) {
                        calls.add(('ordinary', actualContext, deckId));
                        return intent;
                      },
                    ),
              );

          expect(result, same(intent));
          expect(calls, [(isFiltered ? 'filtered' : 'ordinary', context, -18)]);
        },
      );
    }
  });
}
