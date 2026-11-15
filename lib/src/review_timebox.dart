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
 * SPDX-FileCopyrightText: 2026 Mike Hardy <github@mikehardy.net>
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: Collection.kt, Scheduler.kt, and ReviewerFragment.kt
 * in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

import 'review_session.dart';

/// Headless timebox counter matching the pinned collection behavior.
///
/// The callbacks supply the exact inputs read from AnkiDroid's clock and
/// scheduler adapters. Time is in the integer seconds returned by
/// `Time.intTime()`. The tracker does not read collection storage or update the
/// scheduler itself.
final class ReviewTimeboxTracker {
  ReviewTimeboxTracker({
    required int Function() intTimeSeconds,
    required int Function() timeboxSeconds,
    required int Function() numberOfAnswersRecorded,
  })  : _intTimeSeconds = intTimeSeconds,
        _timeboxSeconds = timeboxSeconds,
        _numberOfAnswersRecorded = numberOfAnswersRecorded;

  final int Function() _intTimeSeconds;
  final int Function() _timeboxSeconds;
  final int Function() _numberOfAnswersRecorded;

  int _startTime = 0;
  int _startReps = 0;

  /// Records the current integer time and scheduler answer count.
  void startTimebox() {
    _startTime = _intTimeSeconds();
    _startReps = _numberOfAnswersRecorded();
  }

  /// Returns the configured limit and answer-count delta after strict expiry.
  ///
  /// A zero limit returns before reading the clock. On expiry, the tracker
  /// restarts from fresh adapter reads, as `Collection.timeboxReached()` does.
  ReviewTimeboxReached? timeboxReached() {
    if (_timeboxSeconds() == 0) return null;

    final elapsed = _intTimeSeconds() - _startTime;
    final limit = _timeboxSeconds();
    if (elapsed > limit) {
      final reached = ReviewTimeboxReached(
        secs: limit,
        reps: _numberOfAnswersRecorded() - _startReps,
      );
      startTimebox();
      return reached;
    }
    return null;
  }
}

/// Converts a timebox's seconds to the rounded minute count used for display.
///
/// This preserves Kotlin's `Float` division and `roundToInt()` ties toward
/// positive infinity. The caller supplies localized text and dialog behavior.
int reviewTimeboxRoundedMinutes(int seconds) {
  final secondsAndMinutes = Float32List(1);
  secondsAndMinutes[0] = seconds.toDouble();
  secondsAndMinutes[0] = secondsAndMinutes[0] / 60.0;
  return (secondsAndMinutes[0] + 0.5).floor();
}
