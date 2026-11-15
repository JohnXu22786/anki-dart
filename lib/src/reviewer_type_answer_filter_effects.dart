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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Projects the branch and host-effect order of `typeAnsFilter`.
///
/// The host supplies its already-resolved TypeAnswer and text values and owns
/// the filter implementations. Emission completes before any filter callback;
/// failures propagate and prevent later callbacks. Card lookup, TypeAnswer
/// construction/state, comparison, rendering and lifecycle remain host-side.
Future<String> executeReviewerTypeAnswerFilter<TTypeAnswer extends Object>({
  required bool showingAnswer,
  required TTypeAnswer? typeAnswer,
  required String text,
  required String typedAnswer,
  required bool useHtmlTypeAnswer,
  required Future<void> Function(TTypeAnswer? typeAnswer) emitTypeAnswer,
  required String Function(
    String text,
    TTypeAnswer typeAnswer,
    String typedAnswer,
  )
  filterAnswer,
  required String Function(String text, TTypeAnswer typeAnswer) filterQuestion,
  required String Function(String text) removeTags,
}) async {
  if (showingAnswer) {
    await emitTypeAnswer(null);
    if (typeAnswer == null) {
      return text;
    }
    return filterAnswer(text, typeAnswer, typedAnswer);
  }

  await emitTypeAnswer(typeAnswer);
  if (!useHtmlTypeAnswer) {
    return removeTags(text);
  }
  if (typeAnswer == null) {
    return text;
  }
  return filterQuestion(text, typeAnswer);
}
