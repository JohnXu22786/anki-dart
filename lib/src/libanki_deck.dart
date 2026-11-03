/*
 * Copyright (c) 2020 Arthur Milchior <arthur@milchior.fr>
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
 * SPDX-FileCopyrightText: 2020 Arthur Milchior <arthur@milchior.fr>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Deck.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host-owned operations needed to adapt AnkiDroid's `Deck` JSON model.
///
/// The host retains JSONObject construction, deep cloning, parsing, typed
/// access, and `put` behavior. Callback failures pass through unchanged, except
/// [LibAnkiDeck.confOrNull], which follows the source helper's `Exception`
/// catch boundary.
final class LibAnkiDeckJsonCallbacks {
  const LibAnkiDeckJsonCallbacks({
    required this.getInt,
    required this.getString,
    required this.getBoolean,
    required this.getLong,
    required this.optLong,
    required this.optBoolean,
    required this.optString,
    required this.put,
    required this.deepCloneJsonObject,
    required this.parseJsonObjectString,
  });

  final int Function(Object jsonObject, String key) getInt;
  final String Function(Object jsonObject, String key) getString;
  final bool Function(Object jsonObject, String key) getBoolean;
  final int Function(Object jsonObject, String key) getLong;
  final int Function(Object jsonObject, String key) optLong;
  final bool Function(Object jsonObject, String key, bool defaultValue)
  optBoolean;
  final String Function(Object jsonObject, String key, String defaultValue)
  optString;
  final void Function(Object jsonObject, String key, Object? value) put;
  final Object Function(Object jsonObject) deepCloneJsonObject;
  final Object Function(String jsonString) parseJsonObjectString;
}

/// Portable wrapper for a libanki deck's host JSONObject.
///
/// The host owns JSON parsing, representation, and conversion semantics.
final class LibAnkiDeck {
  const LibAnkiDeck({required this.jsonObject, required this.callbacks});

  /// Constructs a deck from one host deep clone of [jsonObject].
  factory LibAnkiDeck.fromJsonObject({
    required Object jsonObject,
    required LibAnkiDeckJsonCallbacks callbacks,
  }) => LibAnkiDeck(
    jsonObject: callbacks.deepCloneJsonObject(jsonObject),
    callbacks: callbacks,
  );

  /// Constructs a deck by asking the host to parse [jsonString] once.
  factory LibAnkiDeck.fromJsonString({
    required String jsonString,
    required LibAnkiDeckJsonCallbacks callbacks,
  }) => LibAnkiDeck(
    jsonObject: callbacks.parseJsonObjectString(jsonString),
    callbacks: callbacks,
  );

  /// The exact host JSONObject retained by this deck.
  final Object jsonObject;

  /// Host JSONObject behavior used by source properties and constructors.
  final LibAnkiDeckJsonCallbacks callbacks;

  /// Whether the source `dyn` value identifies a filtered deck.
  bool get isFiltered => callbacks.getInt(jsonObject, 'dyn') != 0;

  /// Whether the source `dyn` value identifies a normal deck.
  bool get isNormal => !isFiltered;

  /// Deck name stored at key `name`.
  String get name => callbacks.getString(jsonObject, 'name');

  set name(String value) => callbacks.put(jsonObject, 'name', value);

  /// Whether the deck is collapsed in the deck list, stored at `collapsed`.
  bool get collapsed => callbacks.getBoolean(jsonObject, 'collapsed');

  set collapsed(bool value) => callbacks.put(jsonObject, 'collapsed', value);

  /// Whether the deck is collapsed in the browser, defaulting to false.
  bool get browserCollapsed =>
      callbacks.optBoolean(jsonObject, 'browserCollapsed', false);

  set browserCollapsed(bool value) =>
      callbacks.put(jsonObject, 'browserCollapsed', value);

  /// Unique deck identifier stored at key `id`.
  int get id => callbacks.getLong(jsonObject, 'id');

  set id(int value) => callbacks.put(jsonObject, 'id', value);

  /// Deck configuration identifier, defaulting to one when not positive.
  int get conf {
    final value = callbacks.optLong(jsonObject, 'conf');
    return value > 0 ? value : 1;
  }

  set conf(int value) => callbacks.put(jsonObject, 'conf', value);

  /// Description shown on the deck overview, defaulting to an empty string.
  String get description => callbacks.optString(jsonObject, 'desc', '');

  set description(String value) => callbacks.put(jsonObject, 'desc', value);

  /// Whether the description is treated as Markdown, defaulting to false.
  bool get descriptionAsMarkdown =>
      callbacks.optBoolean(jsonObject, 'md', false);

  set descriptionAsMarkdown(bool value) =>
      callbacks.put(jsonObject, 'md', value);

  /// Source-internal config lookup, returning null for missing or nonpositive values.
  int? confOrNull() {
    try {
      final value = callbacks.getLong(jsonObject, 'conf');
      return value > 0 ? value : null;
    } on Exception {
      return null;
    }
  }
}
