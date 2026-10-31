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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ReminderLogTree.kt, ByteArray.kt, and StringUtils.kt in
 * AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Android [Log.INFO], [Log.WARN], [Log.ERROR], and [Log.ASSERT] priorities.
const int reminderLogInfoPriority = 4;
const int reminderLogWarnPriority = 5;
const int reminderLogErrorPriority = 6;
const int reminderLogAssertPriority = 7;

/// Maximum line-message length before the host's grapheme-aware ellipsizer runs.
const int reminderLogMaxLineLength = 2 * 1024;

/// File size at which AnkiDroid trims a reminder log.
const int reminderLogTrimTriggerBytes = reminderLogTrimTargetBytes * 3 ~/ 2;

/// File size the reminder log keeps as its trim target.
const int reminderLogTrimTargetBytes = 24 * 1024;

/// An ellipsizer supplied by the host to preserve platform Unicode behavior.
typedef ReminderLogEllipsizer = String Function(String text, int maxLength);

/// Whether Android's reminder log tree accepts [priority].
bool isReminderLoggable(int priority) => priority >= reminderLogInfoPriority;

/// Formats the source prefix for an optional reminder [id].
String reminderLogPrefix([int? id]) =>
    id == null ? '[Reminders]' : '[Reminders:$id]';

/// Returns the source log-level character for an Android log [priority].
String reminderLogLevelCharacter(int priority) => switch (priority) {
  reminderLogInfoPriority => 'I',
  reminderLogWarnPriority => 'W',
  reminderLogErrorPriority || reminderLogAssertPriority => 'E',
  _ => 'X',
};

/// Projects a marked log [message] to one persisted line, or null if its exact
/// source header is absent. [timestamp] and [ellipsize] are provided by the host.
String? formatReminderLogLine({
  required String timestamp,
  required int priority,
  required String message,
  required ReminderLogEllipsizer ellipsize,
}) {
  final header = RegExp(
    r'^\[Reminders(?::([0-9]+))?\] ?',
  ).matchAsPrefix(message);
  if (header == null) return null;

  final id = header.group(1) ?? '--';
  final escapedMessage = message.substring(header.end).replaceAll('\n', r'\n');
  final truncatedMessage = ellipsize(escapedMessage, reminderLogMaxLineLength);
  return '$timestamp ${reminderLogLevelCharacter(priority)} #$id '
      '$truncatedMessage\n';
}

/// Finds the first LF byte at or after [fromIndex], clamping negative indices
/// to zero. Returns null if no such byte exists.
int? indexOfNewlineAtOrAfter(List<int> bytes, int fromIndex) {
  final start = fromIndex < 0 ? 0 : fromIndex;
  for (var index = start; index < bytes.length; index++) {
    if (bytes[index] == 0x0a) return index;
  }
  return null;
}

/// Projects AnkiDroid's trim operation: below the trigger, retain all bytes;
/// at or above it, drop through the first newline at/after the target offset.
/// If no newline exists, the source discards the entire existing log.
List<int> trimReminderLogBytes(List<int> bytes) {
  if (bytes.length < reminderLogTrimTriggerBytes) return bytes;

  final targetOffset = bytes.length - reminderLogTrimTargetBytes;
  final newline = indexOfNewlineAtOrAfter(bytes, targetOffset);
  return bytes.sublist(newline == null ? bytes.length : newline + 1);
}
