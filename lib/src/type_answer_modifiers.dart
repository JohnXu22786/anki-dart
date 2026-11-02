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
 * Behavioral reference: TypeAnswerModifiers.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The parsed field and modifier values in a `[[type:...]]` declaration.
///
/// The host remains responsible for looking up fields and applying typing or
/// cloze behavior.
final class TypeAnswerModifiers {
  const TypeAnswerModifiers({
    required this.fieldName,
    required this.combining,
    required this.cloze,
    required this.noSuggest,
  });

  final String fieldName;
  final bool combining;
  final bool cloze;
  final bool noSuggest;

  /// Parses repeated recognized prefixes from the start of [rawField].
  ///
  /// Prefix matching is case-sensitive. Parsing stops at the first unknown
  /// text and preserves that remainder verbatim without trimming it.
  static TypeAnswerModifiers parse(String rawField) {
    var remaining = rawField;
    var combining = true;
    var cloze = false;
    var noSuggest = false;

    while (true) {
      if (remaining.startsWith('nosuggest:')) {
        noSuggest = true;
        remaining = remaining.substring('nosuggest:'.length);
      } else if (remaining.startsWith('cloze:')) {
        cloze = true;
        remaining = remaining.substring('cloze:'.length);
      } else if (remaining.startsWith('nc:')) {
        combining = false;
        remaining = remaining.substring('nc:'.length);
      } else {
        return TypeAnswerModifiers(
          fieldName: remaining,
          combining: combining,
          cloze: cloze,
          noSuggest: noSuggest,
        );
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TypeAnswerModifiers &&
      other.fieldName == fieldName &&
      other.combining == combining &&
      other.cloze == cloze &&
      other.noSuggest == noSuggest;

  @override
  int get hashCode => Object.hash(fieldName, combining, cloze, noSuggest);
}
