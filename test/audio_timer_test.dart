/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: AudioTimer.kt and AudioTimerTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AudioTimer', () {
    test(
      'UI and waveform callbacks start immediately on separate cadences',
      () {
        final scheduler = _FakeAudioTimerScheduler();
        final timerTicks = <Duration>[];
        var audioTicks = 0;
        final timer = AudioTimer(
          scheduler: scheduler,
          onTimerTick: timerTicks.add,
          onAudioTick: () => audioTicks++,
        );

        timer.start();
        expect(timerTicks, [Duration.zero]);
        expect(audioTicks, 1);
        expect(scheduler.intervals, [
          const Duration(milliseconds: 16),
          const Duration(milliseconds: 50),
        ]);

        scheduler.advance(const Duration(milliseconds: 50));
        expect(timerTicks, hasLength(4));
        expect(audioTicks, 2);
        expect(timerTicks.last, const Duration(milliseconds: 48));
      },
    );

    test('UI waits a full interval after callback work completes', () {
      final scheduler = _FakeAudioTimerScheduler();
      final timerTicks = <Duration>[];
      var consumedCallbackTime = false;
      final timer = AudioTimer(
        scheduler: scheduler,
        onTimerTick: (tick) {
          timerTicks.add(tick);
          if (!consumedCallbackTime &&
              tick == const Duration(milliseconds: 16)) {
            consumedCallbackTime = true;
            scheduler.consume(const Duration(milliseconds: 20));
          }
        },
        onAudioTick: () {},
      );

      timer.start();
      scheduler.advance(const Duration(milliseconds: 51));
      expect(timerTicks, hasLength(2));
      scheduler.advance(const Duration(milliseconds: 1));
      expect(timerTicks, hasLength(3));
      expect(timerTicks.last, const Duration(milliseconds: 52));
    });

    test('waveform waits a full interval after callback work completes', () {
      final scheduler = _FakeAudioTimerScheduler();
      var audioTicks = 0;
      final timer = AudioTimer(
        scheduler: scheduler,
        onTimerTick: (_) {},
        onAudioTick: () {
          audioTicks++;
          if (audioTicks == 2) {
            scheduler.consume(const Duration(milliseconds: 75));
          }
        },
      );

      timer.start();
      scheduler.advance(const Duration(milliseconds: 174));
      expect(audioTicks, 2);
      scheduler.advance(const Duration(milliseconds: 1));
      expect(audioTicks, 3);
    });

    test(
      'notification waits a full interval after callback work completes',
      () {
        final scheduler = _FakeAudioTimerScheduler();
        var notificationTicks = 0;
        final timer = AudioTimer(
          scheduler: scheduler,
          onTimerTick: (_) {},
          onAudioTick: () {},
          onNotificationTick: (_) {
            notificationTicks++;
            if (notificationTicks == 1) {
              scheduler.consume(const Duration(milliseconds: 1500));
            }
          },
        );

        timer.start();
        scheduler.advance(const Duration(milliseconds: 3499));
        expect(notificationTicks, 1);
        scheduler.advance(const Duration(milliseconds: 1));
        expect(notificationTicks, 2);
      },
    );

    test('first notification waits after immediate UI and waveform ticks', () {
      final scheduler = _FakeAudioTimerScheduler();
      final notificationTicks = <Duration>[];
      var initialWaveTick = true;
      final timer = AudioTimer(
        scheduler: scheduler,
        onTimerTick: (tick) {
          if (tick == Duration.zero) {
            scheduler.consume(const Duration(milliseconds: 100));
          }
        },
        onAudioTick: () {
          if (initialWaveTick) {
            initialWaveTick = false;
            scheduler.consume(const Duration(milliseconds: 200));
          }
        },
        onNotificationTick: notificationTicks.add,
      );

      timer.start();
      scheduler.advance(const Duration(milliseconds: 999));
      expect(notificationTicks, isEmpty);
      scheduler.advance(const Duration(milliseconds: 1));
      expect(notificationTicks, [const Duration(milliseconds: 1300)]);
    });

    test('notification callback waits one second before repeating', () {
      final scheduler = _FakeAudioTimerScheduler();
      final notificationTicks = <Duration>[];
      final timer = AudioTimer(
        scheduler: scheduler,
        onTimerTick: (_) {},
        onAudioTick: () {},
        onNotificationTick: notificationTicks.add,
      );

      timer.start();
      expect(notificationTicks, isEmpty);
      scheduler.advance(const Duration(milliseconds: 999));
      expect(notificationTicks, isEmpty);
      scheduler.advance(const Duration(milliseconds: 1));
      expect(notificationTicks, [const Duration(seconds: 1)]);
      scheduler.advance(const Duration(seconds: 2));
      expect(notificationTicks, [
        const Duration(seconds: 1),
        const Duration(seconds: 2),
        const Duration(seconds: 3),
      ]);
    });

    test('duration is monotonic and combines accumulated and session time', () {
      final scheduler = _FakeAudioTimerScheduler();
      final timerTicks = <Duration>[];
      final timer = AudioTimer(
        scheduler: scheduler,
        onTimerTick: timerTicks.add,
        onAudioTick: () {},
      );

      timer.start();
      scheduler.advance(const Duration(milliseconds: 2016));
      timer.pause();
      scheduler.advance(const Duration(seconds: 5));
      timer.start();
      scheduler.advance(const Duration(milliseconds: 1008));

      expect(timerTicks.last, const Duration(milliseconds: 3024));
    });

    test('reentrant pause during start does not install stale loops', () {
      final scheduler = _FakeAudioTimerScheduler();
      final timerTicks = <Duration>[];
      var audioTicks = 0;
      var pauseOnFirstTick = true;
      late final AudioTimer timer;
      timer = AudioTimer(
        scheduler: scheduler,
        onTimerTick: (tick) {
          timerTicks.add(tick);
          if (pauseOnFirstTick) {
            pauseOnFirstTick = false;
            timer.pause();
          }
        },
        onAudioTick: () => audioTicks++,
      );

      timer.start();
      expect(timerTicks, [Duration.zero]);
      expect(audioTicks, 0);
      scheduler.advance(const Duration(seconds: 1));
      expect(timerTicks, [Duration.zero]);
      expect(scheduler.intervals, isEmpty);

      timer.start();
      scheduler.advance(const Duration(milliseconds: 50));
      expect(timerTicks, hasLength(5));
      expect(audioTicks, 2);
      expect(scheduler.intervals, hasLength(2));
    });

    test('start while active does not create duplicate loops', () {
      final scheduler = _FakeAudioTimerScheduler();
      final timerTicks = <Duration>[];
      var audioTicks = 0;
      final timer = AudioTimer(
        scheduler: scheduler,
        onTimerTick: timerTicks.add,
        onAudioTick: () => audioTicks++,
      );

      timer.start();
      timer.start();
      scheduler.advance(const Duration(milliseconds: 50));

      expect(timerTicks, hasLength(4));
      expect(audioTicks, 2);
      expect(scheduler.intervals, hasLength(2));
    });

    test(
      'pause captures time without ticking and resume excludes pause time',
      () {
        final scheduler = _FakeAudioTimerScheduler();
        final timerTicks = <Duration>[];
        final timer = AudioTimer(
          scheduler: scheduler,
          onTimerTick: timerTicks.add,
          onAudioTick: () {},
        );

        timer.start();
        scheduler.advance(const Duration(milliseconds: 2016));
        final tickCount = timerTicks.length;
        timer.pause();
        expect(timerTicks, hasLength(tickCount));
        scheduler.advance(const Duration(seconds: 5));
        timer.start();
        scheduler.advance(const Duration(milliseconds: 1008));

        expect(timerTicks.last, const Duration(milliseconds: 3024));
      },
    );

    test('custom duration replaces the active run and immediately ticks', () {
      final scheduler = _FakeAudioTimerScheduler();
      final timerTicks = <Duration>[];
      var audioTicks = 0;
      final timer = AudioTimer(
        scheduler: scheduler,
        onTimerTick: timerTicks.add,
        onAudioTick: () => audioTicks++,
      );

      timer.start();
      scheduler.advance(const Duration(milliseconds: 10));
      timer.start(const Duration(seconds: 50));
      expect(timerTicks.last, const Duration(seconds: 50));
      expect(audioTicks, 2);
      scheduler.advance(const Duration(milliseconds: 16));
      expect(timerTicks.last, const Duration(seconds: 50, milliseconds: 16));
      expect(timerTicks, hasLength(3));
    });

    test('stop cancels loops and invokes exactly one zero callback', () {
      final scheduler = _FakeAudioTimerScheduler();
      final timerTicks = <Duration>[];
      var audioTicks = 0;
      final timer = AudioTimer(
        scheduler: scheduler,
        onTimerTick: timerTicks.add,
        onAudioTick: () => audioTicks++,
      );

      timer.start();
      scheduler.advance(const Duration(milliseconds: 20));
      final tickCountBeforeStop = timerTicks.length;
      timer.stop();
      expect(timerTicks.last, Duration.zero);
      expect(timerTicks, hasLength(tickCountBeforeStop + 1));
      final tickCount = timerTicks.length;
      final audioTickCount = audioTicks;
      scheduler.advance(const Duration(seconds: 1));
      expect(timerTicks, hasLength(tickCount));
      expect(audioTicks, audioTickCount);
      expect(timerTicks.skip(tickCountBeforeStop), [Duration.zero]);
    });
  });
}

