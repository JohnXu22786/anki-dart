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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: AnswerTimer.kt, AnswerTimerState.kt, and
 * AnswerTimerTest.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AnswerTimer', () {
    test('starts hidden and remains hidden when not shown for a card', () {
      final clock = _FakeClock(0);
      final timer = AnswerTimer(elapsedRealtime: clock.read);

      expect(timer.state, const AnswerTimerHidden());
      timer.configureForCard(shouldShow: false, limitMs: 1000);

      expect(timer.state, const AnswerTimerHidden());
    });

    test('configuring a visible card records clock base and limit', () {
      final clock = _FakeClock(1000);
      final timer = AnswerTimer(elapsedRealtime: clock.read);

      timer.configureForCard(shouldShow: true, limitMs: 5000);

      final state = timer.state as AnswerTimerRunning;
      expect(state, const AnswerTimerRunning(baseTime: 1000, limitMs: 5000));
      expect(state.baseTime, 1000);
      expect(state.limitMs, 5000);
    });

    test('state stream replays the current state and emits transitions',
        () async {
      final clock = _FakeClock(1000);
      final timer = AnswerTimer(elapsedRealtime: clock.read)
        ..configureForCard(shouldShow: true, limitMs: 5000);

      final states = timer.stateStream.take(4).toList();
      clock.now = 2000;
      timer.onPause();
      clock.now = 4000;
      timer.onResume();
      timer.hide();

      expect(
        await states,
        const <AnswerTimerState>[
          AnswerTimerRunning(baseTime: 1000, limitMs: 5000),
          AnswerTimerPaused(elapsedTimeMs: 1000, limitMs: 5000),
          AnswerTimerRunning(baseTime: 3000, limitMs: 5000),
          AnswerTimerHidden(),
        ],
      );
    });

    test('stopping a running timer records elapsed time and caps at limit', () {
      final clock = _FakeClock(1000);
      final timer = AnswerTimer(elapsedRealtime: clock.read)
        ..configureForCard(shouldShow: true, limitMs: 5000);

      clock.now = 3500;
      timer.stop();

      final state = timer.state as AnswerTimerStopped;
      expect(state.elapsedTimeMs, 2500);
      expect(state.limitMs, 5000);

      timer.configureForCard(shouldShow: true, limitMs: 5000);
      clock.now = 10000;
      timer.stop();
      expect((timer.state as AnswerTimerStopped).elapsedTimeMs, 5000);
    });

    test('pause and resume exclude time spent paused', () {
      final clock = _FakeClock(1000);
      final timer = AnswerTimer(elapsedRealtime: clock.read)
        ..configureForCard(shouldShow: true, limitMs: 10000);

      clock.now = 3000;
      timer.onPause();
      expect((timer.state as AnswerTimerPaused).elapsedTimeMs, 2000);

      clock.now = 5000;
      timer.onResume();

      final state = timer.state as AnswerTimerRunning;
      expect(state.baseTime, 3000);
      expect(clock.now - state.baseTime, 2000);
    });

    test('pause caps elapsed time and resume stops at the reached limit', () {
      final clock = _FakeClock(1000);
      final timer = AnswerTimer(elapsedRealtime: clock.read)
        ..configureForCard(shouldShow: true, limitMs: 5000);

      clock.now = 7000;
      timer.onPause();
      expect((timer.state as AnswerTimerPaused).elapsedTimeMs, 5000);

      timer.onResume();

      final state = timer.state as AnswerTimerStopped;
      expect(state.elapsedTimeMs, 5000);
      expect(state.limitMs, 5000);
    });

    test('stopping a paused timer keeps its paused elapsed time', () {
      final clock = _FakeClock(1000);
      final timer = AnswerTimer(elapsedRealtime: clock.read)
        ..configureForCard(shouldShow: true, limitMs: 10000);

      clock.now = 3000;
      timer.onPause();
      clock.now = 9000;
      timer.stop();

      final state = timer.state as AnswerTimerStopped;
      expect(state.elapsedTimeMs, 2000);
      expect(state.limitMs, 10000);
    });

    test('hide forces Hidden and nonmatching transitions leave state intact',
        () {
      final clock = _FakeClock(1000);
      final timer = AnswerTimer(elapsedRealtime: clock.read);

      timer.onPause();
      timer.onResume();
      timer.stop();
      expect(timer.state, isA<AnswerTimerHidden>());

      timer.configureForCard(shouldShow: true, limitMs: 10000);
      final running = timer.state;
      timer.onResume();
      expect(timer.state, same(running));

      timer.hide();
      expect(timer.state, isA<AnswerTimerHidden>());
      timer.onPause();
      expect(timer.state, isA<AnswerTimerHidden>());

      timer.configureForCard(shouldShow: true, limitMs: 10000);
      timer.stop();
      final stopped = timer.state;
      timer.stop();
      timer.onPause();
      timer.onResume();
      expect(timer.state, same(stopped));
    });

    test('negative elapsed deltas are not lower-clamped', () {
      final clock = _FakeClock(100);
      final timer = AnswerTimer(elapsedRealtime: clock.read)
        ..configureForCard(shouldShow: true, limitMs: 1000);

      clock.now = 90;
      timer.onPause();

      final state = timer.state as AnswerTimerPaused;
      expect(state.elapsedTimeMs, -10);
      expect(state.limitMs, 1000);
    });

    test('zero and negative limits use the source upper clamp and comparison',
        () {
      final clock = _FakeClock(100);
      final timer = AnswerTimer(elapsedRealtime: clock.read)
        ..configureForCard(shouldShow: true, limitMs: 0);

      clock.now = 110;
      timer.onPause();
      expect((timer.state as AnswerTimerPaused).elapsedTimeMs, 0);
      timer.onResume();
      expect(timer.state, isA<AnswerTimerStopped>());

      timer.configureForCard(shouldShow: true, limitMs: -5);
      clock.now = 110;
      timer.stop();
      final state = timer.state as AnswerTimerStopped;
      expect(state.elapsedTimeMs, -5);
      expect(state.limitMs, -5);
    });
  });
}

class _FakeClock {
  _FakeClock(this.now);

  int now;

  int read() => now;
}
