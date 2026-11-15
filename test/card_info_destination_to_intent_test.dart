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
 * Source-derived from CardInfoDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CardInfoDestination.toIntent', () {
    const entryPoints = [
      CardInfoDestinationEntryPoint.CURRENT_CARD_STUDY,
      CardInfoDestinationEntryPoint.CURRENT_CARD_BROWSE,
      CardInfoDestinationEntryPoint.PREVIOUS_CARD_STUDY,
    ];

    test('keeps card ID and selects title callbacks by entry point', () {
      for (final entryPoint in entryPoints) {
        final destination = CardInfoDestination(
          cardId: 1234567890123,
          entryPoint: entryPoint,
        );
        final events = <Object?>[];
        final bundle = Object();

        destination.toIntent(
          context: Object(),
          cardInfoFragment: 'CardInfoFragment',
          callbacks: CardInfoDestinationIntentCallbacks<Object, Object, String>(
            resolveBackendTitle: (selected) {
              events.add(('backend', selected));
              return 'title-$selected';
            },
            sentenceCaseTitle: (selected, title) {
              events.add(('sentence', selected, title));
              return '$title!';
            },
            createBundle: () => bundle,
            putString: (target, key, value) {},
            putLong: (target, key, value) {},
            getIntent: (context, fragment, arguments) => 'intent',
          ),
        );

        expect(destination.cardId, 1234567890123);
        expect(destination.entryPoint, entryPoint);
        expect(events, [
          ('backend', entryPoint),
          ('sentence', entryPoint, 'title-$entryPoint'),
        ]);
      }
    });

    test('removes every isolation marker before sentence casing', () {
      final sentenceInputs = <String>[];
      const backendTitle = '\u2068Card\u2069 stats \u2068today\u2069';

      CardInfoDestination(
        cardId: 7,
        entryPoint: CardInfoDestinationEntryPoint.CURRENT_CARD_STUDY,
      ).toIntent(
        context: Object(),
        cardInfoFragment: 'CardInfoFragment',
        callbacks: CardInfoDestinationIntentCallbacks<Object, Object, String>(
          resolveBackendTitle: (_) => backendTitle,
          sentenceCaseTitle: (_, title) {
            sentenceInputs.add(title);
            return '$title!';
          },
          createBundle: () => Object(),
          putString: (target, key, value) {},
          putLong: (target, key, value) {},
          getIntent: (context, fragment, arguments) => 'intent',
        ),
      );

      expect(sentenceInputs, ['Card stats today']);
    });

    test('uses original isolated title when sentence casing is unchanged', () {
      const backendTitle = '\u2068Card\u2069 stats';
      String? bundleTitle;

      CardInfoDestination(
        cardId: 17,
        entryPoint: CardInfoDestinationEntryPoint.CURRENT_CARD_BROWSE,
      ).toIntent(
        context: Object(),
        cardInfoFragment: 'CardInfoFragment',
        callbacks: CardInfoDestinationIntentCallbacks<Object, Object, String>(
          resolveBackendTitle: (_) => backendTitle,
          sentenceCaseTitle: (_, title) => title,
          createBundle: () => Object(),
          putString: (target, key, value) => bundleTitle = value,
          putLong: (target, key, value) {},
          getIntent: (context, fragment, arguments) => 'intent',
        ),
      );

      expect(bundleTitle, backendTitle);
    });

    test('uses changed sentence-case title', () {
      String? bundleTitle;
      CardInfoDestination(
        cardId: 17,
        entryPoint: CardInfoDestinationEntryPoint.PREVIOUS_CARD_STUDY,
      ).toIntent(
        context: Object(),
        cardInfoFragment: 'CardInfoFragment',
        callbacks: CardInfoDestinationIntentCallbacks<Object, Object, String>(
          resolveBackendTitle: (_) => '\u2068previous card\u2069',
          sentenceCaseTitle: (_, title) => 'Previous card',
          createBundle: () => Object(),
          putString: (target, key, value) => bundleTitle = value,
          putLong: (target, key, value) {},
          getIntent: (context, fragment, arguments) => 'intent',
        ),
      );

      expect(bundleTitle, 'Previous card');
    });

    test(
      'writes title then long card ID and delegates exact bundle and tokens',
      () {
        final context = Object();
        final fragment = Object();
        final bundle = Object();
        final intent = Object();
        final events = <Object?>[];
        final result =
            CardInfoDestination(
              cardId: -8,
              entryPoint: CardInfoDestinationEntryPoint.CURRENT_CARD_STUDY,
            ).toIntent(
              context: context,
              cardInfoFragment: fragment,
              callbacks:
                  CardInfoDestinationIntentCallbacks<Object, Object, Object>(
                    resolveBackendTitle: (_) => 'Card info',
                    sentenceCaseTitle: (_, title) => title,
                    createBundle: () {
                      events.add('bundle');
                      return bundle;
                    },
                    putString: (target, key, value) {
                      events.add(('string', target, key, value));
                    },
                    putLong: (target, key, value) {
                      events.add(('long', target, key, value));
                    },
                    getIntent: (actualContext, actualFragment, arguments) {
                      events.add((
                        'intent',
                        actualContext,
                        actualFragment,
                        arguments,
                      ));
                      return intent;
                    },
                  ),
            );

        expect(result, same(intent));
        expect(events, [
          'bundle',
          ('string', bundle, 'title', 'Card info'),
          ('long', bundle, 'cardId', -8),
          ('intent', context, fragment, bundle),
        ]);
      },
    );

    test('propagates callback failures and stops later operations', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'backend', reached: ['backend']),
        (stage: 'sentence', reached: ['backend', 'sentence']),
        (stage: 'bundle', reached: ['backend', 'sentence', 'bundle']),
        (stage: 'title', reached: ['backend', 'sentence', 'bundle', 'title']),
        (
          stage: 'cardId',
          reached: ['backend', 'sentence', 'bundle', 'title', 'cardId'],
        ),
        (
          stage: 'intent',
          reached: [
            'backend',
            'sentence',
            'bundle',
            'title',
            'cardId',
            'intent',
          ],
        ),
      ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.stage} failed');
        final reached = <String>[];
        void invoke(String stage) {
          reached.add(stage);
          if (stage == testCase.stage) throw failure;
        }

        expect(
          () =>
              CardInfoDestination(
                cardId: 23,
                entryPoint: CardInfoDestinationEntryPoint.CURRENT_CARD_STUDY,
              ).toIntent(
                context: Object(),
                cardInfoFragment: Object(),
                callbacks:
                    CardInfoDestinationIntentCallbacks<Object, Object, Object>(
                      resolveBackendTitle: (_) {
                        invoke('backend');
                        return 'title';
                      },
                      sentenceCaseTitle: (_, title) {
                        invoke('sentence');
                        return title;
                      },
                      createBundle: () {
                        invoke('bundle');
                        return Object();
                      },
                      putString: (target, key, value) => invoke('title'),
                      putLong: (target, key, value) => invoke('cardId'),
                      getIntent: (context, fragment, arguments) {
                        invoke('intent');
                        return Object();
                      },
                    ),
              ),
          throwsA(same(failure)),
          reason: 'failure at ${testCase.stage} should propagate',
        );
        expect(reached, testCase.reached, reason: testCase.stage);
      }
    });
  });
}
