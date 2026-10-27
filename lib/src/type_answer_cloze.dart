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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral references: `TypeAnswer.updateInfo()` and
 * `TypeAnswer.contentForCloze()` in AnkiDroid 2.25.3.
 */

import 'type_answer_modifiers.dart';

/// Derives the source cloze index from a host-supplied rendered [question].
///
/// Returns `null` when `TypeAnswer.PATTERN` does not match; the source exits
/// `updateInfo` before deriving an index in that case. A matched declaration
/// without `cloze:` has index 0. With `cloze:`, the zero-based [cardOrdinal] is
/// incremented using Kotlin signed 32-bit `Int` arithmetic. In particular, an
/// ordinal of -1 produces 0, which the source treats as a non-cloze index.
///
/// This does not obtain the question or ordinal from an Android card, inspect
/// note fields, or extract the answer content.
int? typeAnswerClozeIndexForQuestion(String question, int cardOrdinal) {
  final marker = RegExp(
    r'\[\[type:([^\r\n\u0085\u2028\u2029]+?)]]',
  ).firstMatch(question);
  if (marker == null) return null;

  final modifiers = TypeAnswerModifiers.parse(marker.group(1)!);
  if (!modifiers.cloze) return 0;
  return (cardOrdinal + 1).toSigned(32);
}

/// Extracts the source's ordered answer text for [index] from cloze markers.
///
/// A hint beginning at the first `::` in a capture is discarded. If every
/// matching answer is identical, the first is returned once; otherwise all
/// captured answers (including duplicates) are joined in source order. The
/// host supplies the field text and cloze index; this does not perform card or
/// note lookup.
String? typeAnswerContentForCloze(String text, int index) {
  final pattern = RegExp(
    r'\{\{c' + index.toString() + r'::([^\r\n\u0085\u2028\u2029]+?)\}\}',
  );
  final matches = <String>[];
  for (final match in pattern.allMatches(text)) {
    final captured = match.group(1)!;
    final hintStart = captured.indexOf('::');
    matches.add(hintStart < 0 ? captured : captured.substring(0, hintStart));
  }

  if (matches.toSet().length == 1) return matches.first;
  return matches.join(', ');
}
