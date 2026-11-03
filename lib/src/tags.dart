/*
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2012 Kostas Spyropoulos <inigo.aldana@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2012 Kostas Spyropoulos
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: Tags.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'dart:collection';

/// Portable string and list helpers from AnkiDroid's `Tags` class.
///
/// Collection, database, and backend operations remain host-side.
abstract final class Tags {
  static final RegExp _sourceWhitespace = RegExp(r'[\x09-\x0D\x20]');

  /// Splits [tags] on Kotlin/JVM's default ASCII `\\s` characters.
  ///
  /// U+3000 is first converted to an ASCII space, as in the source. Other
  /// Unicode whitespace separators are preserved.
  static List<String> split(String tags) => tags
      .replaceAll('\u3000', ' ')
      .split(_sourceWhitespace)
      .where((tag) => tag.isNotEmpty)
      .toList();

  /// Joins [tags] in iteration order with surrounding spaces.
  static String join(Iterable<String> tags) {
    final values = tags.toList();
    if (values.isEmpty) {
      return '';
    }
    return ' ${values.join(' ')} ';
  }

  /// Returns a new hash set containing the exact distinct strings in [tagList].
  static Set<String> canonify(Iterable<String> tagList) =>
      HashSet<String>.from(tagList);

  /// Returns whether [tag] occurs in [tags], ignoring case.
  ///
  /// Materializing the lowercased iterable preserves Kotlin's eager mapping,
  /// including traversal and errors after an earlier matching element.
  static bool inList(String tag, Iterable<String> tags) {
    final lowercasedTags = tags.map(_sourceLowercase).toList();
    return lowercasedTags.contains(_sourceLowercase(tag));
  }

  // Kotlin/JVM lowercase expands U+0130 to `i` plus combining dot, while
  // Dart's direct mapping drops the dot. Preserve the source expansion.
  static String _sourceLowercase(String value) =>
      value.replaceAll('\u0130', 'i\u0307').toLowerCase();
}
