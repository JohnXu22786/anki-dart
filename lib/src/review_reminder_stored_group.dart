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
 * Source-derived from ReviewRemindersDatabase.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'dart:convert';

import 'review_reminder_schema_migration.dart';

/// The serialized storage envelope for a reminder map.
///
/// The map stays a JSON string so its schema can be decoded separately using
/// [version]. Storage access and schema migration remain the host's concern.
final class StoredReviewReminderGroup {
  const StoredReviewReminderGroup({
    required this.version,
    required this.remindersMapJson,
  });

  /// Decodes the two required fields from AnkiDroid's stored JSON envelope.
  factory StoredReviewReminderGroup.fromJsonString(String serializedString) {
    final json = jsonDecode(serializedString) as Map<String, dynamic>;
    if (json.keys.any((key) => key != 'version' && key != 'remindersMapJson')) {
      throw const FormatException('Unexpected stored reminder group field');
    }
    return StoredReviewReminderGroup(
      version: ReviewReminderSchemaVersion(json['version'] as int),
      remindersMapJson: json['remindersMapJson'] as String,
    );
  }

  /// The schema version of [remindersMapJson].
  final ReviewReminderSchemaVersion version;

  /// The reminder map encoded as its own JSON string.
  final String remindersMapJson;

  /// Encodes the envelope in source field order and with source field names.
  String serializeToString() => jsonEncode({
    'version': version.value,
    'remindersMapJson': remindersMapJson,
  });

  @override
  bool operator ==(Object other) =>
      other is StoredReviewReminderGroup &&
      other.version == version &&
      other.remindersMapJson == remindersMapJson;

  @override
  int get hashCode => Object.hash(version, remindersMapJson);
}
