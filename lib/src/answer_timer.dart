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
 * Behavioral adaptation of AnswerTimer.kt and AnswerTimerState.kt from
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

/// Returns monotonic elapsed-realtime milliseconds, like Android's
/// `SystemClock.elapsedRealtime()`.
typedef ElapsedRealtimeClock = int Function();

/// One of the four states exposed by AnkiDroid's reviewer answer timer.
sealed class AnswerTimerState {
  const AnswerTimerState();
}

/// The answer timer is hidden.
final class AnswerTimerHidden extends AnswerTimerState {
  const AnswerTimerHidden();

  @override
  bool operator ==(Object other) => other is AnswerTimerHidden;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// The timer is running from [baseTime], in elapsed-realtime milliseconds.
final class AnswerTimerRunning extends AnswerTimerState {
  const AnswerTimerRunning({required this.baseTime, required this.limitMs});

  final int baseTime;
  final int limitMs;

  @override
  bool operator ==(Object other) =>
      other is AnswerTimerRunning &&
      other.baseTime == baseTime &&
      other.limitMs == limitMs;

  @override
  int get hashCode => Object.hash(baseTime, limitMs);
}

/// The timer is paused with its accumulated [elapsedTimeMs].
final class AnswerTimerPaused extends AnswerTimerState {
  const AnswerTimerPaused({
    required this.elapsedTimeMs,
    required this.limitMs,
  });

  final int elapsedTimeMs;
  final int limitMs;

  @override
  bool operator ==(Object other) =>
      other is AnswerTimerPaused &&
      other.elapsedTimeMs == elapsedTimeMs &&
      other.limitMs == limitMs;

  @override
  int get hashCode => Object.hash(elapsedTimeMs, limitMs);
}

/// The timer has stopped with its accumulated [elapsedTimeMs].
final class AnswerTimerStopped extends AnswerTimerState {
  const AnswerTimerStopped({
    required this.elapsedTimeMs,
    required this.limitMs,
  });

  final int elapsedTimeMs;
  final int limitMs;

  @override
  bool operator ==(Object other) =>
      other is AnswerTimerStopped &&
      other.elapsedTimeMs == elapsedTimeMs &&
      other.limitMs == limitMs;

  @override
  int get hashCode => Object.hash(elapsedTimeMs, limitMs);
}

/// The answer timer state machine from AnkiDroid's reviewer.
///
/// Call [onPause] and [onResume] from the host lifecycle. [elapsedRealtime]
/// must have the same monotonic millisecond basis as the timer consumer. This
/// class exposes the current state; it does not create a periodic display tick.
class AnswerTimer {
  AnswerTimer({required ElapsedRealtimeClock elapsedRealtime})
      : _elapsedRealtime = elapsedRealtime,
        _stateController = StreamController<AnswerTimerState>.broadcast();

  final ElapsedRealtimeClock _elapsedRealtime;
  final StreamController<AnswerTimerState> _stateController;
  AnswerTimerState _state = const AnswerTimerHidden();

  /// The latest state, initially [AnswerTimerHidden].
  AnswerTimerState get state => _state;

  /// Emits the current state to each listener, then each distinct transition.
  Stream<AnswerTimerState> get stateStream =>
      Stream<AnswerTimerState>.multi((controller) {
        controller.add(_state);
        final subscription = _stateController.stream.listen(controller.add);
        controller.onCancel = subscription.cancel;
      }, isBroadcast: true);

  void _setState(AnswerTimerState state) {
    if (_state == state) return;
    _state = state;
    _stateController.add(state);
  }

  /// Reconfigures the timer for a card, starting it only when [shouldShow].
  void configureForCard({required bool shouldShow, required int limitMs}) {
    if (!shouldShow) {
      _setState(const AnswerTimerHidden());
    } else {
      _setState(AnswerTimerRunning(
        baseTime: _elapsedRealtime(),
        limitMs: limitMs,
      ));
    }
  }

  /// Permanently stops a running or paused timer.
  void stop() {
    switch (_state) {
      case AnswerTimerRunning(:final baseTime, :final limitMs):
        final elapsed = _elapsedRealtime() - baseTime;
        _setState(AnswerTimerStopped(
          elapsedTimeMs: elapsed > limitMs ? limitMs : elapsed,
          limitMs: limitMs,
        ));
      case AnswerTimerPaused(:final elapsedTimeMs, :final limitMs):
        _setState(AnswerTimerStopped(
          elapsedTimeMs: elapsedTimeMs,
          limitMs: limitMs,
        ));
      case AnswerTimerHidden() || AnswerTimerStopped():
        return;
    }
  }

  /// Temporarily pauses a running timer.
  void onPause() {
    final current = _state;
    if (current case AnswerTimerRunning(:final baseTime, :final limitMs)) {
      final elapsed = _elapsedRealtime() - baseTime;
      _setState(AnswerTimerPaused(
        elapsedTimeMs: elapsed > limitMs ? limitMs : elapsed,
        limitMs: limitMs,
      ));
    }
  }

  /// Resumes a paused timer if its limit has not been reached.
  void onResume() {
    final current = _state;
    if (current case AnswerTimerPaused(:final elapsedTimeMs, :final limitMs)) {
      if (elapsedTimeMs < limitMs) {
        _setState(AnswerTimerRunning(
          baseTime: _elapsedRealtime() - elapsedTimeMs,
          limitMs: limitMs,
        ));
      } else {
        _setState(AnswerTimerStopped(
          elapsedTimeMs: elapsedTimeMs,
          limitMs: limitMs,
        ));
      }
    }
  }

  /// Hides the timer from any current state.
  void hide() {
    _setState(const AnswerTimerHidden());
  }
}
