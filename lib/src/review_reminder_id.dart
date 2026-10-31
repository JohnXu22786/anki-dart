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
 * Source-derived from ReviewReminder.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// An identifier assigned to a review reminder.
///
/// Direct construction preserves negative IDs within Kotlin's signed Int range.
final class ReviewReminderId {
  ReviewReminderId(this.value) {
    if (value < _minimumInt32 || value > _maximumInt32) {
      throw ArgumentError.value(
        value,
        'value',
        'ID must be within the signed 32-bit integer range',
      );
    }
  }

  static const _minimumInt32 = -2147483648;
  static const _maximumInt32 = 2147483647;

  final int value;

  /// Plans the source-order allocation from the host's current preference.
  ///
  /// The returned [ReviewReminderIdAllocation] contains the current value as
  /// the allocated ID and the incremented value for the host to persist. This
  /// method does not access preferences or perform persistence itself.
  static ReviewReminderIdAllocation planNextFreeId({
    required int currentNextFreeId,
  }) => ReviewReminderIdAllocation(
    id: ReviewReminderId(currentNextFreeId),
    nextFreeId: currentNextFreeId == _maximumInt32
        ? _minimumInt32
        : currentNextFreeId + 1,
  );

  @override
  bool operator ==(Object other) =>
      other is ReviewReminderId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ReviewReminderId(value=$value)';
}

/// The ordered result of allocating the current reminder ID.
///
/// The host uses [id] for the new reminder and then applies [nextFreeId] to its
/// own preference storage, matching AnkiDroid's read, increment, return order.
final class ReviewReminderIdAllocation {
  const ReviewReminderIdAllocation({
    required this.id,
    required this.nextFreeId,
  });

  final ReviewReminderId id;
  final int nextFreeId;
}

/// Minimum number of due cards required to trigger a review reminder.
final class ReviewReminderCardTriggerThreshold {
  static const zero = ReviewReminderCardTriggerThreshold._(0);

  ReviewReminderCardTriggerThreshold(this.threshold) {
    if (threshold < 0 || threshold > ReviewReminderId._maximumInt32) {
      throw ArgumentError.value(
        threshold,
        'threshold',
        'Card trigger threshold must be >= 0',
      );
    }
  }

  const ReviewReminderCardTriggerThreshold._(this.threshold);

  final int threshold;

  @override
  bool operator ==(Object other) =>
      other is ReviewReminderCardTriggerThreshold &&
      other.threshold == threshold;

  @override
  int get hashCode => threshold.hashCode;

  @override
  String toString() =>
      'ReviewReminderCardTriggerThreshold(threshold=$threshold)';
}
