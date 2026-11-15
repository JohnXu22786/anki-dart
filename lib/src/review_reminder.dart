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
 * SPDX-FileCopyrightText: 2025 Eric Li <ericli3690@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ReviewReminder.kt and ReviewReminderTest.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'review_reminder_form_state.dart';
import 'review_reminder_id.dart';

/// A review reminder's current, in-memory value.
///
/// The host supplies the allocated [id] and epoch-millisecond timestamps. This
/// value does not read a clock or persist changes.
final class ReviewReminder {
  ReviewReminder._({
    required this.id,
    required this.time,
    required this.cardTriggerThreshold,
    required this.scope,
    required this.enabled,
    required this.latestNotifTime,
    required this.profileID,
    required this.onlyNotifyIfNoReviews,
  });

  /// Creates a reminder using an ID and creation timestamp supplied by the host.
  static ReviewReminder createReviewReminder({
    required ReviewReminderId id,
    required ReviewReminderTime time,
    required int latestNotifTime,
    ReviewReminderCardTriggerThreshold cardTriggerThreshold =
        ReviewReminderCardTriggerThreshold.zero,
    ReviewReminderScope scope = const GlobalReminderScope(),
    bool enabled = true,
    String profileID = '',
    bool onlyNotifyIfNoReviews = false,
  }) => ReviewReminder._(
    id: id,
    time: time,
    cardTriggerThreshold: cardTriggerThreshold,
    scope: scope,
    enabled: enabled,
    latestNotifTime: latestNotifTime,
    profileID: profileID,
    onlyNotifyIfNoReviews: onlyNotifyIfNoReviews,
  );

  final ReviewReminderId id;
  final ReviewReminderTime time;
  final ReviewReminderCardTriggerThreshold cardTriggerThreshold;
  final ReviewReminderScope scope;
  bool enabled;
  int latestNotifTime;
  final String profileID;
  final bool onlyNotifyIfNoReviews;

  /// Updates the last notification attempt time to the host-supplied timestamp.
  void updateLatestNotifTime({required int currentTimestamp}) {
    latestNotifTime = currentTimestamp;
  }

  /// The current reminder schema has no migration to perform.
  ReviewReminder migrate() => this;

  @override
  bool operator ==(Object other) =>
      other is ReviewReminder &&
      other.id == id &&
      other.time == time &&
      other.cardTriggerThreshold == cardTriggerThreshold &&
      other.scope == scope &&
      other.enabled == enabled &&
      other.latestNotifTime == latestNotifTime &&
      other.profileID == profileID &&
      other.onlyNotifyIfNoReviews == onlyNotifyIfNoReviews;

  @override
  int get hashCode => Object.hash(
    id,
    time,
    cardTriggerThreshold,
    scope,
    enabled,
    latestNotifTime,
    profileID,
    onlyNotifyIfNoReviews,
  );

  @override
  String toString() =>
      'ReviewReminder(id=$id, time=$time, '
      'cardTriggerThreshold=$cardTriggerThreshold, scope=$scope, '
      'enabled=$enabled, latestNotifTime=$latestNotifTime, '
      'profileID=$profileID, onlyNotifyIfNoReviews=$onlyNotifyIfNoReviews)';
}
