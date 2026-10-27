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
 * Behavioral reference: `TypeAnswer.filterAnswer()` in AnkiDroid 2.25.3.
 */

// Match Java's default Pattern dot behavior, including excluding NEL.
final RegExp _answerTypeAnswerPattern = RegExp(
  r'\[\[type:([^\r\n\u0085\u2028\u2029]+?)]]',
);

/// Replaces each nonempty, single-line `[[type:...]]` marker with [comparisonHtml].
///
/// [comparisonHtml] is the host's already-computed answer comparison. It is
/// inserted literally, including `$` and backslashes, as in Java's
/// `Matcher.quoteReplacement`; this function does not compute or sanitize it.
String filterTypeAnswerAnswer(String answer, String comparisonHtml) =>
    answer.replaceAllMapped(_answerTypeAnswerPattern, (_) => comparisonHtml);
