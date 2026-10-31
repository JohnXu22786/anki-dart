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
 * Source-derived from CardTemplateBrowserAppearanceEditor.Result in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// The default format value used by the source when an Intent extra is null.
const browserAppearanceUseDefault = '';

/// The question and answer formats extracted from the host's Intent.
final class BrowserAppearanceResult {
  const BrowserAppearanceResult({
    required String? question,
    required String? answer,
  }) : question = question ?? browserAppearanceUseDefault,
       answer = answer ?? browserAppearanceUseDefault;

  final String question;
  final String answer;

  /// Applies the formats to host-owned template fields in source order.
  ///
  /// A setter failure propagates immediately, so the answer setter is skipped
  /// if setting the question format fails.
  void applyTo({
    required void Function(String) setBqfmt,
    required void Function(String) setBafmt,
  }) {
    setBqfmt(question);
    setBafmt(answer);
  }
}

/// Extracts the two formats while leaving Intent access with the host.
///
/// When [hasIntent] is false, neither callback is invoked. For a present
/// Intent, question is read before answer; an [Exception] from either read
/// returns null and skips any later read. Dart [Error] values propagate.
BrowserAppearanceResult? browserAppearanceResultFromIntent({
  required bool hasIntent,
  required String? Function() readQuestionFormat,
  required String? Function() readAnswerFormat,
}) {
  if (!hasIntent) return null;

  try {
    final question = readQuestionFormat();
    final answer = readAnswerFormat();
    return BrowserAppearanceResult(question: question, answer: answer);
  } on Exception {
    return null;
  }
}
