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
 * Source-derived from ReviewRemindersDatabase.kt and ReviewReminder.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'review_reminder.dart';
import 'review_reminder_delivery.dart';
import 'review_reminder_group.dart';
import 'review_reminder_id.dart';

/// Decides whether a recurring notification attempt should return a reminder.
///
/// The host supplies [checkTime] for the source delivery check and the
/// independently sampled [updatedAtEpochMilliseconds] for a successful
/// reminder update. This function does not read clocks or persist changes. The
/// host still runs its group editor and persistence path after the decision,
/// including when the reminder is missing or the notification was delivered.
ReviewReminder? refreshReviewReminderNotification({
  required ReviewReminderGroup reminders,
  required ReviewReminderId id,
  required DateTime checkTime,
  required int updatedAtEpochMilliseconds,
}) {
  final storedReminder = reminders[id];
  if (storedReminder == null) return null;

  if (wasLatestReviewReminderNotificationDelivered(
    now: checkTime,
    time: storedReminder.time,
    latestNotifTime: DateTime.fromMillisecondsSinceEpoch(
      storedReminder.latestNotifTime,
    ),
  )) {
    return null;
  }

  storedReminder.updateLatestNotifTime(
    currentTimestamp: updatedAtEpochMilliseconds,
  );
  reminders[id] = storedReminder;
  return storedReminder;
}
