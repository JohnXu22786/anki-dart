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
 * Source-derived from Scheduler.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('schedulerAnswerCard', () {
    test('builds before counting and returns the identical answer', () {
      final card = Object();
      final states = Object();
      final rating = Object();
      final answer = Object();
      final events = <String>[];
      var counter = 7;
      var buildCalls = 0;
      var getCalls = 0;
      var setCalls = 0;

      final result = schedulerAnswerCard<Object, Object, Object, Object>(
        card: card,
        states: states,
        rating: rating,
        buildAnswer: (receivedCard, receivedStates, receivedRating) {
          buildCalls++;
          events.add('build');
          expect(identical(receivedCard, card), isTrue);
          expect(identical(receivedStates, states), isTrue);
          expect(identical(receivedRating, rating), isTrue);
          return answer;
        },
        getNumberOfAnswersRecorded: () {
          getCalls++;
          events.add('get');
          return counter;
        },
        setNumberOfAnswersRecorded: (value) {
          setCalls++;
          events.add('set:$value');
          counter = value;
        },
      );

      expect(identical(result, answer), isTrue);
      expect(events, ['build', 'get', 'set:8']);
      expect((buildCalls, getCalls, setCalls), (1, 1, 1));
      expect(counter, 8);
    });

    test('builder failure skips counter access and mutation', () {
      final failure = StateError('build failed');
      var getCalls = 0;
      var setCalls = 0;

      expect(
        () => schedulerAnswerCard<Object, Object, Object, Object>(
          card: Object(),
          states: Object(),
          rating: Object(),
          buildAnswer: (_, _, _) => throw failure,
          getNumberOfAnswersRecorded: () {
            getCalls++;
            return 0;
          },
          setNumberOfAnswersRecorded: (_) => setCalls++,
        ),
        throwsA(same(failure)),
      );
      expect(getCalls, 0);
      expect(setCalls, 0);
    });

    test('getter and setter failures propagate in source order', () {
      final getFailure = StateError('get failed');
      final getEvents = <String>[];
      expect(
        () => schedulerAnswerCard<Object, Object, Object, Object>(
          card: Object(),
          states: Object(),
          rating: Object(),
          buildAnswer: (_, _, _) {
            getEvents.add('build');
            return Object();
          },
          getNumberOfAnswersRecorded: () {
            getEvents.add('get');
            throw getFailure;
          },
          setNumberOfAnswersRecorded: (_) => getEvents.add('set'),
        ),
        throwsA(same(getFailure)),
      );
      expect(getEvents, ['build', 'get']);

      final setFailure = StateError('set failed');
      final setEvents = <String>[];
      expect(
        () => schedulerAnswerCard<Object, Object, Object, Object>(
          card: Object(),
          states: Object(),
          rating: Object(),
          buildAnswer: (_, _, _) {
            setEvents.add('build');
            return Object();
          },
          getNumberOfAnswersRecorded: () {
            setEvents.add('get');
            return 3;
          },
          setNumberOfAnswersRecorded: (_) {
            setEvents.add('set');
            throw setFailure;
          },
        ),
        throwsA(same(setFailure)),
      );
      expect(setEvents, ['build', 'get', 'set']);
    });

    test('increment wraps at Kotlin Int.MAX_VALUE', () {
      var counter = 0x7fffffff;

      schedulerAnswerCard<Object, Object, Object, Object>(
        card: Object(),
        states: Object(),
        rating: Object(),
        buildAnswer: (_, _, _) => Object(),
        getNumberOfAnswersRecorded: () => counter,
        setNumberOfAnswersRecorded: (value) => counter = value,
      );

      expect(counter, -0x80000000);
    });
  });
}
