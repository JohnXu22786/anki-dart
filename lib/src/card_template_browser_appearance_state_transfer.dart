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
 * Behavioral reference: CardTemplateBrowserAppearanceEditor.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Saves the two format fields before delegating instance-state saving.
///
/// The host reads EditText values, writes Bundle strings, and invokes the
/// Activity superclass. Nullable values preserve `Bundle.getString` semantics;
/// callback failures propagate and stop subsequent source-ordered work.
void saveBrowserAppearanceInstanceState({
  required String? Function() readQuestionFormat,
  required void Function(String?) writeQuestionFormat,
  required String? Function() readAnswerFormat,
  required void Function(String?) writeAnswerFormat,
  required void Function() saveSuperclassState,
}) {
  writeQuestionFormat(readQuestionFormat());
  writeAnswerFormat(readAnswerFormat());
  saveSuperclassState();
}

/// Restores format fields and then applies Browser Appearance host UI effects.
///
/// The host owns Bundle access, EditText, `hasChanges`, toolbar, and localized
/// title behavior. Nullable extras are passed unchanged, and callback failures
/// propagate immediately, matching the source sequence.
void initializeBrowserAppearanceUiFromBundle({
  required String? Function() readQuestionFormatExtra,
  required void Function(String?) setQuestionFormat,
  required String? Function() readAnswerFormatExtra,
  required void Function(String?) setAnswerFormat,
  required bool Function() hasChanges,
  required void Function(bool) setDiscardCallbackEnabled,
  required void Function() enableToolbar,
  required void Function() setBrowserAppearanceTitle,
}) {
  setQuestionFormat(readQuestionFormatExtra());
  setAnswerFormat(readAnswerFormatExtra());
  setDiscardCallbackEnabled(hasChanges());
  enableToolbar();
  setBrowserAppearanceTitle();
}
