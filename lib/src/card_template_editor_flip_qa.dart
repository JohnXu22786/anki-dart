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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

const _answerSeparator = '{{FrontSide}}\n\n<hr id=answer>\n\n';
final _answerSeparatorPattern = RegExp(r'(.+)<hr id=answer>(.+)', dotAll: true);

/// Applies AnkiDroid's `flipQA` string transformation through host setters.
///
/// The host reads the original strings and supplies setters for the existing
/// template fields; storage, model mutation, and UI remain host-side. Setters
/// run in source order, so a question-setter failure prevents answer assignment.
void flipCardTemplateQA({
  required String question,
  required String answer,
  required void Function(String value) setQuestion,
  required void Function(String value) setAnswer,
}) {
  final match = _answerSeparatorPattern.firstMatch(answer);
  final flippedQuestion = match == null
      ? answer.replaceAll('{{FrontSide}}', '')
      : _trimAtOrBelowSpace(match.group(2)!);

  setQuestion(flippedQuestion);
  setAnswer('$_answerSeparator$question');
}

String _trimAtOrBelowSpace(String value) {
  var start = 0;
  var end = value.length;
  while (start < end && value.codeUnitAt(start) <= 0x20) {
    start++;
  }
  while (end > start && value.codeUnitAt(end - 1) <= 0x20) {
    end--;
  }
  return value.substring(start, end);
}
