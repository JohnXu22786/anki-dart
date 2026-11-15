/*
 * Copyright (c) 2009 Daniel Svärd daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2009 Daniel Svärd
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:math' show min;

/// Host-neutral state for the review timer fields and methods on AnkiDroid Card.
///
/// The host owns the clock and the card's time limit and supplies both as
/// callbacks. `timeTaken` preserves Kotlin's signed 32-bit narrowing; stop and
/// resume retain the full-width elapsed value.
final class CardReviewTimer {
  CardReviewTimer({this.timerStarted = 0, this.elapsedTime = 0});

  /// The host-clock time at which the current review interval began.
  int timerStarted;

  /// The full-width time accumulated before the current review interval.
  int elapsedTime;

  /// Stores one host-clock reading as the start time.
  void startTimer({required int Function() timeNow}) {
    timerStarted = timeNow();
  }

  /// Returns the signed 32-bit elapsed time, limited by the host's time limit.
  int timeTaken({
    required int Function() timeNow,
    required int Function() timeLimit,
  }) {
    final total = (timeNow() - timerStarted).toSigned(32);
    return min(total, timeLimit());
  }

  /// Stores the full-width elapsed time for a paused review.
  void stopTimer({required int Function() timeNow}) {
    elapsedTime = timeNow() - timerStarted;
  }

  /// Restores the timer start using one host-clock reading and the saved time.
  void resumeTimer({required int Function() timeNow}) {
    timerStarted = timeNow() - elapsedTime;
  }
}