class _FakeAudioTimerScheduler implements AudioTimerScheduler {
  Duration _now = Duration.zero;
  final List<_ScheduledTick> _scheduled = [];

  @override
  Duration get elapsed => _now;

  List<Duration> get intervals => _scheduled
      .where((tick) => tick.isActive)
      .map((tick) => tick.interval)
      .toList();

  @override
  AudioTimerCancellation schedule({
    required Duration delay,
    required void Function() callback,
  }) {
    final tick = _ScheduledTick(
      dueAt: _now + delay,
      interval: delay,
      callback: callback,
    );
    _scheduled.add(tick);
    return tick;
  }

  void consume(Duration amount) => _now += amount;

  void advance(Duration amount) {
    final target = _now + amount;
    while (true) {
      final next = _scheduled
          .where((tick) => tick.isActive && tick.dueAt <= target)
          .fold<_ScheduledTick?>(
            null,
            (earliest, tick) => earliest == null || tick.dueAt < earliest.dueAt
                ? tick
                : earliest,
          );
      if (next == null) break;
      if (next.dueAt > _now) _now = next.dueAt;
      next.callback();
      if (next.isActive) next.cancel();
    }
    if (target > _now) _now = target;
  }
}

class _ScheduledTick implements AudioTimerCancellation {
  _ScheduledTick({
    required this.dueAt,
    required this.interval,
    required this.callback,
  });

  Duration dueAt;
  final Duration interval;
  final void Function() callback;
  bool _active = true;

  @override
  bool get isActive => _active;

  @override
  void cancel() => _active = false;
}
