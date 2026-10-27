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
 * Behavioral reference: `TypeAnswer.contentForCloze()` in AnkiDroid 2.25.3.
 */

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
