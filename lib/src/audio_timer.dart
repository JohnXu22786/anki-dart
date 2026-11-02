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
 * Behavioral adaptation of AudioTimer.kt from AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

/// A handle returned by a lifecycle-aware [AudioTimerScheduler].
abstract interface class AudioTimerCancellation {
  bool get isActive;

  void cancel();
}

/// The monotonic clock and scheduling boundary owned by the host lifecycle.
///
/// A host can implement this with its lifecycle scope. Disposing that scope
/// should cancel its scheduled work; [AudioTimer] also cancels its own loops
/// when paused, restarted from a duration, or stopped.
abstract interface class AudioTimerScheduler {
  /// Monotonic time from an arbitrary origin, never wall-clock time.
  Duration get elapsed;

  /// Schedules [callback] after [initialDelay] and then every [interval].
  AudioTimerCancellation schedulePeriodic({
    required Duration initialDelay,
    required Duration interval,
    required void Function() callback,
  });
}

/// A standalone scheduler for hosts without a framework lifecycle scheduler.
///
/// Hosts with a lifecycle scope should provide their own
/// [AudioTimerScheduler]. Call [dispose] when this scheduler's owner ends.
final class SystemAudioTimerScheduler implements AudioTimerScheduler {
  SystemAudioTimerScheduler() : _clock = Stopwatch()..start();

  final Stopwatch _clock;
  final Set<_TimerCancellation> _scheduled = {};
  bool _disposed = false;

  @override
  Duration get elapsed => _clock.elapsed;

  @override
  AudioTimerCancellation schedulePeriodic({
    required Duration initialDelay,
    required Duration interval,
    required void Function() callback,
  }) {
    if (_disposed) {
      throw StateError('AudioTimerScheduler has been disposed');
    }
    late final _TimerCancellation cancellation;
    cancellation = _TimerCancellation(
      initialDelay: initialDelay,
      interval: interval,
      callback: callback,
      onCancel: () => _scheduled.remove(cancellation),
    );
    _scheduled.add(cancellation);
    return cancellation;
  }

  /// Cancels all work owned by this scheduler. The scheduler cannot be reused.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final scheduled in _scheduled.toList()) {
      scheduled.cancel();
    }
    _scheduled.clear();
  }
}

final class _TimerCancellation implements AudioTimerCancellation {
  _TimerCancellation({
    required Duration initialDelay,
    required Duration interval,
    required void Function() callback,
    required void Function() onCancel,
  }) : _interval = interval,
       _callback = callback,
       _onCancel = onCancel {
    _timer = Timer(initialDelay, () {
      if (_cancelled) return;
      _callback();
      if (!_cancelled) {
        _timer = Timer.periodic(_interval, (_) => _callback());
      }
    });
  }

  final Duration _interval;
  final void Function() _callback;
  final void Function() _onCancel;
  late Timer _timer;
  bool _cancelled = false;

  @override
  bool get isActive => !_cancelled && _timer.isActive;

  @override
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _timer.cancel();
    _onCancel();
  }
}

/// Tracks elapsed recording time and drives its independent host update loops.
///
/// UI ticks are immediate and repeat every 16 ms; waveform ticks are immediate
/// and repeat every 50 ms. Notification ticks, when requested, first run after
/// one second and then repeat every second. The host owns [scheduler], including
/// its real lifecycle boundary and the consumers of these callbacks.
final class AudioTimer {
  AudioTimer({
    required AudioTimerScheduler scheduler,
    required void Function(Duration elapsed) onTimerTick,
    required void Function() onAudioTick,
    void Function(Duration elapsed)? onNotificationTick,
  }) : _scheduler = scheduler,
       _onTimerTick = onTimerTick,
       _onAudioTick = onAudioTick,
       _onNotificationTick = onNotificationTick;

  static const uiTickInterval = Duration(milliseconds: 16);
  static const waveformTickInterval = Duration(milliseconds: 50);
  static const notificationTickInterval = Duration(seconds: 1);

  final AudioTimerScheduler _scheduler;
  final void Function(Duration elapsed) _onTimerTick;
  final void Function() _onAudioTick;
  final void Function(Duration elapsed)? _onNotificationTick;
  final List<AudioTimerCancellation> _tasks = [];

  Duration _accumulatedDuration = Duration.zero;
  Duration? _sessionStartTime;
  bool _isRunning = false;
  int _runGeneration = 0;

  /// Starts from the accumulated duration, or replaces it with [fromDuration].
  /// Calling without a duration while active is idempotent.
  void start([Duration? fromDuration]) {
    if (fromDuration != null) {
      _cancelRun();
      _accumulatedDuration = fromDuration;
      _sessionStartTime = null;
    } else if (_isRunning) {
      return;
    }

    _isRunning = true;
    final runGeneration = ++_runGeneration;
    _sessionStartTime = _scheduler.elapsed;
    try {
      _onTimerTick(_calculateDuration());
      if (!_isCurrentRun(runGeneration)) return;
      _onAudioTick();
      if (!_isCurrentRun(runGeneration)) return;
      _schedule(runGeneration, _onTimerTickTick, uiTickInterval);
      _schedule(runGeneration, _onAudioTick, waveformTickInterval);
      final notificationTick = _onNotificationTick;
      if (notificationTick != null) {
        _schedule(
          runGeneration,
          () => notificationTick(_calculateDuration()),
          notificationTickInterval,
        );
      }
    } on Object {
      if (_isCurrentRun(runGeneration)) _cancelRun();
      rethrow;
    }
  }

  /// Saves the current total, cancels the loops, and clears the running start.
  void pause() {
    _accumulatedDuration = _calculateDuration();
    _cancelRun();
    _sessionStartTime = null;
  }

  /// Cancels the loops, resets elapsed time, and emits one zero timer tick.
  void stop() {
    _cancelRun();
    _accumulatedDuration = Duration.zero;
    _sessionStartTime = null;
    _onTimerTick(Duration.zero);
  }

  Duration _calculateDuration() {
    final sessionStartTime = _sessionStartTime;
    final currentSession = sessionStartTime == null
        ? Duration.zero
        : _scheduler.elapsed - sessionStartTime;
    return _accumulatedDuration + currentSession;
  }

  void _onTimerTickTick() => _onTimerTick(_calculateDuration());

  bool _isCurrentRun(int runGeneration) =>
      _isRunning && _runGeneration == runGeneration;

  void _schedule(
    int runGeneration,
    void Function() callback,
    Duration interval,
  ) {
    if (!_isCurrentRun(runGeneration)) return;
    _tasks.add(
      _scheduler.schedulePeriodic(
        initialDelay: interval,
        interval: interval,
        callback: () {
          if (!_isCurrentRun(runGeneration)) return;
          try {
            callback();
          } on Object {
            if (_isCurrentRun(runGeneration)) _cancelRun();
            rethrow;
          }
        },
      ),
    );
  }

  void _cancelRun() {
    _runGeneration++;
    _isRunning = false;
    for (final task in _tasks) {
      task.cancel();
    }
    _tasks.clear();
  }
}
