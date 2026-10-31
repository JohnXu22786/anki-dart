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
 * Source-derived from ReviewReminderGroup.kt, ReviewReminder.kt, and
 * ReviewReminderSchema.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:convert';

import 'review_reminder.dart';
import 'review_reminder_id.dart';
import 'review_reminder_form_state.dart';
import 'review_reminder_schema_migration.dart';

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

  /// Decodes the current-schema reminder map from AnkiDroid's JSON string.
  ///
  /// Malformed JSON and values that do not match the source schema throw;
  /// database-level recovery and logging remain the caller's responsibility.
  ReviewReminderGroup.fromJsonString(String serializedString)
    : _reminders = _decodeReminderMap(serializedString);

  final Map<ReviewReminderId, ReviewReminder> _reminders;

  /// Encodes this group's reminders using AnkiDroid's current JSON schema.
  String serializeToString() => jsonEncode({
    for (final entry in _reminders.entries)
      entry.key.value.toString(): _reminderToJson(entry.value),
  });

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

const _globalScopeType =
    'com.ichi2.anki.reviewreminders.ReviewReminderScope.Global';
const _deckSpecificScopeType =
    'com.ichi2.anki.reviewreminders.ReviewReminderScope.DeckSpecific';

/// Encodes and decodes the V1 reminder map stored for schema migrations.
///
/// Map keys are decimal reminder IDs. Each schema value retains its own ID,
/// matching the source serializer; the migration runner handles re-keying.
abstract final class ReviewReminderSchemaV1MapCodec {
  static Map<ReviewReminderId, ReviewReminderSchemaV1> decode(String json) =>
      _decodeSchemaMap(json, _schemaV1FromJson);

  static String encode(Map<ReviewReminderId, ReviewReminderSchemaV1> schemas) =>
      _encodeSchemaMap(schemas, _schemaV1ToJson);
}

/// Encodes and decodes the V2 reminder map stored for schema migrations.
///
/// Map keys are decimal reminder IDs. Each schema value retains its own ID,
/// matching the source serializer; the migration runner handles re-keying.
abstract final class ReviewReminderSchemaV2MapCodec {
  static Map<ReviewReminderId, ReviewReminderSchemaV2> decode(String json) =>
      _decodeSchemaMap(json, _schemaV2FromJson);

  static String encode(Map<ReviewReminderId, ReviewReminderSchemaV2> schemas) =>
      _encodeSchemaMap(schemas, _schemaV2ToJson);
}

Map<ReviewReminderId, ReviewReminder> _decodeReminderMap(String json) {
  final decoded = jsonDecode(json) as Map<String, dynamic>;
  return {
    for (final entry in decoded.entries)
      ReviewReminderId(int.parse(entry.key)): _reminderFromJson(
        entry.value as Map<String, dynamic>,
      ),
  };
}

ReviewReminder _reminderFromJson(Map<String, dynamic> json) {
  _requireJsonKeys(json, const {
    'id',
    'time',
    'cardTriggerThreshold',
    'scope',
    'enabled',
    'latestNotifTime',
    'profileID',
    'onlyNotifyIfNoReviews',
  });
  final time = json['time'] as Map<String, dynamic>;
  _requireJsonKeys(time, const {'hour', 'minute'});

  return ReviewReminder.createReviewReminder(
    id: ReviewReminderId(_int32(json['id'])),
    time: ReviewReminderTime(
      hour: _int32(time['hour']),
      minute: _int32(time['minute']),
    ),
    cardTriggerThreshold: ReviewReminderCardTriggerThreshold(
      _int32(json['cardTriggerThreshold']),
    ),
    scope: _scopeFromJson(json['scope'] as Map<String, dynamic>),
    enabled: json['enabled'] as bool,
    latestNotifTime: _int64(json['latestNotifTime']),
    profileID: json['profileID'] as String,
    onlyNotifyIfNoReviews: json['onlyNotifyIfNoReviews'] as bool,
  );
}

ReviewReminderScope _globalScopeFromJson(Map<String, dynamic> json) {
  _requireJsonKeys(json, const {'type'});
  return const GlobalReminderScope();
}

ReviewReminderScope _deckSpecificScopeFromJson(Map<String, dynamic> json) {
  _requireJsonKeys(json, const {'type', 'did'});
  return DeckSpecificReminderScope(_int64(json['did']));
}

Map<String, Object?> _reminderToJson(ReviewReminder reminder) => {
  'id': reminder.id.value,
  'time': {'hour': reminder.time.hour, 'minute': reminder.time.minute},
  'cardTriggerThreshold': reminder.cardTriggerThreshold.threshold,
  'scope': _scopeToJson(reminder.scope),
  'enabled': reminder.enabled,
  'latestNotifTime': reminder.latestNotifTime,
  'profileID': reminder.profileID,
  'onlyNotifyIfNoReviews': reminder.onlyNotifyIfNoReviews,
};

Map<ReviewReminderId, T> _decodeSchemaMap<T>(
  String json,
  T Function(Map<String, dynamic>) decodeValue,
) {
  final decoded = jsonDecode(json) as Map<String, dynamic>;
  return {
    for (final entry in decoded.entries)
      ReviewReminderId(int.parse(entry.key)): decodeValue(
        entry.value as Map<String, dynamic>,
      ),
  };
}

