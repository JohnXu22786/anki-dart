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
 * Source-derived from ReviewReminderGroup.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'review_reminder.dart';
import 'review_reminder_id.dart';

/// A mutable map wrapper for reminders sharing one host-selected scope.
///
/// Map iteration order is incidental. In particular, [getRemindersList] does
/// not promise a stable order matching AnkiDroid's source `HashMap`.
final class ReviewReminderGroup {
  ReviewReminderGroup() : _reminders = {};

  ReviewReminderGroup.fromMap(Map<ReviewReminderId, ReviewReminder> reminders)
    : _reminders = Map.of(reminders);

  ReviewReminderGroup.fromPairs(
    Iterable<MapEntry<ReviewReminderId, ReviewReminder>> pairs,
  ) : _reminders = {for (final pair in pairs) pair.key: pair.value};

  ReviewReminderGroup.fromGroups(Iterable<ReviewReminderGroup> groups)
    : _reminders = {for (final group in groups) ...group._reminders};

  final Map<ReviewReminderId, ReviewReminder> _reminders;

  /// Returns a new group, with [other]'s values replacing colliding keys.
  ReviewReminderGroup operator +(ReviewReminderGroup other) =>
      ReviewReminderGroup.fromGroups([this, other]);

  ReviewReminder? operator [](ReviewReminderId id) => _reminders[id];

  void operator []=(ReviewReminderId id, ReviewReminder reminder) {
    _reminders[id] = reminder;
  }

  bool isEmpty() => _reminders.isEmpty;

  void remove(ReviewReminderId id) {
    _reminders.remove(id);
  }

  /// Calls [action] once for each key and value pair.
  void forEach(
    void Function(MapEntry<ReviewReminderId, ReviewReminder>) action,
  ) {
    _reminders.forEach((id, reminder) => action(MapEntry(id, reminder)));
  }

  /// Returns the reminder values; their order is not a contract.
  List<ReviewReminder> getRemindersList() => _reminders.values.toList();

  /// Toggles an existing reminder. A missing [id] has no effect.
  void toggleEnabled(ReviewReminderId id) {
    final reminder = _reminders[id];
    if (reminder != null) reminder.enabled = !reminder.enabled;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReviewReminderGroup ||
        other._reminders.length != _reminders.length) {
      return false;
    }
    return _reminders.entries.every(
      (entry) => other._reminders[entry.key] == entry.value,
    );
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    _reminders.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

/// Merges a list of groups, with later groups replacing values at shared keys.
extension ReviewReminderGroupListMerge on List<ReviewReminderGroup> {
  /// Merges this list, with later groups replacing values at shared keys.
  ReviewReminderGroup mergeAll() => ReviewReminderGroup.fromGroups(this);
}
