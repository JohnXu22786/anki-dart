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
 * Behavioral reference: `TypeAnswer.validForEditText()` and
 * `TypeAnswer.autoFocusEditText()` in AnkiDroid 2.25.3.
 */

/// Whether the source would expose a valid EditText answer field.
///
/// This deliberately tests whether [correctAnswer] is non-null, not whether it
/// is nonempty. The host supplies the current TypeAnswer values.
bool typeAnswerValidForEditText({
  required bool useInputTag,
  required String? correctAnswer,
}) =>
    !useInputTag && correctAnswer != null;

/// Whether the source would request automatic focus for a valid answer field.
///
/// Android focus and widget lifecycle remain host-side; this is only the pure
/// `validForEditText() && autoFocus` decision.
bool typeAnswerAutoFocusEditText({
  required bool useInputTag,
  required String? correctAnswer,
  required bool autoFocus,
}) =>
    typeAnswerValidForEditText(
      useInputTag: useInputTag,
      correctAnswer: correctAnswer,
    ) &&
    autoFocus;
