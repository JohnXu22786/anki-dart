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
 * SPDX-FileCopyrightText: 2026 Eric Li <ericli3690@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ReviewReminderSchema.kt and ReviewReminder.kt in
 * AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'review_reminder_form_state.dart';
import 'review_reminder_id.dart';

/// A review reminder schema version.
///
/// The host owns the schema registry and serialized storage.
final class ReviewReminderSchemaVersion {
  static const _maximumInt32 = 2147483647;

  ReviewReminderSchemaVersion(this.value) {
    if (value < 1 || value > _maximumInt32) {
      throw ArgumentError.value(
        value,
        'value',
        'Review reminder schema version must fit a positive signed 32-bit integer',
      );
    }
  }

  final int value;

  @override
  bool operator ==(Object other) =>
      other is ReviewReminderSchemaVersion && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ReviewReminderSchemaVersion(value=$value)';
}

/// Version 1 of the source reminder schema.
///
/// The source declares [onlyNotifyIfNoReviews] here with a `false` default,
/// despite the version comment describing it as added in V2.
final class ReviewReminderSchemaV1 {
  ReviewReminderSchemaV1({
    required this.id,
    required this.time,
    required this.cardTriggerThreshold,
    required this.scope,
    required this.enabled,
    required this.profileID,
    this.onlyNotifyIfNoReviews = false,
  });

  final ReviewReminderId id;
  final ReviewReminderTime time;
  final ReviewReminderCardTriggerThreshold cardTriggerThreshold;
  final ReviewReminderScope scope;
  bool enabled;
  final String profileID;
  final bool onlyNotifyIfNoReviews;

  /// Copies the V1 fields into V2 in source migration order.
  ReviewReminderSchemaV2 migrate() => ReviewReminderSchemaV2(
    id: id,
    time: time,
    cardTriggerThreshold: cardTriggerThreshold,
    scope: scope,
    enabled: enabled,
    profileID: profileID,
    onlyNotifyIfNoReviews: onlyNotifyIfNoReviews,
  );

  @override
  bool operator ==(Object other) =>
      other is ReviewReminderSchemaV1 &&
      other.id == id &&
      other.time == time &&
      other.cardTriggerThreshold == cardTriggerThreshold &&
      other.scope == scope &&
      other.enabled == enabled &&
      other.profileID == profileID &&
      other.onlyNotifyIfNoReviews == onlyNotifyIfNoReviews;

  @override
  int get hashCode => Object.hash(
    id,
    time,
    cardTriggerThreshold,
    scope,
    enabled,
    profileID,
    onlyNotifyIfNoReviews,
  );
}

/// Version 2 of the source reminder schema.
final class ReviewReminderSchemaV2 {
  ReviewReminderSchemaV2({
    required this.id,
    required this.time,
    required this.cardTriggerThreshold,
    required this.scope,
    required this.enabled,
    required this.profileID,
    required this.onlyNotifyIfNoReviews,
  });

  final ReviewReminderId id;
  final ReviewReminderTime time;
  final ReviewReminderCardTriggerThreshold cardTriggerThreshold;
  final ReviewReminderScope scope;
  bool enabled;
  final String profileID;
  final bool onlyNotifyIfNoReviews;

  /// Projects V2 into the current reminder fields.
  ///
  /// [id] and [latestNotifTime] are supplied by the host where the source
  /// factory allocates an ID and reads the current time. This method performs
  /// neither operation.
  ReviewReminderCurrentProjection migrate({
    required ReviewReminderId id,
    required int latestNotifTime,
  }) => ReviewReminderCurrentProjection(
    id: id,
    time: time,
    cardTriggerThreshold: cardTriggerThreshold,
    scope: scope,
    enabled: enabled,
    latestNotifTime: latestNotifTime,
    profileID: profileID,
    onlyNotifyIfNoReviews: onlyNotifyIfNoReviews,
  );

  @override
  bool operator ==(Object other) =>
      other is ReviewReminderSchemaV2 &&
      other.id == id &&
      other.time == time &&
      other.cardTriggerThreshold == cardTriggerThreshold &&
      other.scope == scope &&
      other.enabled == enabled &&
      other.profileID == profileID &&
      other.onlyNotifyIfNoReviews == onlyNotifyIfNoReviews;

  @override
  int get hashCode => Object.hash(
    id,
    time,
    cardTriggerThreshold,
    scope,
    enabled,
    profileID,
    onlyNotifyIfNoReviews,
  );
}

/// The current reminder fields produced by migrating a V2 schema.
///
/// Hosts wrap this projection in their runtime type and provide persistence and
/// future version migration behavior.
final class ReviewReminderCurrentProjection {
  const ReviewReminderCurrentProjection({
    required this.id,
    required this.time,
    required this.cardTriggerThreshold,
    required this.scope,
    required this.enabled,
    required this.latestNotifTime,
    required this.profileID,
    required this.onlyNotifyIfNoReviews,
  });

  final ReviewReminderId id;
  final ReviewReminderTime time;
  final ReviewReminderCardTriggerThreshold cardTriggerThreshold;
  final ReviewReminderScope scope;
  final bool enabled;
  final int latestNotifTime;
  final String profileID;
  final bool onlyNotifyIfNoReviews;
}
