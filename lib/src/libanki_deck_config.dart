/*
 * Copyright (c) 2020 David Allison <davidallisongithub@gmail.com>
 * Copyright (c) 2020 Arthur Milchior <Arthur@Milchior.fr>
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
 * SPDX-FileCopyrightText: 2020 David Allison <davidallisongithub@gmail.com>
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <Arthur@Milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from DeckConfig.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'json_container.dart';

/// Host-owned JSONObject operations used by the DeckConfig JSON model.
///
/// Android JSON parsing, typed reads/writes, nested object and array creation,
/// logging, equality, hashing, and string conversion remain host-owned.
final class LibAnkiDeckConfigJsonCallbacks {
  const LibAnkiDeckConfigJsonCallbacks({
    required this.getInt,
    required this.getLong,
    required this.getString,
    required this.getBoolean,
    required this.optBoolean,
    required this.optDouble,
    required this.getDouble,
    required this.getJsonArray,
    required this.getJsonObject,
    required this.put,
    required this.remove,
    required this.logWarning,
    required this.parseJsonObjectString,
    required this.jsonObjectEquals,
    required this.jsonObjectHashCode,
    required this.jsonObjectToString,
  });

  final int Function(Object jsonObject, String key) getInt;
  final int Function(Object jsonObject, String key) getLong;
  final String Function(Object jsonObject, String key) getString;
  final bool Function(Object jsonObject, String key) getBoolean;
  final bool Function(Object jsonObject, String key, bool defaultValue)
  optBoolean;
  final double Function(Object jsonObject, String key, double defaultValue)
  optDouble;
  final double Function(Object jsonObject, String key) getDouble;
  final Object Function(Object jsonObject, String key) getJsonArray;
  final Object Function(Object jsonObject, String key) getJsonObject;
  final void Function(Object jsonObject, String key, Object? value) put;
  final void Function(Object jsonObject, String key) remove;
  final void Function(Exception failure) logWarning;
  final Object Function(String jsonString) parseJsonObjectString;
  final bool Function(Object left, Object right) jsonObjectEquals;
  final int Function(Object jsonObject) jsonObjectHashCode;
  final String Function(Object jsonObject) jsonObjectToString;
}

/// Portable form of AnkiDroid's JSON-backed `DeckConfig`.
///
/// [newConfig] corresponds to the Kotlin `new` property, whose name is a Dart
/// keyword. JSONObject construction, parsing, access, and failure behavior are
/// supplied by [callbacks].
final class LibAnkiDeckConfig implements JSONObjectHolder {
  const LibAnkiDeckConfig({required this.jsonObject, required this.callbacks});

  /// Parses [jsonString] once using the host parser and retains its exact object.
  factory LibAnkiDeckConfig.fromJsonString({
    required String jsonString,
    required LibAnkiDeckConfigJsonCallbacks callbacks,
  }) => LibAnkiDeckConfig(
    jsonObject: callbacks.parseJsonObjectString(jsonString),
    callbacks: callbacks,
  );

  @override
  final Object jsonObject;

  final LibAnkiDeckConfigJsonCallbacks callbacks;

  /// The config identifier, stored at source key `cong`.
  int get conf => callbacks.getLong(jsonObject, 'cong');

  set conf(int value) => callbacks.put(jsonObject, 'cong', value);

  /// Unique config identifier, stored at key `id`.
  int get id => callbacks.getLong(jsonObject, 'id');

  set id(int value) => callbacks.put(jsonObject, 'id', value);

  String get name => callbacks.getString(jsonObject, 'name');

  set name(String value) => callbacks.put(jsonObject, 'name', value);

  bool get waitForAudio =>
      callbacks.optBoolean(jsonObject, 'waitForAudio', true);

  /// Removes the answer action value so the host can apply its default.
  void removeAnswerAction() => callbacks.remove(jsonObject, ANSWER_ACTION);

  bool get stopTimerOnAnswer =>
      callbacks.getBoolean(jsonObject, 'stopTimerOnAnswer');

  double get secondsToShowQuestion =>
      callbacks.optDouble(jsonObject, 'secondsToShowQuestion', 0.0);

  set secondsToShowQuestion(double value) =>
      callbacks.put(jsonObject, 'secondsToShowQuestion', value);

  double get secondsToShowAnswer =>
      callbacks.optDouble(jsonObject, 'secondsToShowAnswer', 0.0);

  set secondsToShowAnswer(double value) =>
      callbacks.put(jsonObject, 'secondsToShowAnswer', value);

  /// Time limit for answering in milliseconds.
  int get maxTaken => callbacks.getInt(jsonObject, 'maxTaken');

  bool get autoplay => callbacks.optBoolean(jsonObject, 'autoplay', true);

  set autoplay(bool value) => callbacks.put(jsonObject, 'autoplay', value);

  bool get replayq => callbacks.getBoolean(jsonObject, 'replayq');

  set replayq(bool value) => callbacks.put(jsonObject, 'replayq', value);

  /// Reads integer timer data first, then tries a boolean for older JSON.
  bool get timer {
    try {
      return callbacks.getInt(jsonObject, 'timer') != 0;
    } on Exception catch (failure) {
      callbacks.logWarning(failure);
      try {
        return callbacks.getBoolean(jsonObject, 'timer');
      } on Exception catch (fallbackFailure) {
        callbacks.logWarning(fallbackFailure);
        return true;
      }
    }
  }

  /// A fresh wrapper around the nested source `new` JSONObject on every read.
  LibAnkiDeckConfigNew get newConfig => LibAnkiDeckConfigNew(
    jsonObject: callbacks.getJsonObject(jsonObject, 'new'),
    callbacks: callbacks,
  );

  /// A fresh wrapper around the nested source `lapse` JSONObject on every read.
  LibAnkiDeckConfigLapse get lapseConfig => LibAnkiDeckConfigLapse(
    jsonObject: callbacks.getJsonObject(jsonObject, 'lapse'),
    callbacks: callbacks,
  );

  /// A fresh wrapper around the nested source `rev` JSONObject on every read.
  LibAnkiDeckConfigRev get revConfig => LibAnkiDeckConfigRev(
    jsonObject: callbacks.getJsonObject(jsonObject, 'rev'),
    callbacks: callbacks,
  );

  Object component1() => jsonObject;

  LibAnkiDeckConfig copy({Object jsonObject = _unspecifiedDeckConfigObject}) =>
      LibAnkiDeckConfig(
        jsonObject: identical(jsonObject, _unspecifiedDeckConfigObject)
            ? this.jsonObject
            : jsonObject,
        callbacks: callbacks,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibAnkiDeckConfig &&
          callbacks.jsonObjectEquals(jsonObject, other.jsonObject));

  @override
  int get hashCode => callbacks.jsonObjectHashCode(jsonObject);

  @override
  String toString() => callbacks.jsonObjectToString(jsonObject);

  static const QUESTION_ACTION = 'questionAction';
  static const ANSWER_ACTION = 'answerAction';
}

/// Nested settings from the source `DeckConfig.New` data class.
final class LibAnkiDeckConfigNew implements JSONObjectHolder {
  const LibAnkiDeckConfigNew({
    required this.jsonObject,
    required this.callbacks,
  });

  @override
  final Object jsonObject;
  final LibAnkiDeckConfigJsonCallbacks callbacks;

  int get perDay => callbacks.getInt(jsonObject, 'perDay');
  set perDay(int value) => callbacks.put(jsonObject, 'perDay', value);

  Object get delays => callbacks.getJsonArray(jsonObject, 'delays');
  set delays(Object value) => callbacks.put(jsonObject, 'delays', value);

  bool get bury => callbacks.getBoolean(jsonObject, 'bury');
  set bury(bool value) => callbacks.put(jsonObject, 'bury', value);

  Object component1() => jsonObject;

  LibAnkiDeckConfigNew copy({
    Object jsonObject = _unspecifiedDeckConfigObject,
  }) => LibAnkiDeckConfigNew(
    jsonObject: identical(jsonObject, _unspecifiedDeckConfigObject)
        ? this.jsonObject
        : jsonObject,
    callbacks: callbacks,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibAnkiDeckConfigNew &&
          callbacks.jsonObjectEquals(jsonObject, other.jsonObject));

  @override
  int get hashCode => callbacks.jsonObjectHashCode(jsonObject);

  @override
  String toString() =>
      'New(jsonObject=${callbacks.jsonObjectToString(jsonObject)})';
}

/// Nested settings from the source `DeckConfig.Lapse` data class.
final class LibAnkiDeckConfigLapse implements JSONObjectHolder {
  const LibAnkiDeckConfigLapse({
    required this.jsonObject,
    required this.callbacks,
  });

  @override
  final Object jsonObject;
  final LibAnkiDeckConfigJsonCallbacks callbacks;

  Object get delays => callbacks.getJsonArray(jsonObject, 'delays');
  set delays(Object value) => callbacks.put(jsonObject, 'delays', value);

  int get leechAction => callbacks.getInt(jsonObject, 'leechAction');
  set leechAction(int value) => callbacks.put(jsonObject, 'leechAction', value);

  double get mult => callbacks.getDouble(jsonObject, 'mult');
  set mult(double value) => callbacks.put(jsonObject, 'mult', value);

  Object component1() => jsonObject;

  LibAnkiDeckConfigLapse copy({
    Object jsonObject = _unspecifiedDeckConfigObject,
  }) => LibAnkiDeckConfigLapse(
    jsonObject: identical(jsonObject, _unspecifiedDeckConfigObject)
        ? this.jsonObject
        : jsonObject,
    callbacks: callbacks,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibAnkiDeckConfigLapse &&
          callbacks.jsonObjectEquals(jsonObject, other.jsonObject));

  @override
  int get hashCode => callbacks.jsonObjectHashCode(jsonObject);

  @override
  String toString() =>
      'Lapse(jsonObject=${callbacks.jsonObjectToString(jsonObject)})';
}

/// Nested settings from the source `DeckConfig.Rev` data class.
final class LibAnkiDeckConfigRev implements JSONObjectHolder {
  const LibAnkiDeckConfigRev({
    required this.jsonObject,
    required this.callbacks,
  });

  @override
  final Object jsonObject;
  final LibAnkiDeckConfigJsonCallbacks callbacks;

  int get perDay => callbacks.getInt(jsonObject, 'perDay');
  set perDay(int value) => callbacks.put(jsonObject, 'perDay', value);

  Object get delays => callbacks.getJsonArray(jsonObject, 'delays');
  set delays(Object value) => callbacks.put(jsonObject, 'delays', value);

  int get hardFactor => callbacks.getInt(jsonObject, 'hardFactor');
  set hardFactor(int value) => callbacks.put(jsonObject, 'hardFactor', value);

  Object component1() => jsonObject;

  LibAnkiDeckConfigRev copy({
    Object jsonObject = _unspecifiedDeckConfigObject,
  }) => LibAnkiDeckConfigRev(
    jsonObject: identical(jsonObject, _unspecifiedDeckConfigObject)
        ? this.jsonObject
        : jsonObject,
    callbacks: callbacks,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibAnkiDeckConfigRev &&
          callbacks.jsonObjectEquals(jsonObject, other.jsonObject));

  @override
  int get hashCode => callbacks.jsonObjectHashCode(jsonObject);

  @override
  String toString() =>
      'Rev(jsonObject=${callbacks.jsonObjectToString(jsonObject)})';
}

const _unspecifiedDeckConfigObject = _UnspecifiedDeckConfigObject();

final class _UnspecifiedDeckConfigObject {
  const _UnspecifiedDeckConfigObject();
}
