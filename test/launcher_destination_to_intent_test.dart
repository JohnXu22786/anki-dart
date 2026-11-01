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
 * Source-derived from LauncherDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LauncherDestination.toIntent', () {
    test(
      'creates once, sets host tokens in source order, and returns that Intent',
      () {
        final context = Object();
        final target = Object();
        final action = Object();
        final category = Object();
        final intent = Object();
        final events = <Object?>[];

        final result = LauncherDestination.instance
            .toIntent<Object, Object, Object, Object, Object>(
              context: context,
              target: target,
              action: action,
              category: category,
              callbacks:
                  LauncherDestinationIntentCallbacks<
                    Object,
                    Object,
                    Object,
                    Object,
                    Object
                  >(
                    createIntent: (actualContext, actualTarget) {
                      events.add(('create', actualContext, actualTarget));
                      return intent;
                    },
                    setAction: (actualIntent, actualAction) {
                      events.add(('action', actualIntent, actualAction));
                    },
                    addCategory: (actualIntent, actualCategory) {
                      events.add(('category', actualIntent, actualCategory));
                    },
                  ),
            );

        expect(result, same(intent));
        expect(events, [
          ('create', context, target),
          ('action', intent, action),
          ('category', intent, category),
        ]);
      },
    );

    test('callback failures propagate unchanged and stop later operations', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'create', reached: ['create']),
        (stage: 'action', reached: ['create', 'action']),
        (stage: 'category', reached: ['create', 'action', 'category']),
      ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.stage} failed');
        final reached = <String>[];
        void invoke(String stage) {
          reached.add(stage);
          if (stage == testCase.stage) throw failure;
        }

        expect(
          () => LauncherDestination.instance
              .toIntent<Object, Object, Object, Object, Object>(
                context: Object(),
                target: Object(),
                action: Object(),
                category: Object(),
                callbacks:
                    LauncherDestinationIntentCallbacks<
                      Object,
                      Object,
                      Object,
                      Object,
                      Object
                    >(
                      createIntent: (_, _) {
                        invoke('create');
                        return Object();
                      },
                      setAction: (_, _) => invoke('action'),
                      addCategory: (_, _) => invoke('category'),
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
