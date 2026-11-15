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
 * Source-derived from StudyOptionsDestination.kt and StatisticsDestination.kt
 * in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('StudyOptionsDestination.toIntent', () {
    test('is a singleton and delegates the exact host activity token once', () {
      final context = Object();
      final activity = Object();
      final intent = Object();
      final calls = <(Object, Object)>[];

      final result = StudyOptionsDestination.instance
          .toIntent<Object, Object, Object>(
            context: context,
            studyOptionsActivity: activity,
            callbacks:
                StudyOptionsDestinationIntentCallbacks<Object, Object, Object>(
                  createIntent: (actualContext, actualActivity) {
                    calls.add((actualContext, actualActivity));
                    return intent;
                  },
                ),
          );

      expect(
        StudyOptionsDestination.instance,
        same(StudyOptionsDestination.instance),
      );
      expect(calls, hasLength(1));
      expect(calls.single.$1, same(context));
      expect(calls.single.$2, same(activity));
      expect(result, same(intent));
    });
  });

  group('StatisticsDestination.toIntent', () {
    test(
      'is a singleton and uses its statistics-specific host callback once',
      () {
        final context = Object();
        final fragment = Object();
        final intent = Object();
        final calls = <(Object, Object)>[];

        final result = StatisticsDestination.instance
            .toIntent<Object, Object, Object>(
              context: context,
              statisticsFragment: fragment,
              callbacks:
                  StatisticsDestinationIntentCallbacks<Object, Object, Object>(
                    getStatisticsIntent: (actualContext, actualFragment) {
                      calls.add((actualContext, actualFragment));
                      return intent;
                    },
                  ),
            );

        expect(
          StatisticsDestination.instance,
          same(StatisticsDestination.instance),
        );
        expect(calls, hasLength(1));
        expect(calls.single.$1, same(context));
        expect(calls.single.$2, same(fragment));
        expect(result, same(intent));
      },
    );
  });

  test(
    'both destination callbacks propagate their exact failure unchanged',
    () {
      final studyFailure = StateError('study Intent creation failed');
      var studyCalls = 0;
      expect(
        () => StudyOptionsDestination.instance.toIntent<Object, Object, Object>(
          context: Object(),
          studyOptionsActivity: Object(),
          callbacks:
              StudyOptionsDestinationIntentCallbacks<Object, Object, Object>(
                createIntent: (_, _) {
                  studyCalls++;
                  throw studyFailure;
                },
              ),
        ),
        throwsA(same(studyFailure)),
      );
      expect(studyCalls, 1);

      final statisticsFailure = StateError('statistics Intent creation failed');
      var statisticsCalls = 0;
      expect(
        () => StatisticsDestination.instance.toIntent<Object, Object, Object>(
          context: Object(),
          statisticsFragment: Object(),
          callbacks:
              StatisticsDestinationIntentCallbacks<Object, Object, Object>(
                getStatisticsIntent: (_, _) {
                  statisticsCalls++;
                  throw statisticsFailure;
                },
              ),
        ),
        throwsA(same(statisticsFailure)),
      );
      expect(statisticsCalls, 1);
    },
  );
}
