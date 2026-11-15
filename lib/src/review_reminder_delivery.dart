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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-FileCopyrightText: 2025 Eric Li <ericli3690@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ReviewReminder.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'review_reminder_form_state.dart';

/// Returns whether [latestNotifTime] is at or after the most recent scheduled
/// reminder time, following AnkiDroid's local Calendar field behavior.
///
/// The host supplies the local [now]; this function does not read a clock or
/// access notification scheduling. The scheduled time clears seconds while
/// retaining the current millisecond, and moves to the prior calendar day only
/// when today's scheduled time is after [now].
bool wasLatestReviewReminderNotificationDelivered({
  required DateTime now,
  required ReviewReminderTime time,
  required DateTime latestNotifTime,
}) {
  var latestScheduledTimestamp = DateTime(
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
    0,
    now.millisecond,
  );

  if (latestScheduledTimestamp.isAfter(now)) {
    latestScheduledTimestamp = DateTime(
      now.year,
      now.month,
      now.day - 1,
      time.hour,
      time.minute,
      0,
      now.millisecond,
    );
  }

  return latestNotifTime.millisecondsSinceEpoch >=
      latestScheduledTimestamp.millisecondsSinceEpoch;
}
