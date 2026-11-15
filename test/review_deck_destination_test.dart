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
 * Source-derived from ReviewDeckDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

typedef _ObjectCallbacks =
    ReviewDeckDestinationIntentCallbacks<Object, Object, Object, Object>;

void main() {
  group('ReviewDeckDestination variants', () {
    test('keeps CurrentDeck singleton and exact ExternalLaunch deck IDs', () {
      expect(
        ReviewDeckDestination.currentDeck,
        same(ReviewDeckDestination.currentDeck),
      );

      for (final deckId in [0, -1, 42]) {
        final destination = ReviewDeckDestination.externalLaunch(deckId);
        expect(destination, ReviewDeckExternalLaunch(deckId));
        expect(destination.deckId, deckId);
      }
    });
  });

  group('ReviewDeckDestination.toIntent', () {
    test(
      'CurrentDeck delegates once and returns the exact Reviewer Intent',
      () {
        final context = Object();
        final intent = Object();
        final calls = <(String, Object)>[];
        final callbacks = _ObjectCallbacks(
          getReviewerIntent: (actualContext) {
            calls.add(('reviewer', actualContext));
            return intent;
          },
          createIntent: (_, _) =>
              throw StateError('external intent must not be created'),
          setAction: (_, _) => throw StateError('action must not be set'),
          putLongExtra: (_, _, _) =>
              throw StateError('deck extra must not be written'),
        );

        final result = ReviewDeckDestination.currentDeck.toIntent(
          context: context,
          target: Object(),
          viewAction: Object(),
          deckIdExtraKey: 'deckId',
          callbacks: callbacks,
        );

        expect(result, same(intent));
        expect(calls, [('reviewer', context)]);
        expect(identical(calls.single.$2, context), isTrue);
      },
    );

    test('ExternalLaunch preserves action order, ID, and Intent identity', () {
      final target = Object();
      final viewAction = Object();
      for (final deckId in [0, -19, 812]) {
        final context = Object();
        final intent = Object();
        final events = <Object?>[];
        final callbacks = _ObjectCallbacks(
          getReviewerIntent: (_) =>
              throw StateError('Reviewer must not be called'),
          createIntent: (actualContext, actualTarget) {
            events.add(('create', actualContext, actualTarget));
            return intent;
          },
          setAction: (actualIntent, actualAction) {
            events.add(('action', actualIntent, actualAction));
          },
          putLongExtra: (actualIntent, key, value) {
            events.add(('extra', actualIntent, key, value));
          },
        );

        final result = ReviewDeckDestination.externalLaunch(deckId).toIntent(
          context: context,
          target: target,
          viewAction: viewAction,
          deckIdExtraKey: 'IntentHandler.EXTRA_DECK_ID',
          callbacks: callbacks,
        );

        expect(result, same(intent));
        expect(events, [
          ('create', context, target),
          ('action', intent, viewAction),
          ('extra', intent, 'IntentHandler.EXTRA_DECK_ID', deckId),
        ]);
        expect(
          identical((events.first as (String, Object, Object)).$2, context),
          isTrue,
        );
        expect(
          identical((events.first as (String, Object, Object)).$3, target),
          isTrue,
        );
      }
    });

    test('callback failures propagate unchanged and stop later operations', () {
      final currentFailure = StateError('reviewer failed');
      expect(
        () => ReviewDeckDestination.currentDeck.toIntent(
          context: Object(),
          target: Object(),
          viewAction: Object(),
          deckIdExtraKey: 'deckId',
          callbacks: _ObjectCallbacks(
            getReviewerIntent: (_) => throw currentFailure,
            createIntent: (_, _) => throw StateError('unexpected create'),
            setAction: (_, _) => throw StateError('unexpected action'),
            putLongExtra: (_, _, _) => throw StateError('unexpected extra'),
          ),
        ),
        throwsA(same(currentFailure)),
      );

      for (final stage in ['create', 'action', 'extra']) {
        final failure = StateError('$stage failed');
        final reached = <String>[];
        void invoke(String currentStage) {
          reached.add(currentStage);
          if (currentStage == stage) throw failure;
        }

        expect(
          () => ReviewDeckDestination.externalLaunch(-7).toIntent(
            context: Object(),
            target: Object(),
            viewAction: Object(),
            deckIdExtraKey: 'deckId',
            callbacks: _ObjectCallbacks(
              getReviewerIntent: (_) => throw StateError('unexpected Reviewer'),
              createIntent: (_, _) {
                invoke('create');
                return Object();
              },
              setAction: (_, _) => invoke('action'),
              putLongExtra: (_, _, _) => invoke('extra'),
            ),
          ),
          throwsA(same(failure)),
          reason: 'failure at $stage should propagate',
        );
        expect(reached, switch (stage) {
          'create' => ['create'],
          'action' => ['create', 'action'],
          _ => ['create', 'action', 'extra'],
        }, reason: stage);
      }
    });
  });
}
