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
 * Behavioral reference: TypeAnswer.removeTags() in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

// Java's default regex dot excludes these line terminators. List them explicitly
// so Dart's regular-expression engine has the same behavior for NEL as well.
final RegExp _typeAnswerTag = RegExp(
  r'\[\[type:([^\r\n\u0085\u2028\u2029]+?)]]',
);

/// Removes nonempty, single-line `[[type:...]]` placeholders from [text].
///
/// This is the question-side cleanup only. Resolving a field or comparing the
/// typed answer remains the host's responsibility.
String removeTypeAnswerTags(String text) => text.replaceAll(_typeAnswerTag, '');