String _encodeSchemaMap<T>(
  Map<ReviewReminderId, T> schemas,
  Map<String, Object?> Function(T) encodeValue,
) => jsonEncode({
  for (final entry in schemas.entries)
    entry.key.value.toString(): encodeValue(entry.value),
});

ReviewReminderSchemaV1 _schemaV1FromJson(Map<String, dynamic> json) {
  _requireJsonKeys(
    json,
    const {
      'id',
      'time',
      'cardTriggerThreshold',
      'scope',
      'enabled',
      'profileID',
    },
    optional: const {'onlyNotifyIfNoReviews'},
  );
  final time = json['time'] as Map<String, dynamic>;
  _requireJsonKeys(time, const {'hour', 'minute'});

  return ReviewReminderSchemaV1(
    id: ReviewReminderId(_int32(json['id'])),
    time: ReviewReminderTime(
      hour: _int32(time['hour']),
      minute: _int32(time['minute']),
    ),
    cardTriggerThreshold: ReviewReminderCardTriggerThreshold(
      _int32(json['cardTriggerThreshold']),
    ),
    scope: _scopeFromJson(json['scope'] as Map<String, dynamic>),
    enabled: json['enabled'] as bool,
    profileID: json['profileID'] as String,
    onlyNotifyIfNoReviews: json.containsKey('onlyNotifyIfNoReviews')
        ? json['onlyNotifyIfNoReviews'] as bool
        : false,
  );
}

ReviewReminderSchemaV2 _schemaV2FromJson(Map<String, dynamic> json) {
  _requireJsonKeys(json, const {
    'id',
    'time',
    'cardTriggerThreshold',
    'scope',
    'enabled',
    'profileID',
    'onlyNotifyIfNoReviews',
  });
  final time = json['time'] as Map<String, dynamic>;
  _requireJsonKeys(time, const {'hour', 'minute'});

  return ReviewReminderSchemaV2(
    id: ReviewReminderId(_int32(json['id'])),
    time: ReviewReminderTime(
      hour: _int32(time['hour']),
      minute: _int32(time['minute']),
    ),
    cardTriggerThreshold: ReviewReminderCardTriggerThreshold(
      _int32(json['cardTriggerThreshold']),
    ),
    scope: _scopeFromJson(json['scope'] as Map<String, dynamic>),
    enabled: json['enabled'] as bool,
    profileID: json['profileID'] as String,
    onlyNotifyIfNoReviews: json['onlyNotifyIfNoReviews'] as bool,
  );
}

Map<String, Object?> _schemaV1ToJson(ReviewReminderSchemaV1 schema) => {
  'id': schema.id.value,
  'time': {'hour': schema.time.hour, 'minute': schema.time.minute},
  'cardTriggerThreshold': schema.cardTriggerThreshold.threshold,
  'scope': _scopeToJson(schema.scope),
  'enabled': schema.enabled,
  'profileID': schema.profileID,
  if (schema.onlyNotifyIfNoReviews) 'onlyNotifyIfNoReviews': true,
};

Map<String, Object?> _schemaV2ToJson(ReviewReminderSchemaV2 schema) => {
  'id': schema.id.value,
  'time': {'hour': schema.time.hour, 'minute': schema.time.minute},
  'cardTriggerThreshold': schema.cardTriggerThreshold.threshold,
  'scope': _scopeToJson(schema.scope),
  'enabled': schema.enabled,
  'profileID': schema.profileID,
  'onlyNotifyIfNoReviews': schema.onlyNotifyIfNoReviews,
};

ReviewReminderScope _scopeFromJson(Map<String, dynamic> json) =>
    switch (json['type'] as String) {
      _globalScopeType => _globalScopeFromJson(json),
      _deckSpecificScopeType => _deckSpecificScopeFromJson(json),
      _ => throw FormatException('Unknown review reminder scope type'),
    };

Map<String, Object?> _scopeToJson(ReviewReminderScope scope) => switch (scope) {
  GlobalReminderScope() => {'type': _globalScopeType},
  DeckSpecificReminderScope(:final deckId) => {
    'type': _deckSpecificScopeType,
    'did': deckId,
  },
};

int _int32(Object? value) {
  final number = value as int;
  if (number < -2147483648 || number > 2147483647) {
    throw FormatException('Expected a signed 32-bit integer');
  }
  return number;
}

int _int64(Object? value) {
  final number = value as int;
  if (number < -9223372036854775808 || number > 9223372036854775807) {
    throw FormatException('Expected a signed 64-bit integer');
  }
  return number;
}

void _requireJsonKeys(
  Map<String, dynamic> json,
  Set<String> required, {
  Set<String> optional = const {},
}) {
  final allowed = {...required, ...optional};
  if (!json.keys.every(allowed.contains) || !required.every(json.containsKey)) {
    throw FormatException('JSON fields do not match the reminder schema');
  }
}

/// Merges a list of groups, with later groups replacing values at shared keys.
extension ReviewReminderGroupListMerge on List<ReviewReminderGroup> {
  /// Merges this list, with later groups replacing values at shared keys.
  ReviewReminderGroup mergeAll() => ReviewReminderGroup.fromGroups(this);
}
