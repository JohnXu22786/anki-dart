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
 * Behavioral reference: CustomToolbarButton.kt, Consts.kt, and Toolbar.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:collection';

import 'math_jax_format.dart';

/// Unit separator used between custom toolbar button fields.
const fieldSeparator = '\u001f';

/// Portable custom toolbar button values and their preference serialization.
///
/// The Android toolbar and preference storage remain host responsibilities.
class CustomToolbarButton {
  CustomToolbarButton(int index, this.buttonText, this.prefix, this.suffix)
    : _index = _validateIndex(index);

  int _index;

  int get index => _index;

  set index(int value) => _index = _validateIndex(value);
  String buttonText;
  final String prefix;
  final String suffix;

  /// Returns the host-neutral text formatter matching AnkiDroid's wrapper.
  TextWrapper toFormatter() => TextWrapper(prefix, suffix);

  static const keepEmptyEntries = -1;

  /// Parses a four-field record, warning through [warn] when its index is bad.
  static CustomToolbarButton? fromString(
    String? value, {
    void Function(Object error)? warn,
  }) {
    if (value == null || value.isEmpty) return null;

    final limit = keepEmptyEntries < 0 ? 0 : keepEmptyEntries;
    final fields = _splitKeepingTrailingEmpty(value, fieldSeparator, limit);
    if (fields.length != 4) return null;

    try {
      final index = int.parse(fields[0]);
      if (index < -0x80000000 || index > 0x7fffffff) {
        throw FormatException(
          'Index is outside the signed Int32 range',
          fields[0],
        );
      }
      return CustomToolbarButton(index, fields[1], fields[2], fields[3]);
    } on FormatException catch (error) {
      warn?.call(error);
      return null;
    }
  }

  /// Parses entries in their supplied iteration order, then stably sorts them.
  static List<CustomToolbarButton> fromStringSet(
    Iterable<String?> values, {
    void Function(Object error)? warn,
  }) {
    final buttons = <({int order, CustomToolbarButton button})>[];
    var order = 0;
    for (final value in values) {
      final button = fromString(value, warn: warn);
      if (button != null) buttons.add((order: order, button: button));
      order++;
    }

    buttons.sort((left, right) {
      final byIndex = left.button.index.compareTo(right.button.index);
      return byIndex != 0 ? byIndex : left.order.compareTo(right.order);
    });

    return [
      for (var i = 0; i < buttons.length; i++) _reindex(buttons[i].button, i),
    ];
  }

  /// Serializes button fields, removing U+001F from every field first.
  static Set<String> toStringSet(Iterable<CustomToolbarButton> buttons) =>
      HashSet<String>.of(
        buttons.map(
          (button) =>
              [
                    button.index.toString(),
                    button.buttonText,
                    button.prefix,
                    button.suffix,
                  ]
                  .map((field) => field.replaceAll(fieldSeparator, ''))
                  .join(fieldSeparator),
        ),
      );

  static int _validateIndex(int index) {
    if (index < -0x80000000 || index > 0x7fffffff) {
      throw RangeError.range(index, -0x80000000, 0x7fffffff, 'index');
    }
    return index;
  }

  static CustomToolbarButton _reindex(CustomToolbarButton button, int index) {
    button.index = index;
    return button;
  }
}

List<String> _splitKeepingTrailingEmpty(
  String value,
  String separator,
  int limit,
) {
  if (limit == 1) return [value];
  final fields = <String>[];
  var start = 0;
  while (true) {
    final separatorIndex = value.indexOf(separator, start);
    if (separatorIndex == -1) {
      fields.add(value.substring(start));
      return fields;
    }
    fields.add(value.substring(start, separatorIndex));
    start = separatorIndex + separator.length;
    if (limit > 0 && fields.length == limit - 1) {
      fields.add(value.substring(start));
      return fields;
    }
  }
}
