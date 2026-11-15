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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: BrowserColumnCollection.kt and CardBrowserColumn.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:collection';

/// The Cards or Notes table mode used when interpreting a browser column.
enum BrowserColumnMode { cards, notes }

/// The source-declared data type for a browser column.
enum BrowserColumnType { text, numeric, date, unspecified }

/// A column key recognized by AnkiDroid's Card Browser.
///
/// The data type may depend on [BrowserColumnMode]. Labels, samples, sort types,
/// and backend row values stay with the host.
enum BrowserColumn {
  question('question', BrowserColumnType.text),
  answer('answer', BrowserColumnType.text),
  sortField('noteFld', BrowserColumnType.text),
  deck('deck', BrowserColumnType.text),
  tags('noteTags', BrowserColumnType.text),
  cardType('template', BrowserColumnType.text, BrowserColumnType.numeric),
  due('cardDue', BrowserColumnType.unspecified),
  ease('cardEase', BrowserColumnType.numeric),
  changed('cardMod', BrowserColumnType.date),
  created('noteCrt', BrowserColumnType.date),
  edited('noteMod', BrowserColumnType.date),
  interval('cardIvl', BrowserColumnType.numeric),
  lapses('cardLapses', BrowserColumnType.numeric),
  noteType('note', BrowserColumnType.text),
  reviews('cardReps', BrowserColumnType.numeric),
  fsrsDifficulty('difficulty', BrowserColumnType.numeric),
  fsrsRetrievability('retrievability', BrowserColumnType.numeric),
  fsrsStability('stability', BrowserColumnType.numeric),
  originalPosition('originalPosition', BrowserColumnType.numeric);

  const BrowserColumn(this.key, this.cardsType, [BrowserColumnType? notesType])
      : notesType = notesType ?? cardsType;

  final String key;
  final BrowserColumnType cardsType;
  final BrowserColumnType notesType;

  /// Returns the data type displayed for [mode], matching AnkiDroid's mapping.
  BrowserColumnType typeFor(BrowserColumnMode mode) =>
      mode == BrowserColumnMode.cards ? cardsType : notesType;

  /// Resolves a source column key, throwing for any unknown key.
  static BrowserColumn fromColumnKey(String key) {
    for (final column in values) {
      if (column.key == key) return column;
    }
    throw ArgumentError.value(key, 'key', 'Invalid key: $key');
  }
}

/// The ordered columns selected for one Card Browser view.
///
/// The caller supplies the serialized preference and its mode-specific default
/// keys. Reading/writing SharedPreferences and resolving the current mode remain
/// host responsibilities.
final class BrowserColumnCollection {
  BrowserColumnCollection(List<BrowserColumn> columns)
      : columns = UnmodifiableListView(columns),
        count = columns.length;

  final List<BrowserColumn> columns;
  final int count;

  /// A snapshot of the selected keys, matching Kotlin's eager `List.map`.
  Iterable<String> get backendKeys =>
      columns.map((column) => column.key).toList();

  BrowserColumn operator [](int index) => columns[index];

  String get preferenceValue => columns.map((column) => column.key).join('|');

  /// Loads `|`-separated keys, falling back to [defaultColumnKeys] on bad data.
  ///
  /// Successfully loaded values remove later duplicates while preserving the
  /// first occurrence, matching the source collection's load behavior.
  static BrowserColumnCollection load({
    required String? preferenceValue,
    required List<String> defaultColumnKeys,
  }) {
    final defaults = List<String>.of(defaultColumnKeys);
    final value = preferenceValue ?? defaults.join('|');
    try {
      return _parse(value);
    } on ArgumentError {
      return _parse(defaults.join('|'));
    }
  }

  /// Applies an update and returns its value for the host to persist.
  ///
  /// A `false` callback result leaves storage untouched and returns `null`.
  /// A successful update drops null columns but otherwise preserves its order
  /// and duplicates, matching the source's update behavior.
  static BrowserColumnUpdate? update({
    required String? preferenceValue,
    required List<String> defaultColumnKeys,
    required bool Function(List<BrowserColumn?> columns) mutate,
  }) {
    final values = load(
      preferenceValue: preferenceValue,
      defaultColumnKeys: defaultColumnKeys,
    ).columns.map<BrowserColumn?>((column) => column).toList();
    if (!mutate(values)) return null;

    final collection =
        BrowserColumnCollection(values.whereType<BrowserColumn>().toList());
    return BrowserColumnUpdate(
      collection: collection,
      preferenceValue: collection.preferenceValue,
    );
  }

  /// Replaces the selection and returns both lists plus the serialized value.
  static BrowserColumnReplacement replace({
    required String? preferenceValue,
    required List<String> defaultColumnKeys,
    required List<BrowserColumn> newColumns,
  }) {
    final originalColumns = <BrowserColumn>[];
    final updateResult = update(
      preferenceValue: preferenceValue,
      defaultColumnKeys: defaultColumnKeys,
      mutate: (columns) {
        originalColumns.addAll(columns.whereType<BrowserColumn>());
        columns
          ..clear()
          ..addAll(newColumns);
        return true;
      },
    )!;
    return BrowserColumnReplacement(
      newColumns: updateResult.collection,
      originalColumns: originalColumns,
      preferenceValue: updateResult.preferenceValue,
    );
  }

  static BrowserColumnCollection _parse(String value) {
    final columns =
        value.split('|').map(BrowserColumn.fromColumnKey).toSet().toList();
    return BrowserColumnCollection(columns);
  }
}

/// A successful pure update; the host decides how to persist [preferenceValue].
final class BrowserColumnUpdate {
  const BrowserColumnUpdate({
    required this.collection,
    required this.preferenceValue,
  });

  final BrowserColumnCollection collection;
  final String preferenceValue;
}

/// The result of replacing active columns.
final class BrowserColumnReplacement {
  BrowserColumnReplacement({
    required this.newColumns,
    required List<BrowserColumn> originalColumns,
    required this.preferenceValue,
  }) : originalColumns = UnmodifiableListView(originalColumns);

  final BrowserColumnCollection newColumns;
  final List<BrowserColumn> originalColumns;
  final String preferenceValue;
}
